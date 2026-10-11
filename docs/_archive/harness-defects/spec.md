# Specification — harness-defects

## Goal
Seven verified harness defects in git-safety, permissions, and control flow
are fixed and verified, with the shipped state of the repo (config,
gitignore, docs) self-consistent with the fixed behavior.

## In scope
- The commit-authorship invariant: task-implementer / issue-resolver commit
  their own work (explicit file lists, never `-A`); lead's phase-complete /
  review / finalize commits shrink to `git add docs/<slug>/`; phase-complete
  records checkbox flips; lead's bookkeeping-only edit exception stated.
- Worktree flow hardening: commit-before-report; clean (`status
  --porcelain`) + landed (`merge-base --is-ancestor`) verification before
  `git worktree remove`; failure → stop and report, never `--force`;
  summary format unchanged.
- Interactive `/implement-phase` FAIL semantics mirroring `-auto`; skipped
  tasks carried as deferred issues into review's feedback-log.
- Denylist holes: plain `git push*` deny in lead; `branch -D` (prefix +
  anymatch) in task-implementer and issue-resolver.
- grill task whitelist `{"*": deny, "explore": allow, "scout": allow}` (+
  body note, + README agents-table row).
- `.gitignore` ships `.worktrees/`, `.scratch/`, `**/autorun.log`; archive.md
  leave-behind note; README copy-instructions `.gitignore` line.
- phase-reviewer `<fill in …>` placeholder deleted (defaults preserved).
- Shipped `.opencode/opencode.json` reduced to `$schema` + `watcher.ignore`.
- Second-pass fixes: lead.md stale pointer → phase-lifecycle skill; README
  Troubleshooting `git add -A` recovery rewritten to the invariant.
- End-of-slug docs follow-through: README + AGENTS.md updated to shipped
  reality (content updates only — the AGENTS.md *diet* is slug 2).

## Out of scope
- Denylist hoist / config dedup / agent-file slimming (slug 2).
- `scripts/doctor.sh` and its simulation-as-a-test-suite (slug 2; slug 1's
  simulation is a one-off verification, not a shipped tool).
- AGENTS.md ≤80-line diet, prose pass over agent bodies, sandbox why-essay
  relocation (slug 2).
- CI of any kind; any modification of `~/.config` (author relocates personal
  config manually — the harness's own sandbox rule applies to its authors).

## Functional requirements
1. FR1: No agent procedure anywhere instructs or permits `git add -A`;
   lead's only commit command shape is `git add docs/<slug>/`.
2. FR2: Part B of phase-lifecycle instructs the isolated worker to commit on
   its task branch before reporting done.
3. FR3: lead verifies worktree clean + task-branch landed before removal;
   `--force` is prohibited on the failure path.
4. FR4: `/implement-phase` (interactive) on task FAIL: stops delegating,
   commits nothing, surfaces root cause, asks the user for direction —
   semantically identical to `-auto` except the stop→ask step.
5. FR5: Tasks skipped after a FAIL are recorded as deferred issues and
   resurface via review's feedback-log.
6. FR6: lead's resolved bash denylist includes plain `git push*`;
   task-implementer's and issue-resolver's include `git branch -D*` as both
   prefix and anymatch patterns.
7. FR7: grill's task permission is exactly the explore/scout whitelist (a
   missing `scout` built-in in a given OpenCode version is a harmless no-op);
   grill.md body and README row agree.
8. FR8: `git check-ignore` confirms `.worktrees/`, `.scratch/`, and
   `docs/<any>/autorun.log` (post-archive path too) are ignored.
9. FR9: No `<fill in` string exists anywhere under `.opencode/`.
10. FR10: Shipped `.opencode/opencode.json` contains exactly `$schema` +
    `watcher.ignore` entries.
11. FR11: lead.md's worktree-mechanics pointer targets the phase-lifecycle
    skill, not command files; README Troubleshooting recovery matches the
    new invariant.

## Non-functional requirements
- Performance/context: permission changes live in YAML frontmatter (config,
  not prompt) → zero added per-spawn context; body-prose additions kept to
  the minimum the fixes require.
- Reliability: the fixes must not change `-auto` or `autorun.sh` behavior
  beyond gaining the missing git-verification and FAIL-parity semantics.
- Compatibility: worktree flow must still behave identically in the
  non-parallel (no-worktree) path.

## Acceptance criteria
- [x] All seven defects demonstrably fixed (map each to FRs 1–10 in the
      final review report).
- [x] `grep -rn "git add -A" .opencode/` → no hits; `grep -rn "<fill in"
      .opencode/` → no hits.
- [x] Frontmatter audit: push/branch -D denies and grill whitelist present
      with prefix+anymatch pairing where specified.
- [x] `git check-ignore -v` succeeds for the three `.gitignore` entries,
      including `docs/_archive/<slug>/autorun.log`.
- [x] Shipped config diff shows only `$schema` + `watcher.ignore` remain.
- [x] Pure-git simulation (Task 1.4) passes: dirty worktree → removal
      refuses; committed+merged → removal succeeds; lead-equivalent commit
      adds only `docs/<slug>/`.
- [x] Dogfooding: each phase passes `/review-phase`; `/finalize` clean.
- [x] README + AGENTS.md describe shipped reality (FR11 included).

## Constraints / assumptions
- Slug 1 dogfoods itself: phase N runs under a partially-updated harness;
  each phase must remain runnable after the previous phase's edits.
- No `[parallel-with]` tags anywhere in this slug (self-referential;
  isolated worktrees add risk without benefit here).
- Author's personal OpenCode config relocation is a manual step outside the
  agent sandbox; tasks may document it, never perform it.
- Facts verified during grill (don't re-derive): OpenCode config files merge
  (global → project root → .opencode layer wins); frontmatter is config not
  prompt; explore/scout are the read-only built-ins.
