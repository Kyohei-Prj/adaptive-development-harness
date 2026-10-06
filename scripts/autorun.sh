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
#   scripts/autorun.sh <slug> [start_phase]
#
#   start_phase (optional, default: the plan's first phase number) — resume
#   from this phase's implement step onward, skipping every phase before
#   it. Use this after a stop-and-fix: autorun exits non-zero and logs
#   "Stopped at: Phase N: <step>" whenever a phase needs human help (a
#   NEEDS_HUMAN/FAIL trailer, a missing trailer, or an `opencode run`
#   failure). Resolve the issue by hand — finish that phase's implement
#   and review yourself if needed, commit as normal — then re-invoke this
#   script with start_phase set to the NEXT phase number so it doesn't
#   redo work that's already committed. Passing a start_phase past the
#   last phase in the plan skips the phase loop entirely and runs only
#   /finalize.
#
#   start_phase also accepts an "N:review" suffix (e.g. "3:review") to
#   resume Phase 3 at its REVIEW step, skipping that phase's implement step
#   (use this when implement finished and committed but review is what
#   stopped). Only the first resumed phase is affected — later phases
#   always run both steps.
#
#   SUPERVISED MODE: for an unattended run that heals itself, prefer
#   `/autorun-supervised <slug> [start_phase]` (or drive this script through
#   scripts/autorun-watch.sh) — it launches this script in the background,
#   detects stalls via session activity, diagnoses failures by exporting the
#   step's session, and resumes automatically up to its retry caps. Each
#   `opencode run` below carries a --title tag for exactly that reason: it
#   is how the watcher locates the currently-running step's session.
#
#   NOTE ON GIT STATE: phases stack — each phase N branches off phase N-1's
#   branch (feature/<slug>-phase-(N-1)), not off main. This script doesn't
#   create or switch branches itself; it relies on whatever's currently
#   checked out on disk. So before resuming, make sure you're sitting on
#   the branch the resumed phase should build on top of (normally
#   feature/<slug>-phase-(start_phase-1), assuming you completed that
#   phase's review manually and it's committed).
#
# Requires:
#   - the `opencode` CLI on PATH, with headless auth already configured
#     (`opencode auth login`, or the relevant provider env vars set)
#   - `jq` on PATH — required to correctly parse `opencode run --format
#     json`'s event stream. See the note above run_step() for why this
#     isn't optional: naive text-grepping the raw JSONL previously produced
#     false-positive AND false-negative status reads.
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

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <slug> [start_phase]" >&2
  exit 2
fi

