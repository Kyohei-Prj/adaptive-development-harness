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
# Task 3.2 landed the 8 permanent static checks below (role-table
# permissions, `<fill in` absence, no `git add -A`, .gitignore entries,
# README file counts, grill whitelist, AGENTS.md ≤ 80 lines, shipped
# watcher entries); Task 3.3 adds the invariant-marker presence check the
# same way — one function plus one register_check line, nothing else.
# ---------------------------------------------------------------------------

# CHECK 1 — role-table permissions: denylist-DRIFT check over the per-agent
# copies (FR8 fallback branch: gate experiment B was reclassified FAIL and
# the shared-denylist hoist was abandoned — docs/harness-streamlining/
# gate-experiments.md Decision; the plan pre-sanctioned this adaptation).
#
# "In sync" here can only mean "matches its recorded golden": the shared
# denylist is deliberately duplicated per agent-file, so the golden is a
# per-agent ORDERED pattern→action stream parsed from each frontmatter's
# `bash:` key. Constraints encoded (each from a recorded feedback-log risk):
#   * ORDER, not just membership: a deny only protects when it sits AFTER
#     its own agent's `"*": allow` catch-all (last-match-wins). A set
#     equality would miss an in-file reorder that silently disarms every
#     deny — the exact silent-failure class this slug exists to catch —
#     so the golden diff is order-sensitive by construction.
#   * Per-agent reality, not a uniform shared-17 (feedback-log NB5): the
#     5 map-form agents differ — architecture-reviewer and phase-reviewer
#     carry 23 denies each, task-implementer and issue-resolver 19, and
#     lead 23 denies + 2 scoped allows (`git merge task/*`,
#     `git mv docs/* docs/_archive/*`).
#   * Both shapes of the `bash:` key (Phase 1 NB4): map form (the 5 above)
#     and whole-string `bash: deny` (doc-updater, planner, grill) — the
#     latter golden exactly ONE "string deny" line per agent (wholesale
#     bash deny; its resolved entry-diff would be semantically inert).
#
# NEVER treat entry presence in `opencode debug agent` as proof of
# protection: Experiment B's disarmed deny still *appeared* in the resolved
# output — presence proves nothing, order does. That is also why this check
# parses the in-repo frontmatter files as the source of truth instead of
# `opencode debug agent`/`opencode debug config` (v1.18.35 has both, but
# they merge the author's global ~/.config/opencode layer and would make
# the golden machine-dependent). Parser: awk over the regular frontmatter
# shape — deliberately no python3/PyYAML prerequisite (the README lists
# neither); if the frontmatter ever grows irregular, the parse output
# drifts and this check goes red loudly, never a silent skip.
#
# Regenerating the golden after an INTENTIONAL permission change: run this
# check on the changed repo — the FAIL diff shows the new reality as `+`
# lines; strip the `+`, replace the heredoc body, and re-read the
# gate-experiments.md Decision before committing (this is the change that
# has to have a reason).
check_role_table_permissions() {
  local golden live d bad=0 f files
  golden=$(cat <<'GOLDEN'
architecture-reviewer	map	
architecture-reviewer	allow	*
architecture-reviewer	deny	git push --force*
architecture-reviewer	deny	git push -f*
architecture-reviewer	deny	git push origin +*
architecture-reviewer	deny	rm -rf*
architecture-reviewer	deny	rm -fr*
architecture-reviewer	deny	git reset --hard*
architecture-reviewer	deny	git checkout -- .*
architecture-reviewer	deny	git checkout --force*
architecture-reviewer	deny	git clean -f*
architecture-reviewer	deny	git branch -D*
architecture-reviewer	deny	git commit *
architecture-reviewer	deny	git add *
architecture-reviewer	deny	git push*
architecture-reviewer	deny	*rm -rf*
architecture-reviewer	deny	*rm -fr*
architecture-reviewer	deny	*reset --hard*
architecture-reviewer	deny	*checkout -- .*
architecture-reviewer	deny	*checkout --force*
architecture-reviewer	deny	*git clean -f*
architecture-reviewer	deny	*branch -D*
architecture-reviewer	deny	*git commit *
architecture-reviewer	deny	*git add *
architecture-reviewer	deny	*git push*
doc-updater	string	deny
grill	string	deny
issue-resolver	map	
issue-resolver	allow	*
issue-resolver	deny	git push --force*
issue-resolver	deny	git push -f*
issue-resolver	deny	git push origin +*
issue-resolver	deny	rm -rf*
issue-resolver	deny	rm -fr*
issue-resolver	deny	git reset --hard*
issue-resolver	deny	git checkout -- .*
issue-resolver	deny	git checkout --force*
issue-resolver	deny	git clean -f*
issue-resolver	deny	git branch -D*
issue-resolver	deny	*rm -rf*
issue-resolver	deny	*rm -fr*
issue-resolver	deny	*reset --hard*
issue-resolver	deny	*checkout -- .*
issue-resolver	deny	*checkout --force*
issue-resolver	deny	*git clean -f*
issue-resolver	deny	*push --force*
issue-resolver	deny	*push -f *
issue-resolver	deny	*branch -D*
lead	map	
lead	allow	*
lead	deny	git push --force*
lead	deny	git push -f*
lead	deny	git push origin +*
lead	deny	git push*
lead	deny	rm -rf*
lead	deny	rm -fr*
lead	deny	git reset --hard*
lead	deny	git checkout -- .*
lead	deny	git checkout --force*
lead	deny	git clean -f*
lead	deny	git branch -D*
lead	deny	*rm -rf*
lead	deny	*rm -fr*
lead	deny	*reset --hard*
lead	deny	*checkout -- .*
lead	deny	*checkout --force*
lead	deny	*git clean -f*
lead	deny	*push --force*
lead	deny	*push -f *
lead	deny	*branch -D*
lead	deny	*git push*
lead	deny	git merge *
lead	allow	git merge task/*
lead	deny	git mv *
lead	allow	git mv docs/* docs/_archive/*
phase-reviewer	map	
phase-reviewer	allow	*
phase-reviewer	deny	git push --force*
phase-reviewer	deny	git push -f*
phase-reviewer	deny	git push origin +*
phase-reviewer	deny	rm -rf*
phase-reviewer	deny	rm -fr*
phase-reviewer	deny	git reset --hard*
phase-reviewer	deny	git checkout -- .*
phase-reviewer	deny	git checkout --force*
phase-reviewer	deny	git clean -f*
phase-reviewer	deny	git branch -D*
phase-reviewer	deny	git commit *
phase-reviewer	deny	git add *
phase-reviewer	deny	git push*
phase-reviewer	deny	*rm -rf*
phase-reviewer	deny	*rm -fr*
phase-reviewer	deny	*reset --hard*
phase-reviewer	deny	*checkout -- .*
phase-reviewer	deny	*checkout --force*
phase-reviewer	deny	*git clean -f*
phase-reviewer	deny	*branch -D*
phase-reviewer	deny	*git commit *
phase-reviewer	deny	*git add *
phase-reviewer	deny	*git push*
planner	string	deny
task-implementer	map	
task-implementer	allow	*
task-implementer	deny	git push --force*
task-implementer	deny	git push -f*
task-implementer	deny	git push origin +*
task-implementer	deny	rm -rf*
task-implementer	deny	rm -fr*
task-implementer	deny	git reset --hard*
task-implementer	deny	git checkout -- .*
task-implementer	deny	git checkout --force*
task-implementer	deny	git clean -f*
task-implementer	deny	git branch -D*
task-implementer	deny	*rm -rf*
task-implementer	deny	*rm -fr*
task-implementer	deny	*reset --hard*
task-implementer	deny	*checkout -- .*
task-implementer	deny	*checkout --force*
task-implementer	deny	*git clean -f*
task-implementer	deny	*push --force*
task-implementer	deny	*push -f *
task-implementer	deny	*branch -D*
GOLDEN
)
  files=("$REPO_ROOT"/.opencode/agents/*.md)
  if [[ ! -e "${files[0]}" ]]; then
    echo "no agent files under $REPO_ROOT/.opencode/agents/"
    return 1
  fi
  live=$(for f in "${files[@]}"; do
    awk -v name="${f##*/}" '
      BEGIN { name = substr(name, 1, length(name) - 3) }
      NR == 1 {
        if ($0 != "---") { printf "%s\tfrontmatter-missing\t\n", name; exit }
        infm = 1; next
      }
      infm && $0 == "---" { exit }
      !infm { next }
      !seen && /^  bash:[ \t]*$/ { seen = 1; ismap = 1; printf "%s\tmap\t\n", name; next }
      !seen && /^  bash:[ \t]*[^ \t]/ {
        seen = 1; v = $0; sub(/^  bash:[ \t]*/, "", v)
        printf "%s\tstring\t%s\n", name, v; exit
      }
      ismap && /^    "[^"]*":[ \t]*(allow|deny|ask)[ \t]*$/ {
        line = $0
        match(line, /"[^"]*"/)
        pat = substr(line, RSTART + 1, RLENGTH - 2)
        act = line; sub(/^.*:[ \t]*/, "", act); gsub(/[ \t]+$/, "", act)
        printf "%s\t%s\t%s\n", name, act, pat; next
      }
      ismap && !/^[ \t]*$/ { exit }
    ' "$f"
  done)
  if [[ "$live" != "$golden" ]]; then
    d=$(diff --label golden --label live -u <(printf '%s\n' "$golden") <(printf '%s\n' "$live") | head -n 40)
    printf 'parsed bash-permission stream differs from the golden (ORDER-sensitive; see function header):\n%s\n' "$d"
    bad=1
  fi
  # Complementary architecture invariant: the failed hoist must NOT be
  # re-applied — the shipped config carries no top-level `permission` key
  # (an agent's `"*": allow` catch-all out-votes config-layer denies at
  # runtime while they still appear resolved; gate-experiments.md).
  if grep -qE '^  "permission"' "$REPO_ROOT/.opencode/opencode.json" 2>/dev/null; then
    echo 'top-level "permission" key present in .opencode/opencode.json — the FR8-failed denylist hoist must NOT be re-applied (gate-experiments.md Decision)'
    bad=1
  fi
  return "$bad"
}

