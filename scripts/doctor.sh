#!/usr/bin/env bash
#
# doctor.sh — the harness repo's permanent static test suite.
#
# This repo makes a pile of *structural* claims — agent permission tables
# stay in sync, no prompt suggests `git add -A`, AGENTS.md stays a ≤80-line
# navigation file, docs' file counts match reality, `.gitignore` keeps the
# scratch dirs protected, required procedure steps survive every prose
# condensation pass. Prose claims rot silently: the next refactor can
# break any of them and nothing currently notices. doctor.sh turns each
# claim into an executable check, so "the harness is still self-consistent"
# is one command instead of a grep-and-pray exercise (docs/harness-
# streamlining/architecture.md, spec FR3/FR4).
#
# harness-repo-only; never shipped; no CI in v1 — it asserts claims about
# THIS repo's files (shipping it to third parties would be meaningless)
# and a CI hookup would be maintenance surface with no consumer yet.
#
# Usage:
#   scripts/doctor.sh        # no arguments; runs from ANY cwd — the repo
#                            # root is resolved from this script's own
#                            # location, never from the caller's cwd
#
# Exit codes:
#   0  every check and the simulation stage passed; the simulation scratch
#      dir was cleaned up
#   1  at least one step failed; .scratch/doctor-sim/ is KEPT for diagnosis
#   2  environment/usage error (argument given, not inside a harness-repo
#      checkout, DOCTOR_EXTRA_CHECKS names a missing file)
#
# Requires: bash ≥ 4.4 (empty-array expansion under `set -u`). The Task
# 3.4 simulation will additionally need git plumbing; the skeleton doesn't.
#
# Layout — how later tasks plug in (Tasks 3.2/3.3 add checks, 3.4 sim):
#   A check is a zero-argument function. It reads $REPO_ROOT, prints one
#   diagnostic line per problem it finds on failure (stdout, anything —
#   shown indented under its FAIL line), returns 0 = pass / non-zero =
#   fail. Adding a check = one function in the Checks section below + one
#   register_check line there, nothing else. The simulation stage's
#   scratch dir lifecycle (fresh before the stage, kept on fail, cleaned
#   on pass) is owned by the Flow section — sim bodies must not duplicate
#   it, just write artifacts under $DOCTOR_SIM_DIR.
#
# Test seam:
#   DOCTOR_EXTRA_CHECKS=<path> sources <path> as bash before the run. The
#   file calls register_check <name> to add checks on top of the shipped
#   ones. This is how the throwaway TDD harness drives artificial
#   pass/fail cases without a deliberately-broken check ever being
#   committed into this file. Unset in normal use.

set -euo pipefail