START_PHASE=""
START_STEP=""
if [[ $# -eq 2 ]]; then
  if [[ "$2" =~ ^([0-9]+)(:(review))?$ ]]; then
    START_PHASE="${BASH_REMATCH[1]}"
    START_STEP="${BASH_REMATCH[3]}"
  else
    echo "Error: start_phase must be a positive integer, optionally with a ':review' suffix (e.g. 3 or 3:review), got: $2" >&2
    exit 2
  fi
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not found on PATH. Install it (e.g. 'apt install jq', 'brew install jq') before running this script." >&2
  echo "jq is what lets this script correctly parse 'opencode run --format json' event-by-event, instead of text-grepping the raw JSONL — the latter previously matched tool-output payloads (like a skill file's own documentation text) instead of the agent's actual final report." >&2
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
  if [[ -n "$START_PHASE" ]]; then
    echo "resuming from phase: $START_PHASE${START_STEP:+:$START_STEP} (earlier phases assumed already complete)"
  fi
  echo "===================================================="
} >> "$LOG"

# Extract phase numbers from headers like "## Phase 1 —" or "## Phase 1 -"
mapfile -t PHASES < <(grep -oE '^## Phase [0-9]+' "$PLAN" | grep -oE '[0-9]+' | sort -n)

if [[ ${#PHASES[@]} -eq 0 ]]; then
  echo "Error: no '## Phase N' headers found in $PLAN — is the plan file well-formed?" >&2
  exit 1
fi

echo "Found ${#PHASES[@]} phase(s) in plan: ${PHASES[*]}"

if [[ -n "$START_PHASE" ]]; then
  # Validate start_phase is an actual phase number from the plan, not just
  # any integer — a typo here (e.g. resuming at 3 when the plan only has
  # phases 1, 2, 4, 5) should fail loudly rather than silently produce an
  # empty or wrong-looking run.
  found=0
  for p in "${PHASES[@]}"; do
    [[ "$p" == "$START_PHASE" ]] && found=1 && break
  done
  if [[ $found -eq 0 && "$START_PHASE" -le "${PHASES[-1]}" ]]; then
    echo "Error: start_phase $START_PHASE is not one of the plan's phase numbers (${PHASES[*]})." >&2
    exit 2
  fi

  filtered=()
  for p in "${PHASES[@]}"; do
    [[ "$p" -ge "$START_PHASE" ]] && filtered+=("$p")
  done
  PHASES=("${filtered[@]}")

  if [[ ${#PHASES[@]} -eq 0 ]]; then
    if [[ -n "$START_STEP" ]]; then
      echo "Error: start_phase $START_PHASE:review asks to resume at a review step, but no phases remain to run (it is past the plan's highest phase)." >&2
      exit 2
    fi
    echo "start_phase $START_PHASE is past the last phase ($PLAN's highest phase) — skipping the phase loop and running only /finalize." | tee -a "$LOG"
  elif [[ -n "$START_STEP" ]]; then
    echo "Resuming from phase $START_PHASE at its $START_STEP step onward: ${PHASES[*]}" | tee -a "$LOG"
  else
    echo "Resuming from phase $START_PHASE onward: ${PHASES[*]}" | tee -a "$LOG"
  fi
fi

# `opencode run --format json` emits one JSON object per line (JSONL), with
# a `type` field: "text" (actual model output), "tool_use" (a tool call's
# full input/output — e.g. a skill file's ENTIRE contents when the agent
# reads it), "step_start"/"step_finish", and "error". Naively grepping the
# raw JSONL for "AUTORUN_STATUS:" is unsafe: (1) a tool_use event's output
# can itself contain that literal substring — e.g. the phase-lifecycle
# skill documents the trailer format with a literal example block, and
# grep can't tell "the skill describing the format" from "the agent's real
# report"; (2) embedded newlines inside a JSON string are encoded as the
# two literal characters \n, not real line breaks, so a naive grep can
# match far past where a human would expect a "line" to end. Extracting
# only `type=="text"` events' `.part.text` — and only the LAST one, i.e.
# the model's actual final response — avoids both problems.
extract_final_text() {
  # Concatenate ALL type=="text" events, not just the last one. A model can
  # legitimately emit several separate text segments in one turn (narration
  # between tool calls, then its report) — and despite instructions to make
  # the AUTORUN_STATUS line the literal last line of the response, a model
  # can still tack on a trailing remark as its own extra text event after
  # the real report ("let me know if you'd like me to continue..."). If we
  # only look at the single LAST text event, a trailing remark like that
  # hides a trailer that's genuinely present earlier in the same turn.
  # Concatenating everything and taking the last matching line downstream
  # is robust to both cases: the report being the true final segment, or
  # something trailing after it.
  jq -s -r '[.[] | select(.type=="text") | .part.text] | join("\n")' 2>/dev/null
}

run_step() {
  local label="$1"
  local command_name="$2"
  local command_args="$3"
  local run_id="$4"
  # For logging/error messages only — NOT what's sent to opencode.
  local command_text="/$command_name $command_args"

  echo "" | tee -a "$LOG"
  echo "=== $label ===" | tee -a "$LOG"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG"

  # IMPORTANT: `opencode run` does NOT resolve slash-command syntax in its
  # free-text prompt argument — that expansion only happens in the
  # interactive TUI. Passing "/implement-phase-auto 1 todo-app" as the
  # plain message here would forward that literal string to the model,
  # which has no idea what a slash command is and either hallucinates a
  # response or errors — silently breaking the whole hand-off chain this
  # script depends on. The `--command <name>` flag is what actually
  # resolves against .opencode/commands/<name>.md; the positional message
  # after it supplies the command's arguments ($1, $2, ...), same as
  # typing "/implement-phase-auto 1 todo-app" would in the TUI.
  # --title tags the child session (e.g. "autorun-my-app-p1-implement") so
  # scripts/autorun-watch.sh can find the one session that should currently
  # be making progress (stall detection) and /autorun-supervised can
  # `opencode export` exactly that session after a stop — instead of
  # guessing "most recent session" and reading some unrelated one.
  local out
  if ! out=$(opencode run --agent lead --format json --title "autorun-$SLUG-$run_id" --command "$command_name" "$command_args" 2>&1); then
    echo "$out" | tee -a "$LOG"
    echo "Error: 'opencode run' itself failed (non-zero exit) for: $command_text" | tee -a "$LOG"
    echo "This is a tooling/auth/connectivity failure, not an AUTORUN_STATUS: FAIL from the agent — check the output above." | tee -a "$LOG"
    exit 1
  fi

  echo "$out" >> "$LOG"

  # NOTE: `|| true` on both extractions below is load-bearing, not
  # decoration. jq (on malformed/empty input) and grep (on no match) both
  # exit non-zero when they legitimately find nothing — that's the normal,
  # expected way of saying "nothing here." Under `set -euo pipefail`, that
  # non-zero status propagates through the pipe and, because these are
  # plain `var=$(...)` assignments rather than part of an `if`/`&&`,
  # `set -e` kills the whole script on that line — BEFORE the `if [[ -z
  # ... ]]` fallback below ever runs. That fallback is exactly the
  # graceful-degradation path this script is supposed to take, so without
  # `|| true` here it can never fire: the script just dies silently
  # instead of printing the warning and the resume instructions.
  local final_text
  final_text=$(echo "$out" | extract_final_text || true)

  if [[ -z "$final_text" ]]; then
    echo "Warning: could not extract a final text response via jq (malformed JSON, no 'text' event found, or --format json not supported by your opencode version)." | tee -a "$LOG"
    echo "Falling back to a raw scan of the full output — this is the old, less reliable path and can false-positive on tool output containing the literal string 'AUTORUN_STATUS:' (e.g. the phase-lifecycle skill's own documentation). Treat any result from this fallback with suspicion." | tee -a "$LOG"
    final_text="$out"
  fi

  local status_line
  status_line=$(grep -o 'AUTORUN_STATUS:.*' <<<"$final_text" | tail -n1 || true)

  if [[ -z "$status_line" ]]; then
    echo "Warning: no AUTORUN_STATUS trailer found in the final text response for: $command_text" | tee -a "$LOG"
    echo "Treating as NEEDS_HUMAN — see $LOG for the full transcript of this step." | tee -a "$LOG"
    echo "Stopped. Resolve manually (see $LOG for the full transcript), then re-run: $0 $SLUG <phase> — or <phase>:review to resume at that phase's review step" | tee -a "$LOG"
    exit 1
  fi

  echo "$status_line" | tee -a "$LOG"

  if [[ "$status_line" == AUTORUN_STATUS:\ OK* ]]; then
    return 0
  fi

  echo "Stopped at: $label" | tee -a "$LOG"
  echo "Reason: $status_line" | tee -a "$LOG"
  echo "Review $LOG for the full transcript. Resolve manually, then re-run: $0 $SLUG <phase> (or <phase>:review to skip straight to that phase's review step) — this resumes from that point onward without redoing already-committed work." | tee -a "$LOG"
  exit 1
}

first=1
for N in "${PHASES[@]}"; do
  if [[ $first -eq 1 && "$START_STEP" == "review" ]]; then
    # Only the first resumed phase can skip implement — it's the one whose
    # implement step already finished and committed before the run stopped.
    echo "Skipping Phase $N implement step (resumed at ${N}:review)." | tee -a "$LOG"
  else
    run_step "Phase $N: implement" "implement-phase-auto" "$N $SLUG" "p${N}-implement"
  fi
  run_step "Phase $N: review" "review-phase-auto" "$N $SLUG" "p${N}-review"
  first=0
done

run_step "Finalize" "finalize" "$SLUG" "finalize"

echo "" | tee -a "$LOG"
echo "All phases complete and finalized." | tee -a "$LOG"
echo "Review $LOG, then merge feature/$SLUG-phase-* to main manually, and run /archive $SLUG afterward." | tee -a "$LOG"