# CHECK 2 — no `<fill in` template placeholder survives into a shipped
# prompt surface: a placeholder that reached .opencode/ is an unfinished
# prompt pretending to be finished. node_modules/ is excluded from every
# .opencode/ traversal (install artifact, not harness content).
check_no_fill_in_placeholders() {
  local out rc=0
  out=$(grep -rnF '<fill in' "$REPO_ROOT/.opencode" --exclude-dir=node_modules 2>&1) || rc=$?
  if (( rc == 0 )); then
    printf '%s\n' "$out"
    echo "'<fill in' template placeholder(s) found under .opencode/"
    return 1
  elif (( rc > 1 )); then
    printf 'grep failed: %s\n' "$out"
    return 1
  fi
}

# CHECK 3 — no shipped prompt tells anyone to run `git add -A` (explicit
# paths only; see AGENTS.md "Commit explicit paths"). Deliberately scoped
# to .opencode/, unlike a whole-repo grep: the docs and this script's own
# comments legitimately NAME the forbidden pattern while explaining why
# it is forbidden — grepping them would false-positive on the explanation
# (precedent: harness-defects slug's acceptance grepped .opencode/ too).
check_no_git_add_all() {
  local out rc=0
  out=$(grep -rnF 'git add -A' "$REPO_ROOT/.opencode" --exclude-dir=node_modules 2>&1) || rc=$?
  if (( rc == 0 )); then
    printf '%s\n' "$out"
    echo "'git add -A' found under .opencode/ (shipped prompts must stage explicit paths only)"
    return 1
  elif (( rc > 1 )); then
    printf 'grep failed: %s\n' "$out"
    return 1
  fi
}