if [[ $# -ne 0 ]]; then
  echo "Usage: $0   (doctor takes no arguments)" >&2
  exit 2
fi

# Resolve the repo root from THIS script's own location, never from cwd:
# doctor.sh checks the repo it lives in. (`git rev-parse --show-toplevel`
# would follow the caller's cwd and could describe a different repo
# entirely when invoked by absolute path from elsewhere.)
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$script_dir/.." && pwd)

if [[ ! -d "$REPO_ROOT/.opencode" ]]; then
  echo "Error: $REPO_ROOT has no .opencode/ — scripts/doctor.sh must live inside the harness repo checkout it checks." >&2
  exit 2
fi

DOCTOR_SIM_DIR="$REPO_ROOT/.scratch/doctor-sim"

# ---------------------------------------------------------------------------
# Check registry
# ---------------------------------------------------------------------------
CHECKS=()
register_check() { CHECKS+=("$1"); }

# ---------------------------------------------------------------------------
# Checks
#
# Task 3.2 adds the 8 static checks (role-table permissions, `<fill in`
# absence, no `git add -A`, .gitignore entries, docs file counts, grill
# whitelist, AGENTS.md ≤ 80 lines, shipped watcher entries) and Task 3.3
# the invariant-marker presence check — each as one function plus one
# register_check line, here. The skeleton ships with none registered on
# purpose: the flow is proven by the simulation stage plus injected checks
# (see Test seam in the header).
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Simulation stage (Task 3.4 fills this in — spec FR4)
#
# sim_worktree_flow runs with $DOCTOR_SIM_DIR freshly created and keeps
# every artifact it writes inside it; its pass/fail feeds both the exit
# code and the scratch dir's keep/clean decision.
# ---------------------------------------------------------------------------
sim_worktree_flow() {
  # Task 3.4 replaces this placeholder body with the pure-git worktree-flow
  # simulation (slug 1's part-B flow). 3.1 only needs the seam exercised
  # end to end, so the placeholder proves the directory is real and
  # writable — a kept-on-fail dir therefore contains visible evidence of
  # the run that kept it.
  echo "placeholder — the pure-git worktree simulation lands in Task 3.4" \
    > "$DOCTOR_SIM_DIR/sim-placeholder.txt"
}
SIM_STEPS=(sim_worktree_flow)

# ---------------------------------------------------------------------------
# Test seam (see header): inject checks from an external file.
# ---------------------------------------------------------------------------
if [[ -n "${DOCTOR_EXTRA_CHECKS:-}" ]]; then
  if [[ ! -f "$DOCTOR_EXTRA_CHECKS" ]]; then
    echo "Error: DOCTOR_EXTRA_CHECKS=$DOCTOR_EXTRA_CHECKS does not name a readable file." >&2
    exit 2
  fi
  # shellcheck source=/dev/null  # external runtime path (TDD-harness fixture), not a repo file
  source "$DOCTOR_EXTRA_CHECKS"
fi

# ---------------------------------------------------------------------------
# Flow
# ---------------------------------------------------------------------------

# Run one registered step: prints exactly one PASS/FAIL header line plus
# the step's own output indented underneath on failure, and returns the
# step's status. The step runs inside a command substitution with errexit
# off so a check's internal failing commands can't trip doctor's own
# `set -e` — the loop wants the step's 0/1, nothing else. (The `if
# out=$(...)` shape is load-bearing for the same reason autorun.sh guards
# its extractions: under `set -e` a non-zero command substitution in a
# plain assignment would kill this script before any handling could run.)
run_step() {
  local name="$1" out
  if out=$( set +e; "$name" 2>&1 ); then
    echo "PASS  $name"
    return 0
  fi
  echo "FAIL  $name"
  if [[ -n "$out" ]]; then
    sed 's/^/        /' <<<"$out"
  fi
  return 1
}

# The scratch dir may only ever be removed at its exact intended path —
# cheap belt-and-braces so a mis-resolved root can't aim rm -rf elsewhere.
assert_sim_dir_is_expected() {
  if [[ "$DOCTOR_SIM_DIR" != "$REPO_ROOT/.scratch/doctor-sim" || "$REPO_ROOT" == "/" ]]; then
    echo "Error: refusing to touch scratch dir at unexpected path: $DOCTOR_SIM_DIR" >&2
    exit 2
  fi
}

prepare_sim_dir() {
  assert_sim_dir_is_expected
  rm -rf "$DOCTOR_SIM_DIR"  # stale output of an earlier failed run — every run gets a fresh stage
  mkdir -p "$DOCTOR_SIM_DIR"
}

cleanup_sim_dir() {
  assert_sim_dir_is_expected
  rm -rf "$DOCTOR_SIM_DIR"
}

echo "doctor: checking $REPO_ROOT"

pass_count=0
fail_count=0

for name in "${CHECKS[@]}"; do
  if run_step "$name"; then
    pass_count=$((pass_count + 1))
  else
    fail_count=$((fail_count + 1))
  fi
done

# The simulation stage runs even when checks already failed: a one-shot
# test suite is worth its price only when it reports the COMPLETE failure
# list, not fail-fast on the first one.
prepare_sim_dir
for name in "${SIM_STEPS[@]}"; do
  if run_step "$name"; then
    pass_count=$((pass_count + 1))
  else
    fail_count=$((fail_count + 1))
  fi
done

if (( fail_count == 0 )); then
  cleanup_sim_dir
  echo "doctor: ${pass_count} passed, 0 failed — simulation scratch cleaned."
  exit 0
fi

echo "doctor: ${pass_count} passed, ${fail_count} failed."
echo "doctor: simulation scratch kept for diagnosis at $DOCTOR_SIM_DIR"
exit 1
