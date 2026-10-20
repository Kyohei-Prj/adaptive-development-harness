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
# Requires: bash ≥ 4.4 (empty-array expansion under `set -u`); git ≥ 2.32
# for the Task 3.4 simulation (`git init -b`, `git worktree`, hermetic
# config via GIT_CONFIG_GLOBAL/GIT_CONFIG_SYSTEM).
#
# Layout — how later tasks plug in (3.2/3.3 added the checks; 3.4 filled
#   in the simulation below):
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
#
#   DOCTOR_SIM_SKIP_VERIFY=1 drops the simulation's step-4 verification
#   call — cleanup then runs blind with the force flags part B's invariant
#   forbids. It is the executable fixture for "a condensation pass deleted
#   the step": while it is set, the simulation MUST fail (scenarios assert
#   via their trace that the verify step actually observed their fixtures).
#   Demonstration/diagnosis only, like DOCTOR_EXTRA_CHECKS; unset normally.

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
#     carry 27 denies each, task-implementer and issue-resolver 21, and
#     lead 25 denies + 2 scoped allows (`git merge task/*`,
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
# drifts and this check goes red loudly — for whatever the awk pattern
# reads over; an irregularity wholly outside that pattern could still slip
# through silently (same parser-philosophy caveat as CHECK 10).
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
architecture-reviewer	deny	*push --force*
architecture-reviewer	deny	*push -f *
architecture-reviewer	deny	git worktree remove --force*
architecture-reviewer	deny	*worktree remove --force*
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
issue-resolver	deny	git worktree remove --force*
issue-resolver	deny	*worktree remove --force*
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
lead	deny	git worktree remove --force*
lead	deny	*worktree remove --force*
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
phase-reviewer	deny	*push --force*
phase-reviewer	deny	*push -f *
phase-reviewer	deny	git worktree remove --force*
phase-reviewer	deny	*worktree remove --force*
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
task-implementer	deny	git worktree remove --force*
task-implementer	deny	*worktree remove --force*
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
  # re-applied — no `permission` key at ANY depth or formatting of the
  # shipped config: per-agent maps live in the agent .md frontmatter (the
  # golden above), so one in the config-layer file is the hoist shape or a
  # variant (an agent's `"*": allow` catch-all out-votes config-layer
  # denies at runtime while they still appear resolved; gate-experiments.md).
  if grep -qE '"permission"[[:space:]]*:' "$REPO_ROOT/.opencode/opencode.json" 2>/dev/null; then
    echo '"permission" key present in .opencode/opencode.json — the FR8-failed denylist hoist must NOT be re-applied (gate-experiments.md Decision)'
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
  # Zero parsed names is NOT a pass: a renamed/reindented `task:` key or
  # removed entries would leave the loop below unrun and the whitelist
  # invariant silently unverifiable — go red on the shape change itself.
  [[ -n "$names" ]] || { echo "grill task block parsed empty — frontmatter shape changed?"; return 1; }
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

# CHECK 9 — invariant-marker presence (positive-presence; architecture.md
# "Decision: `<!-- invariant: … -->` markers"): the absence-checks above
# can't notice a prose condensation pass accidentally DELETING a required
# step, so the two load-bearing worktree steps carry HTML-comment markers
# that must exist. The ids below are the golden; renaming one is a
# deliberate two-sided change (marker + this list, with a reason).
check_invariant_markers() {
  local skill="$REPO_ROOT/.opencode/skills/phase-lifecycle/SKILL.md" bad=0 id where
  if [[ ! -f "$skill" ]]; then
    echo ".opencode/skills/phase-lifecycle/SKILL.md is missing — its invariant markers can't be checked"
    return 1
  fi
  for id in worktree-commit-before-report worktree-clean-and-landed-verification; do
    grep -qF -- "<!-- invariant: $id -->" "$skill" || {
      case "$id" in
        worktree-commit-before-report)
          where="part B step 2, on the commit-before-report requirement inside the delegation instructions" ;;
        worktree-clean-and-landed-verification)
          where="part B step 4, on the verify-before-cleanup gate (porcelain-clean AND merge-base --is-ancestor, with the never-force-remove rule)" ;;
      esac
      echo "invariant marker '<!-- invariant: $id -->' missing from .opencode/skills/phase-lifecycle/SKILL.md — it belongs on $where; if that step was deliberately removed, drop this id from check_invariant_markers in the same commit and say why"
      bad=1
    }
  done
  return "$bad"
}