# CHECK 4 — .gitignore keeps the harness's three shipped lines: README's
# copy-instructions call them "the harness's three lines" — .worktrees/
# (parallel-task worktrees), .scratch/ (agent scratch space), and
# **/autorun.log (unattended-run output). Losing any means git starts
# tracking harness ephemera. /.serena/ is an editor-local extra, not part
# of that claim, so it is NOT asserted.
check_gitignore_shipped_entries() {
  local bad=0 line
  for line in '.worktrees/' '.scratch/' '**/autorun.log'; do
    grep -qxF -- "$line" "$REPO_ROOT/.gitignore" || {
      echo ".gitignore missing shipped line: $line"
      bad=1
    }
  done
  return "$bad"
}

# CHECK 5 — README's "Minimal footprint" counts and its directory-tree
# scripts/ listing match the files on disk. Prose counts rot silently on
# every file added (this check's own reason to exist: Task 3.2 made the
# claim "1 script" false the moment doctor.sh landed).
check_readme_file_counts() {
  local readme="$REPO_ROOT/README.md" bad=0 claim base
  local a c s k n_agents n_cmds n_skills n_scripts
  claim=$(grep -oE '[0-9]+ agent files, [0-9]+ command files, [0-9]+ skills, [0-9]+ scripts?' "$readme" | head -n 1)
  if [[ -z "$claim" ]]; then
    echo 'README minimal-footprint sentence not found (removed, or reworded past this parse — update check_readme_file_counts)'
    return 1
  fi
  read -r a c s k <<<"$(sed -E 's/([0-9]+) agent files, ([0-9]+) command files, ([0-9]+) skills, ([0-9]+) scripts?/\1 \2 \3 \4/' <<<"$claim")"
  n_agents=$(find "$REPO_ROOT/.opencode/agents" -maxdepth 1 -name '*.md' | wc -l)
  n_cmds=$(find "$REPO_ROOT/.opencode/commands" -maxdepth 1 -name '*.md' | wc -l)
  n_skills=$(find "$REPO_ROOT/.opencode/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)
  n_scripts=$(find "$REPO_ROOT/scripts" -maxdepth 1 -name '*.sh' | wc -l)
  (( a == n_agents )) || { echo "README claims $a agent files, found $n_agents"; bad=1; }
  (( c == n_cmds )) || { echo "README claims $c command files, found $n_cmds"; bad=1; }
  (( s == n_skills )) || { echo "README claims $s skills, found $n_skills"; bad=1; }
  (( k == n_scripts )) || { echo "README claims $k script(s), found $n_scripts in scripts/"; bad=1; }
  # Tree cross-check for scripts/ (the surface this task's claims cover),
  # both directions: every real script is listed in the tree…
  while read -r base; do
    grep -qF -- "── $base" "$readme" || {
      echo "scripts/$base not listed in README's directory tree"
      bad=1
    }
  done < <(find "$REPO_ROOT/scripts" -maxdepth 1 -name '*.sh' -exec basename {} \;)
  # …and every .sh the tree lists under a tree-branch glyph exists.
  while read -r base; do
    [[ -f "$REPO_ROOT/scripts/$base" ]] || {
      echo "README's tree lists scripts/$base but the file is absent"
      bad=1
    }
  done < <(grep -oE '(├|└)── [A-Za-z0-9._-]+\.sh' "$readme" | sed -E 's/.*── //')
  return "$bad"
}

# CHECK 6 — grill's task whitelist stays within {explore, scout}: grill is
# alignment-only, allowed to consult the codebase through read-only
# subagents but never to spawn implementation- or review-side work. A
# third allowed subagent (or a re-allowed "*") reopens that hole.
check_grill_task_whitelist() {
  local grill="$REPO_ROOT/.opencode/agents/grill.md" bad=0 name names
  names=$(awk '
    NR == 1 { if ($0 != "---") exit; infm = 1; next }
    infm && $0 == "---" { exit }
    !infm { next }
    /^  task:[ \t]*$/ { t = 1; next }
    t && /^    "[^"]*":[ \t]*(allow|deny|ask)[ \t]*$/ {
      line = $0
      match(line, /"[^"]*"/)
      pat = substr(line, RSTART + 1, RLENGTH - 2)
      act = line; sub(/^.*:[ \t]*/, "", act); gsub(/[ \t]+$/, "", act)
      if (act != "deny") print pat
      next
    }
    t && !/^[ \t]*$/ { exit }
  ' "$grill")
  # Any non-deny action counts as whitelisted: an `ask` on a third
  # subagent would still let the call through the door the deny closed.
  for name in $names; do
    case "$name" in
      explore | scout) ;;
      *) echo "grill task whitelist allows unexpected subagent: $name (expected ⊆ {explore, scout})"; bad=1 ;;
    esac
  done
  return "$bad"
}

