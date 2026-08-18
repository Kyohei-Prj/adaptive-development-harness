#!/usr/bin/env bash
#
# Hands-off, fresh-session-per-stage autorun.
#
# The in-chat /autorun command runs every phase inside ONE continuous `lead`
# session — hands-off within a phase, but the orchestrating session itself
# never resets, so on a long plan it can drift toward (or past) the smart
# zone. This script gets both properties at once by moving the phase
# boundary from the conversation to the process: each phase's implement and
# review step is its own `opencode run` invocation — a brand-new process
# with a brand-new context, no different from manually closing a session and
# opening another, except nothing here has to remember to do that.
#
# Usage:
#   scripts/autorun.sh <slug>
#
# Requires:
#   - the `opencode` CLI on PATH, with headless auth already configured
#     (`opencode auth login`, or the relevant provider env vars set)
#   - docs/<slug>/implementation-plan.md already committed (i.e. Planning
#     is done)
#
# KNOWN CAVEAT: some opencode versions/platforms have had `opencode run`
# require a pre-existing session instead of creating one automatically
# (see https://github.com/anomalyco/opencode/issues/28407). Smoke-test with
# `opencode run --agent lead "echo hi"` before relying on this script for a
# real multi-phase run. If your version needs an explicit session, create
# one per phase here instead (check `opencode session --help`).

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <slug>" >&2
  exit 2
fi

SLUG="$1"
PLAN="docs/$SLUG/implementation-plan.md"
LOG="docs/$SLUG/autorun.log"

if [[ ! -f "$PLAN" ]]; then
  echo "Error: $PLAN not found. Run /plan (and /grill first, for anything non-trivial) before autorun." >&2
  exit 1
fi

mkdir -p "docs/$SLUG"
{
  echo "===================================================="
  echo "autorun.sh started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "slug: $SLUG"
  echo "===================================================="
} >> "$LOG"

# Extract phase numbers from headers like "## Phase 1 —" or "## Phase 1 -"
mapfile -t PHASES < <(grep -oE '^## Phase [0-9]+' "$PLAN" | grep -oE '[0-9]+' | sort -n)

if [[ ${#PHASES[@]} -eq 0 ]]; then
  echo "Error: no '## Phase N' headers found in $PLAN — is the plan file well-formed?" >&2
  exit 1
fi

echo "Found ${#PHASES[@]} phase(s): ${PHASES[*]}"

run_step() {
  local label="$1"
  local command_text="$2"

  echo "" | tee -a "$LOG"
  echo "=== $label ===" | tee -a "$LOG"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG"

  local out
  # --format json streams structured events; we still rely on the literal
  # AUTORUN_STATUS trailer in the final assistant text rather than parsing
  # event types, so this works whether or not --format json is supported by
  # your opencode version. Drop --format json below if it errors for you.
  if ! out=$(opencode run --agent lead --format json "$command_text" 2>&1); then
    echo "$out" | tee -a "$LOG"
    echo "Error: 'opencode run' itself failed (non-zero exit) for: $command_text" | tee -a "$LOG"
    echo "This is a tooling/auth/connectivity failure, not an AUTORUN_STATUS: FAIL from the agent — check the output above." | tee -a "$LOG"
    exit 1
  fi

  echo "$out" >> "$LOG"

  local status_line
  status_line=$(grep -o 'AUTORUN_STATUS:.*' <<<"$out" | tail -n1)

  if [[ -z "$status_line" ]]; then
    echo "Warning: no AUTORUN_STATUS trailer found in output for: $command_text" | tee -a "$LOG"
    echo "Treating as NEEDS_HUMAN — see $LOG for the full transcript of this step." | tee -a "$LOG"
    echo "Stopped. Review $LOG, resolve manually, then re-run this script — already-completed phases are safe to skip past by editing the loop or re-running individual /implement-phase-auto or /review-phase-auto commands by hand." | tee -a "$LOG"
    exit 1
  fi

  echo "$status_line" | tee -a "$LOG"

  if [[ "$status_line" == AUTORUN_STATUS:\ OK* ]]; then
    return 0
  fi

  echo "Stopped at: $label" | tee -a "$LOG"
  echo "Reason: $status_line" | tee -a "$LOG"
  echo "Review $LOG for the full transcript. Resolve manually, then re-run — you'll want to skip already-completed phases (edit this script's phase list, or re-invoke the remaining /implement-phase-auto and /review-phase-auto commands by hand)." | tee -a "$LOG"
  exit 1
}

for N in "${PHASES[@]}"; do
  run_step "Phase $N: implement" "/implement-phase-auto $N $SLUG"
  run_step "Phase $N: review"    "/review-phase-auto $N $SLUG"
done

run_step "Finalize" "/finalize $SLUG"

echo "" | tee -a "$LOG"
echo "All phases complete and finalized." | tee -a "$LOG"
echo "Review $LOG, then merge feature/$SLUG-phase-* to main manually, and run /archive $SLUG afterward." | tee -a "$LOG"