# CHECK 10 — vocabulary consistency (docs/workflow-patterns spec FR1/FR10:
# "the vocabulary appears in exactly one source of truth (`planning-docs`
# skill) and consistent copies elsewhere are enforced by doctor"). Golden-
# list-in-doctor pattern, as in check_invariant_markers: the id-set is
# written down ONCE below and every carrying file is compared with it, so
# a deliberate vocabulary change updates this golden in the same commit
# and says why.
#
# One `vocab` entry per vocabulary dimension:
#   '<dimension>|<golden ids>|<carrying files, source of truth first>'
# A file carries an id when its text contains the `[<dimension>: <id>]`
# form; a `|`-list (`[type: tdd|smoke]`) counts as every member, and the
# template placeholder `[type: ...]` is NOT an id. Ids are detected over the
# `[a-z|-]` character class (lowercase letters, `|`, `-`) — the shape the
# vocabulary actually uses — so a lost golden id drops out of the parse and
# goes red as "missing", loudly; but an off-vocabulary id using characters
# OUTSIDE that class — digits or uppercase, e.g. `[type: tdd2]` or
# `[mode: AUTOS]` — never enters the parse at all and slips past the extra
# direction silently (same parser philosophy, and same caveat, as CHECK 1).
#
# Comparison is file-vs-golden, not pairwise-file-to-file, so every FAIL
# names exactly one file and one id, and drift is caught in EITHER
# direction: a file that lost a golden id, or a file referencing an id
# outside the vocabulary — an undeclared fifth tag appearing in the source
# of truth goes red exactly like a consumer that stopped knowing one.
#
# THE MODE DIMENSION (workflow-patterns Task 2.4) carries the phase-level
# `[mode: …]` vocabulary — golden `sdd interactive autorun`, source of truth
# the planning-docs skill, consumers planner.md and plan.md. Note what is
# deliberately NOT in the mode set: task-implementer.md stays a `type`-only
# carrier — modes are phase-level and it has no `[mode: …]` refs, so demanding
# them there would enforce a vocabulary that file is never meant to know.
# README.md carries BOTH dimensions: its prose is vocabulary-complete for each
# (type since the Phase 1 drift fix, mode since the README "Mode tags"
# subsection), so the golden list catches README prose drift like any other
# carrier's.
#
# Test seam (same spirit as DOCTOR_EXTRA_CHECKS, see header): an optional
# first argument overrides $REPO_ROOT, so a throwaway harness drives this
# check against scratch fixture trees without touching tracked files.
check_tag_vocabulary_consistency() {
  local root="${1:-$REPO_ROOT}" bad=0
  local entry dim ids files src rel file have missing extra id role
  local -a vocab=(
    'type|tdd smoke spike|.opencode/skills/planning-docs/SKILL.md .opencode/agents/planner.md .opencode/commands/plan.md .opencode/agents/task-implementer.md README.md'
    'mode|sdd interactive autorun|.opencode/skills/planning-docs/SKILL.md .opencode/agents/planner.md .opencode/commands/plan.md README.md'
  )
  for entry in "${vocab[@]}"; do
    IFS='|' read -r dim ids files <<<"$entry"
    src="${files%% *}"
    for rel in $files; do
      file="$root/$rel"
      if [[ ! -f "$file" ]]; then
        printf '%s-vocabulary: %s does not exist — its [%s: …] references cannot be checked\n' "$dim" "$rel" "$dim"
        bad=1
        continue
      fi
      if [[ "$rel" == "$src" ]]; then role="source of truth"; else role="consumer"; fi
      have=$(grep -oE "\[$dim:[[:space:]]*[a-z|-]+\]" "$file" \
        | sed -E "s/^\[$dim:[[:space:]]*//; s/\]$//" | tr '|' '\n' | sort -u) || true
      missing=$(comm -23 <(printf '%s\n' $ids | sed '/^$/d' | sort -u) \
                         <(printf '%s\n' $have | sed '/^$/d' | sort -u)) || true
      extra=$(comm -13 <(printf '%s\n' $ids | sed '/^$/d' | sort -u) \
                       <(printf '%s\n' $have | sed '/^$/d' | sort -u)) || true
      for id in $missing; do
        if [[ "$role" == "source of truth" ]]; then
          printf '%s-vocabulary drift: %s (source of truth) is missing [%s: %s] — golden set: %s; the vocabulary is defined once in this file, so define it here and reference it in every carrying file (a deliberate removal updates this golden in check_tag_vocabulary_consistency in scripts/doctor.sh in the same commit, with a reason)\n' \
            "$dim" "$rel" "$dim" "$id" "$ids"
        else
          printf '%s-vocabulary drift: %s (%s) is missing [%s: %s] — golden set: %s; reference the id exactly as the source of truth %s defines it (a deliberate removal drops it from the source of truth AND from this golden in the same commit, with a reason)\n' \
            "$dim" "$rel" "$role" "$dim" "$id" "$ids" "$src"
        fi
        bad=1
      done
      for id in $extra; do
        if [[ "$role" == "source of truth" ]]; then
          printf '%s-vocabulary drift: %s (source of truth) references [%s: %s], outside the golden set: %s; a new id goes into this golden in check_tag_vocabulary_consistency in scripts/doctor.sh AND every carrying file in the same commit\n' \
            "$dim" "$rel" "$dim" "$id" "$ids"
        else
          printf '%s-vocabulary drift: %s (%s) references [%s: %s], which the source of truth %s does not define — remove the reference or define the id in the source of truth and this golden in the same commit\n' \
            "$dim" "$rel" "$role" "$dim" "$id" "$src"
        fi
        bad=1
      done
    done
  done
  # Pattern Record heading — the same golden-list story as the vocab array:
  # the planning-docs template ships the `## Pattern Record` section the
  # planner's pattern-selection step fills in, and planner.md / plan.md
  # reference it by name. Presence-only on both sides: the template carries
  # the literal heading, the consumers mention the section name in prose
  # (there is no `[pattern: …]` tagged form for the id parser above to see);
  # asserting the section's SHAPE is out of this check's minimal scope.
  grep -qF '## Pattern Record' "$root/.opencode/skills/planning-docs/SKILL.md" || {
    printf 'pattern-record drift: .opencode/skills/planning-docs/SKILL.md (source of truth) no longer carries the "## Pattern Record" heading both consumers point at (a deliberate rename updates template, consumers, and this check in the same commit, with a reason)\n'
    bad=1
  }
  for rel in .opencode/agents/planner.md .opencode/commands/plan.md; do
    grep -qF 'Pattern Record' "$root/$rel" || {
      printf 'pattern-record drift: %s (consumer) no longer references the Pattern Record — the pattern-selection step must point at the "## Pattern Record" template section in .opencode/skills/planning-docs/SKILL.md (a deliberate rename updates template, consumers, and this check in the same commit, with a reason)\n' "$rel"
      bad=1
    }
  done
  return "$bad"
}