# CHECK 7 — AGENTS.md stays ≤ 80 lines: it is auto-loaded navigation for
# every session; past that budget it is a tax rather than a map.
check_agents_md_line_limit() {
  local n
  n=$(wc -l < "$REPO_ROOT/AGENTS.md")
  if (( n > 80 )); then
    echo "AGENTS.md is $n lines (limit 80) — move prose to README and link it"
    return 1
  fi
}

# CHECK 8 — the shipped .opencode/opencode.json keeps its 11 watcher.ignore
# entries. Intentionally PRESENCE-only (superset allowed), not exact-set:
# the rot this guards is an accidental REMOVAL (dropping .git/** or
# .worktrees/** reintroduces watcher churn); additions are legitimate
# per-deployment config changes a PR review should judge, not this check.
check_watcher_ignore_entries() {
  local cfg="$REPO_ROOT/.opencode/opencode.json" bad=0 e ignore
  local entries=(
    'node_modules/**' 'dist/**' 'build/**' '.git/**' '**/*.min.js'
    '**/*.map' '**/*.lock' '.venv/**' '.opencode/**' '.worktrees/**'
    '.scratch/**'
  )
  ignore=$(awk '/"ignore": \[/,/\]/' "$cfg" 2>/dev/null)
  if [[ -z "$ignore" ]]; then
    echo 'no watcher.ignore array found in .opencode/opencode.json'
    return 1
  fi
  for e in "${entries[@]}"; do
    grep -qF -- "\"$e\"" <<<"$ignore" || {
      echo "watcher.ignore missing shipped entry: $e"
      bad=1
    }
  done
  return "$bad"
}

register_check check_role_table_permissions
register_check check_no_fill_in_placeholders
register_check check_no_git_add_all
register_check check_gitignore_shipped_entries
register_check check_readme_file_counts
register_check check_grill_task_whitelist
register_check check_agents_md_line_limit
register_check check_watcher_ignore_entries

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