# CHECK 11 — mode-gate contract (docs/workflow-patterns spec FR4; the Task 2.3
# review's durability fix). Task 2.3's red→green evidence — 22 grep
# assertions over the three implement commands — lived only in gitignored
# .scratch/ and vanished with it, leaving FR4 with no durable regression
# check: a later edit could delete the Mode gate while doctor stayed green.
# This is the static port of that contract, one-for-one per assertion: each
# command carries a Mode gate step that precedes its "Phase branch setup"
# step (a refusal must mutate no git state), reads the phase's `[mode: …]`
# tag from implementation-plan.md, states the [mode: sdd] /
# [mode: autorun] / absent-tag-=-sdd proceed paths, and states that the
# refusal commits nothing; implement-phase.md additionally refuses
# [mode: interactive] with a forward-looking /interactive pointer; both
# headless commands carry the exact trailer line
# `AUTORUN_STATUS: NEEDS_HUMAN: phase … is [mode: interactive]` (parsed by
# scripts/autorun.sh, formatted per phase-lifecycle part D); autorun.md
# additionally forbids silently skipping ahead past the blocking phase.
# Non-static scratch assertions: none — all 22 were text/structure greps
# over these tracked files, so all 22 are ported.
#
# Golden-presence contract over prose, as in check_invariant_markers: the
# gate step may legitimately be reworded, but a deliberate change updates
# the step and this check in the same commit, with a reason. When a file
# has no gate paragraph at all, one precise line fires and that file's
# window assertions are skipped — they would only echo it (the scratch
# harness counted every failing assertion independently; detection
# equivalence is kept: any drift that reds one of the 22 reds this).
#
# Test seam (same spirit as check_tag_vocabulary_consistency): an optional
# first argument overrides $REPO_ROOT, so a throwaway harness drives this
# check against scratch fixture trees without touching tracked files.
check_mode_gate_contract() {
  local root="${1:-$REPO_ROOT}" bad=0 f n g b gate gate14 why=''
  local -a cmds=(
    .opencode/commands/implement-phase.md
    .opencode/commands/implement-phase-auto.md
    .opencode/commands/autorun.md
  )
  for f in "${cmds[@]}"; do
    n="${f##*/}"
    if [[ ! -f "$root/$f" ]]; then
      printf 'mode-gate drift: %s is missing — its [mode: …] gate cannot be checked (spec FR4; a deliberate command rename updates the file, the gate, and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$f"
      bad=1
      continue
    fi
    # Ordering: the gate step exists AND sits strictly before the numbered
    # "Phase branch setup" step — the refusal must precede any git
    # mutation (no phase branch, no phase-branches.md row, no worktree).
    g=$(grep -n -m1 -i 'Mode gate' "$root/$f" | cut -d: -f1) || true
    b=$(grep -n -m1 -E '^[0-9]+\. Phase branch setup' "$root/$f" | cut -d: -f1) || true
    if [[ -z "$g" ]]; then
      why="no 'Mode gate' step found"
    elif [[ -z "$b" ]]; then
      why="no numbered 'Phase branch setup' step found — the step the gate must precede"
    elif (( g >= b )); then
      why="the gate (line $g) does not precede 'Phase branch setup' (line $b)"
    else
      why=''
    fi
    [[ -z "$why" ]] || {
      printf 'mode-gate drift: %s — %s — the gate must sit before phase branch setup so a [mode: interactive] refusal mutates no git state (spec FR4; a deliberate change to the gate updates the step and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$n" "$why"
      bad=1
    }
    [[ -n "$g" ]] || continue  # whole gate paragraph missing — reported above
    # Gate-body assertions over the step window (the scratch harness's
    # -A12/-A14 windows around every 'Mode gate' occurrence).
    gate=$(grep -A12 -i 'Mode gate' "$root/$f") || true
    grep -qF -- 'implementation-plan.md' <<<"$gate" || {
      printf 'mode-gate drift: %s — the Mode gate step never names implementation-plan.md — it must read the phase [mode: …] tag from docs/<slug>/implementation-plan.md (spec FR4; a deliberate change to where the tag lives updates the step and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$n"
      bad=1
    }
    grep -qE '\[mode: sdd\]' <<<"$gate" || {
      printf 'mode-gate drift: %s — the Mode gate step does not state the [mode: sdd] proceed path (spec FR4; a deliberate vocabulary change updates the step, the planning-docs mode vocabulary, and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$n"
      bad=1
    }
    grep -Eqi 'absent|no tag' <<<"$gate" || {
      printf 'mode-gate drift: %s — the Mode gate step does not state that an absent tag means [mode: sdd] — backward compatibility with pre-mode plans (spec FR4; a deliberate change updates the step and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$n"
      bad=1
    }
    grep -Eqi 'no commit|not.*commit|without commit|do NOT commit|nothing .* commit' <<<"$gate" || {
      printf 'mode-gate drift: %s — the Mode gate step does not state that the refusal commits nothing — the refusal is read-only: no phase branch, no phase-branches.md row, no commit (spec FR4; a deliberate change updates the step and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$n"
      bad=1
    }
    if [[ "$n" == "implement-phase.md" ]]; then
      # interactive entry point: refusal + forward-looking /interactive pointer
      gate14=$(grep -A14 -i 'Mode gate' "$root/$f") || true
      grep -Eqi 'refus' <<<"$gate14" || {
        printf 'mode-gate drift: implement-phase.md — the Mode gate step contains no refusal of [mode: interactive] — the interactive command must stop and not delegate (spec FR4; a deliberate change to the refusal updates the step and this check in scripts/doctor.sh in the same commit, with a reason)\n'
        bad=1
      }
      grep -qF -- '/interactive' <<<"$gate14" || {
        printf 'mode-gate drift: implement-phase.md — the Mode gate step no longer points at /interactive — the refusal must name the interactive entry point to run instead (spec FR4; a deliberate rename updates the step, the command, and this check in scripts/doctor.sh in the same commit, with a reason)\n'
        bad=1
      }
    else
      # headless commands: exact NEEDS_HUMAN trailer + [mode: autorun] proceed
      grep -Eq 'AUTORUN_STATUS: NEEDS_HUMAN: phase (N|\$1|<n>) is \[mode: interactive\]' "$root/$f" || {
        printf 'mode-gate drift: %s — missing the exact trailer line AUTORUN_STATUS: NEEDS_HUMAN: phase <n> is [mode: interactive] — the surrounding flow parses this trailer to detect the gate stop (spec FR4; a deliberate trailer-format change updates the step, scripts/autorun.sh and phase-lifecycle part D, and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$n"
        bad=1
      }
      grep -qE '\[mode: autorun\]' <<<"$gate" || {
        printf 'mode-gate drift: %s — the Mode gate step does not state the [mode: autorun] proceed path (spec FR4; a deliberate vocabulary change updates the step, the planning-docs mode vocabulary, and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$n"
        bad=1
      }
      if [[ "$n" == "autorun.md" ]]; then
        grep -Eqi 'not skip ahead' <<<"$gate" || {
          printf 'mode-gate drift: autorun.md — the Mode gate step does not forbid skipping ahead — the multi-phase run must halt at the blocking phase, not silently continue with later phases (spec FR4; a deliberate change updates the step and this check in scripts/doctor.sh in the same commit, with a reason)\n'
          bad=1
        }
      fi
    fi
  done
  return "$bad"
}

# CHECK 12 — acceptance-review contract (docs/workflow-patterns spec FR6
# clauses (a) and (b), made durable per FR10; the static half of Task 3.4's
# fixture-run evidence, same durability reasoning as CHECK 11: the scratch
# fixture's blocking/not-blocking verdicts vanish with .scratch/, this check
# is what survives — a later prose-condensation pass must not be able to
# delete the reviewer's "Acceptance scenario compliance" section or its
# diff lock while doctor stays green).
#
# Golden-presence contract over prose, as in check_invariant_markers /
# CHECK 11: the section may legitimately be reworded, but a deliberate
# change updates the prompt and this check in the same commit, with a
# reason. Anchors are deliberately tight — exact substrings and single-line
# regexes, NOT windowed -A12/-A14 greps (the fragility the Phase 2 review
# flagged in CHECK 11): every assertion is a whole-file presence test, and
# a missing file fires one precise line with that file's other assertions
# skipped (they would only echo it).
#
# What is deliberately NOT asserted: the Draft-gate and absent-file rules
# the section also carries — the check's mandate (plan Task 3.4) is the
# section + diff rule; those behaviours stay fixture-tested prose.
#
# Test seam (same spirit as check_mode_gate_contract): an optional first
# argument overrides $REPO_ROOT, so a throwaway harness drives this check
# against scratch fixture trees — pre-change or tampered prompt copies —
# without touching tracked files.
check_acceptance_review_contract() {
  local root="${1:-$REPO_ROOT}" bad=0 fp rp
  fp=".opencode/agents/phase-reviewer.md"
  rp=".opencode/commands/review-phase.md"
  # The reviewer prompt — the section carrying FR6(a) green evidence per
  # scenario / uncovered, and the FR6(b) diff lock with its logged approval.
  if [[ ! -f "$root/$fp" ]]; then
    printf 'acceptance-review drift: %s is missing — the "Acceptance scenario compliance" section cannot be checked (spec FR6; a deliberate rename/move updates the file and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$fp"
    bad=1
  else
    grep -qF 'Acceptance scenario compliance' "$root/$fp" || {
      printf 'acceptance-review drift: %s — no "Acceptance scenario compliance" report section — the phase review must report per-scenario evidence and run the acceptance.md diff lock (spec FR6; a deliberate removal of this review duty updates the reviewer prompt and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$fp"
      bad=1
    }
    grep -qiE 'green evidence' "$root/$fp" || {
      printf 'acceptance-review drift: %s — the section no longer demands green evidence per scenario — every numbered scenario in docs/<slug>/acceptance.md must name the test/check that proves it (spec FR6 clause (a); a deliberate change updates the reviewer prompt and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$fp"
      bad=1
    }
    grep -qiE 'scenario[^.]*uncovered|uncovered[^.]*scenario' "$root/$fp" || {
      printf 'acceptance-review drift: %s — the section no longer flags an unproven scenario as uncovered — missing proof must be reported explicitly, never silently omitted (spec FR6 clause (a); a deliberate change updates the reviewer prompt and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$fp"
      bad=1
    }
    grep -qF -- 'git diff <base>...HEAD -- docs/<slug>/acceptance.md' "$root/$fp" || {
      printf 'acceptance-review drift: %s — the acceptance.md diff-lock command is gone — the review must run git diff <base>...HEAD -- docs/<slug>/acceptance.md (<base> read from this phase'"'"'s row in docs/<slug>/phase-branches.md) to catch scenario edits (spec FR6 clause (b); a deliberate change to the diff form updates the reviewer prompt and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$fp"
      bad=1
    }
    grep -qF 'feedback-log.md' "$root/$fp" || {
      printf 'acceptance-review drift: %s — the section no longer names the logged approval as the only exception to a non-empty acceptance.md diff — user-approved scenario edits are logged in docs/<slug>/feedback-log.md (spec FR6 clause (b); a deliberate change updates the reviewer prompt and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$fp"
      bad=1
    }
    grep -qiE 'unlogged[^.]*blocking' "$root/$fp" || {
      printf 'acceptance-review drift: %s — an unlogged acceptance.md change is no longer classified blocking — the un-approved scenario edit is exactly what the acceptance lock gates on (spec FR6 clause (b): "an unlogged change is blocking"; a deliberate change updates the reviewer prompt and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$fp"
      bad=1
    }
  fi
  # The human-facing command — surfaces the section in the presented report.
  if [[ ! -f "$root/$rp" ]]; then
    printf 'acceptance-review drift: %s is missing — the report section cannot be surfaced to the human (spec FR6; a deliberate command rename updates the file and this check in scripts/doctor.sh in the same commit, with a reason)\n' "$rp"
    bad=1
  else
    grep -qF 'Acceptance scenario compliance' "$root/$rp" || {
      printf 'acceptance-review drift: %s — the "Acceptance scenario compliance" section is not surfaced in /review-phase — acceptance findings must reach the human presentation, not hide inside the raw report; the section name is matched against the reviewer prompt verbatim, so a deliberate rename updates prompt, command, and this check in scripts/doctor.sh in the same commit, with a reason\n' "$rp"
      bad=1
    }
  fi
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
register_check check_invariant_markers
register_check check_tag_vocabulary_consistency
register_check check_mode_gate_contract
register_check check_acceptance_review_contract

# ---------------------------------------------------------------------------
# Simulation stage (Task 3.4 — spec FR4): pure-git worktree-flow simulation
#
# Exercises the git-plumbing discipline of .opencode/skills/phase-lifecycle/
# SKILL.md part B inside a throwaway `git init` repo under $DOCTOR_SIM_DIR
# (repo at ./repo, decision trace at ./sim-trace.log). Pure git: never
# invokes opencode, never touches the harness repo's own git state — every
# call goes through sim_git/sim_git_at (explicit -C target, hermetic
# config, injected identity), because this function runs with the CALLER's
# cwd, which may itself sit inside the harness repo: relying on cwd here is
# the nested-git footgun the explicit targeting exists to dodge.
#
# Four scenarios, all always run (no fail-fast — the complete list of
# broken scenarios is the diagnosis, mirroring how the Flow runs checks):
#   1  dirty worktree at step-4 verification → cleanup REFUSES, worktree
#      and branch stay put (the porcelain half of the gate).
#   2  commit on the task branch + sequential merge into base → gate
#      passes → `git worktree remove` + `git branch -d` succeed and the
#      merge is landed (the prose flow's happy path; force flags never
#      appear on it).
#   3  the docs-only lead-commit shape (part A's phase-complete commit):
#      a docs/-only commit reads as docs-only AND a mixed docs+code
#      commit is detectably NOT — the invariant hinges on that
#      discrimination, so both sides are asserted.
#   4  committed-but-unmerged work must never be cleaned up (the
#      merge-base half of the gate). This is also the acceptance fixture:
#      under DOCTOR_SIM_SKIP_VERIFY=1 (header, Test seam) the sim MUST
#      fail, and because scenarios 1/2/4 assert via sim-trace.log that the
#      verify step actually OBSERVED their fixtures, a condensation pass
#      that deletes the step fails loudly even where git's own dirty/
#      merged guards would backstop the state.
#
# The two `<!-- invariant: ... -->` markers in SKILL.md part B are the
# prose-side counterpart of this executable guard: check_invariant_markers
# catches the markers vanishing; this simulation catches the behaviour they
# encode regressing. The SKIP_VERIFY seam models the bug (blind forced
# cleanup — exactly what the never-force-remove rule warns about), which
# is why the sim's own verified path never uses force flags.
#
# Scratch lifecycle (fresh per run, kept on ANY failure, cleaned on green)
# stays owned by the Flow section below; this body writes only under
# $DOCTOR_SIM_DIR.
# ---------------------------------------------------------------------------
sim_worktree_flow() {
  local sim_repo="$DOCTOR_SIM_DIR/repo"
  local sim_trace="$DOCTOR_SIM_DIR/sim-trace.log"
  local sim_base=main
  local -a failed=()
  local scenario
  : > "$sim_trace"

  # Every git call of the simulation: explicit -C dir (never cwd — see the
  # section header), the machine's global/system git config ignored via
  # GIT_CONFIG_*=/dev/null (no foreign identity, signing, hooks, template
  # dir or init.defaultBranch can vary the result), stripped git env vars,
  # and one injected fixed identity. The repo is created with an explicit
  # -b for the same determinism reason.
  sim_git_at() {
    local dir="$1"; shift
    env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
      GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null \
      git -C "$dir" \
        -c user.name='doctor-sim' -c user.email='doctor-sim@invalid' \
        -c commit.gpgsign=false "$@"
  }
  sim_git() { sim_git_at "$sim_repo" "$@"; }
  sim_say() { printf 'sim: %s\n' "$*" | tee -a "$sim_trace"; }

  # Named scenario verdict lines — tee'd to $sim_trace so a kept-on-fail
  # scratch dir contains the run's own verdicts. sim_fail annotates
  # failures produced under the dropped-verification seam: the sim is
  # SUPPOSED to fail under DOCTOR_SIM_SKIP_VERIFY — that IS the acceptance
  # fixture, not a doctor.sh bug.
  sim_pass() { sim_say "PASS  $*"; }
  sim_fail() {
    sim_say "FAIL  $*"
    if [[ "${DOCTOR_SIM_SKIP_VERIFY:-0}" == "1" ]]; then
      sim_say "      (DOCTOR_SIM_SKIP_VERIFY=1: this run is the dropped-"
      sim_say "       verification fixture; a failing sim under it is the"
      sim_say "       REQUIRED outcome — the step cannot vanish silently)"
    fi
    return 1
  }
  sim_say "=== pure-git part-B worktree-flow simulation (fixture repo: $sim_repo)"

  # --- the part-B step-4 gate, as code ---------------------------------------
  # Each sub-check records an OBSERVATION line in $sim_trace BEFORE it
  # decides; the scenarios grep those lines back, so deleting a check
  # entirely is as detectable as making it answer wrongly — git's own
  # dirty/merged guards backstop the STATE, and that backstop must not be
  # allowed to let a deleted check pass silently.
  sim_porcelain_clean() {
    local out
    out=$(sim_git_at "$1" status --porcelain) || return 1
    [[ -z "$out" ]]
  }
  sim_branch_landed() {
    sim_git merge-base --is-ancestor "$1" "$sim_base"
  }
  # 0 = both checks passed, cleanup ran; 1 = REFUSED, nothing destroyed
  # (nothing destroyed is the entire point of refusing).
  sim_verify_and_cleanup() {
    local wt="$1" br="$2" state
    if [[ "${DOCTOR_SIM_SKIP_VERIFY:-0}" == "1" ]]; then
      # The modelled condensation bug: a flow without the gate reaches for
      # the very force flags SKILL.md's never-force-remove rule forbids —
      # silently destroying exactly the work the missing check flagged.
      sim_say "verify SKIPPED for $wt ($br): blind forced cleanup (DOCTOR_SIM_SKIP_VERIFY=1)"
      sim_git worktree remove --force "$wt"
      sim_git branch -D "$br"
      return 0
    fi
    if sim_porcelain_clean "$wt"; then state=clean; else state=dirty; fi
    sim_say "verify-porcelain $wt $state"
    [[ "$state" == "clean" ]] || { sim_say "REFUSE cleanup of $wt — uncommitted work present"; return 1; }
    if sim_branch_landed "$br"; then state=landed; else state=missing; fi
    sim_say "verify-landed $br $state"
    [[ "$state" == "landed" ]] || { sim_say "REFUSE cleanup of $wt — $br not merged into $sim_base" ; return 1; }
    sim_git worktree remove "$wt" || return 1
    sim_git branch -d "$br"
  }

  # Scenario 1 — dirty → refuse. The worker "reported done" with a
  # forgotten file and an uncommitted edit; its branch's real work IS
  # committed and merged, so only the porcelain half can refuse this
  # fixture — and the trace assertion proves that half actually looked
  # (git's own dirty-guard on `worktree remove` must not get to cover for
  # a deleted check).
  sim_scenario_1_dirty_refuse() {
    local wt="$DOCTOR_SIM_DIR/wt-dirty" br="task/sim-dirty" rc=0
    if ! sim_git worktree add -b "$br" "$wt" >/dev/null; then
      sim_fail "scenario 1 (dirty → refuse): fixture setup failed"; return 1
    fi
    printf 'worker change\n' > "$wt/worker.txt"
    if ! sim_git_at "$wt" add worker.txt >/dev/null \
       || ! sim_git_at "$wt" commit -q -m 'committed half of the work' >/dev/null \
       || ! sim_git merge --no-edit "$br" >/dev/null; then
      sim_fail "scenario 1 (dirty → refuse): fixture setup failed"; return 1
    fi
    printf 'forgotten scratch\n' > "$wt/scratch-notes.md"
    printf 'uncommitted edit\n' >> "$wt/worker.txt"
    sim_verify_and_cleanup "$wt" "$br" || rc=$?
    if ! grep -qF -- "verify-porcelain $wt dirty" "$sim_trace"; then
      sim_fail "scenario 1 (dirty → refuse): verify never observed the dirty worktree — step-4 check deleted or bypassed"; return 1
    fi
    if (( rc == 0 )); then
      sim_fail "scenario 1 (dirty → refuse): gate CLEANED UP a dirty worktree instead of refusing — silent work loss"; return 1
    fi
    if [[ ! -d "$wt" ]] || ! sim_git rev-parse -q --verify "$br" >/dev/null; then
      sim_fail "scenario 1 (dirty → refuse): refusal destroyed the worktree or branch — refusing must preserve what it refuses to clean"; return 1
    fi
    sim_pass "scenario 1 (dirty → refuse)"
  }

  # Scenario 2 — commit + merge → remove. The happy path end to end:
  # worker commits explicit paths on its task branch, the sequential
  # single-branch merge lands it in base, the gate passes, and cleanup is
  # the sanctioned non-force pair. Post-conditions: gone from disk and
  # refs, work reachable from base.
  sim_scenario_2_commit_merge_remove() {
    local wt="$DOCTOR_SIM_DIR/wt-clean" br="task/sim-clean" rc=0 sha
    if ! sim_git worktree add -b "$br" "$wt" >/dev/null; then
      sim_fail "scenario 2 (commit+merge → remove): fixture setup failed"; return 1
    fi
    printf 'feature work\n' > "$wt/feature.txt"
    if ! sim_git_at "$wt" add feature.txt >/dev/null \
       || ! sim_git_at "$wt" commit -q -m 'task work' >/dev/null; then
      sim_fail "scenario 2 (commit+merge → remove): fixture setup failed"; return 1
    fi
    sha=$(sim_git rev-parse "$br")
    if ! sim_git merge --no-edit "$br" >/dev/null; then
      sim_fail "scenario 2 (commit+merge → remove): sequential merge into $sim_base failed"; return 1
    fi
    sim_verify_and_cleanup "$wt" "$br" || rc=$?
    if ! grep -qF -- "verify-porcelain $wt clean" "$sim_trace" \
       || ! grep -qF -- "verify-landed $br landed" "$sim_trace"; then
      sim_fail "scenario 2 (commit+merge → remove): verify never recorded the clean+landed fixture — step-4 check deleted or bypassed"; return 1
    fi
    if (( rc != 0 )); then
      sim_fail "scenario 2 (commit+merge → remove): gate refused a clean+merged worktree (rc=$rc) — a false refusal strands worktrees and branches"; return 1
    fi
    if [[ -d "$wt" ]] || sim_git rev-parse -q --verify "$br" >/dev/null; then
      sim_fail "scenario 2 (commit+merge → remove): worktree dir or branch survived a passed gate"; return 1
    fi
    if ! sim_git merge-base --is-ancestor "$sha" "$sim_base"; then
      sim_fail "scenario 2 (commit+merge → remove): merged work not reachable from $sim_base after cleanup"; return 1
    fi
    sim_pass "scenario 2 (commit+merge → remove)"
  }

  # Scenario 3 — the docs-only lead-commit shape (part A: the lead commits
  # only docs/<slug>/ in its phase-complete commit). Empty listings (empty
  # or merge commits) count as NOT docs-only — only a non-empty all-docs
  # listing may pass. Positive AND negative controls asserted: the whole
  # invariant hinges on the discrimination.
  sim_commit_is_docs_only() {
    local paths p
    paths=$(sim_git show --name-only --format= "$1") || return 1
    [[ -n "$paths" ]] || return 1
    while IFS= read -r p; do
      [[ "$p" == docs/* ]] || return 1
    done <<<"$paths"
    return 0
  }
  sim_scenario_3_docs_only_lead_commit() {
    mkdir -p "$sim_repo/docs/sim"
    printf 'phase-branch record\n' > "$sim_repo/docs/sim/phase-branches.md"
    if ! sim_git add docs/sim/phase-branches.md >/dev/null \
       || ! sim_git commit -q -m 'docs(sim): phase complete'; then
      sim_fail "scenario 3 (docs-only lead commit): fixture commit failed"; return 1
    fi
    if ! sim_commit_is_docs_only HEAD; then
      sim_fail "scenario 3 (docs-only lead commit): docs-only commit not recognized — discriminator broken"; return 1
    fi
    printf 'note\n' > "$sim_repo/docs/sim/note.md"
    printf 'app()\n' > "$sim_repo/app.js"
    if ! sim_git add docs/sim/note.md app.js >/dev/null \
       || ! sim_git commit -q -m 'mixed: docs plus code'; then
      sim_fail "scenario 3 (docs-only lead commit): negative-control commit failed"; return 1
    fi
    if sim_commit_is_docs_only HEAD; then
      sim_fail "scenario 3 (docs-only lead commit): mixed docs+code commit accepted as docs-only — the invariant hinges on this discrimination"; return 1
    fi
    sim_pass "scenario 3 (docs-only lead commit)"
  }

  # Scenario 4 — committed-but-unmerged work must never be cleaned up:
  # the merge-base half of the gate (the worktree is deliberately
  # porcelain-clean so this fixture isolates that half; scenario 1 owns
  # the dirty half). Under DOCTOR_SIM_SKIP_VERIFY the gate is gone and
  # the blind cleanup force-removes this worktree and force-deletes the
  # only ref to the work — the exact silent work-loss bug part B exists
  # to prevent — so every assertion here goes red and the overall sim
  # fails loudly instead of passing silently. That IS the acceptance
  # fixture.
  sim_scenario_4_unmerged_never_cleaned() {
    local wt="$DOCTOR_SIM_DIR/wt-skip" br="task/sim-skip" rc=0 sha
    if ! sim_git worktree add -b "$br" "$wt" >/dev/null; then
      sim_fail "scenario 4 (unmerged → never cleaned): fixture setup failed"; return 1
    fi
    printf 'unmerged work\n' > "$wt/unmerged.md"
    if ! sim_git_at "$wt" add unmerged.md >/dev/null \
       || ! sim_git_at "$wt" commit -q -m 'work that never lands' >/dev/null; then
      sim_fail "scenario 4 (unmerged → never cleaned): fixture setup failed"; return 1
    fi
    sha=$(sim_git rev-parse "$br")
    if [[ -n "$(sim_git_at "$wt" status --porcelain)" ]]; then
      sim_fail "scenario 4 (unmerged → never cleaned): fixture worktree unexpectedly dirty — it must isolate the merge-base check"; return 1
    fi
    sim_verify_and_cleanup "$wt" "$br" || rc=$?
    if ! grep -qF -- "verify-landed $br missing" "$sim_trace"; then
      sim_fail "scenario 4 (unmerged → never cleaned): verify never recorded $br as unlanded — step-4 check deleted or bypassed"; return 1
    fi
    if (( rc == 0 )); then
      sim_fail "scenario 4 (unmerged → never cleaned): CLEANED UP committed-but-unmerged work — the silent work-loss bug part B exists to prevent"; return 1
    fi
    if [[ ! -d "$wt" ]] || [[ "$(sim_git rev-parse -q --verify "$br" 2>/dev/null)" != "$sha" ]]; then
      sim_fail "scenario 4 (unmerged → never cleaned): worktree or its branch ref lost after refusal — unlanded work destroyed"; return 1
    fi
    sim_pass "scenario 4 (unmerged → never cleaned)"
  }

  # Throwaway fixture repo: deterministic default branch, seed commit.
  # (NOT `if ! A || { B; }` — that list SUCCEEDS when A and B both pass:
  # `!A` is false so the || evaluates B and the list gets B's 0 status,
  # firing the failure branch on the happy path. Each negated term needs
  # its own `!`.)
  if ! sim_git_at "$DOCTOR_SIM_DIR" init -b "$sim_base" "$sim_repo" >/dev/null; then
    sim_fail "fixture repo setup failed: git init"
    return 1
  fi
  printf 'seed\n' > "$sim_repo/README.md"
  if ! sim_git add README.md >/dev/null || ! sim_git commit -q -m 'seed' >/dev/null; then
    sim_fail "fixture repo setup failed: seed commit"
    return 1
  fi

  for scenario in \
    sim_scenario_1_dirty_refuse \
    sim_scenario_2_commit_merge_remove \
    sim_scenario_3_docs_only_lead_commit \
    sim_scenario_4_unmerged_never_cleaned; do
    "$scenario" || failed+=("$scenario")
  done
  if (( ${#failed[@]} )); then
    sim_say "simulation FAILED: ${failed[*]} — fixture tree: $sim_repo, decision trace: $sim_trace"
    return 1
  fi
  sim_say "simulation: all 4 part-B flow scenarios passed"
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
