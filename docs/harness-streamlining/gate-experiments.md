# Gate Experiments — harness-streamlining

Throwaway probes (run in `.scratch/`, nothing under it committed) that verify
the config-merge assumptions of the denylist hoist against the installed
OpenCode version before the hoist is applied. Verdicts and evidence recorded
here so the Phase 1 review can log them in `feedback-log.md`.

## Experiment A

**Goal:** prove that a third-party project placing the shipped
`.opencode/opencode.json` at `<their-project>/.opencode/opencode.json`
actually gets it loaded as a merged config layer — the precondition for
hoisting the shared destructive-command denylist into the shipped config's
top-level `permission.bash`.

**Setup (throwaway, `.scratch/gate-a/`, since removed):**
- `git init` inside `.scratch/gate-a/` first, so the fake project is its own
  git root (rules out the false-FAIL artifact of opencode walking up to the
  enclosing harness repo root and never seeing the fake project's dir).
- Copied this repo's `.opencode/opencode.json` verbatim to
  `.scratch/gate-a/.opencode/opencode.json`, adding ONE sentinel entry to
  `watcher.ignore`: `"sentinel-gate-a-8f3d/**"`. Globally unique — the
  author's global `~/.config/opencode/` config also merges, so only this
  string can identify the fake project's layer (verified: filesystem grep
  found the sentinel in exactly one file,
  `.scratch/gate-a/.opencode/opencode.json`).

**Commands (OpenCode v1.18.34, cwd `.scratch/gate-a/`):**
- `opencode debug config`
- `opencode debug scrap` (project-identity corroboration)
- control: `opencode debug config` from the harness repo root

**Evidence:**

Resolved `watcher` block from `opencode debug config` inside the fake
project — sentinel present:

```json
"watcher": {
    "ignore": [
      "node_modules/**",
      "dist/**",
      "build/**",
      ".git/**",
      "**/*.min.js",
      "**/*.map",
      "**/*.lock",
      ".venv/**",
      ".opencode/**",
      ".worktrees/**",
      ".scratch/**",
      "sentinel-gate-a-8f3d/**"
    ]
```

Project identity — `opencode debug scrap` treats the fake dir as its own
project (`"vcs": "git"` proves `git init` was picked up, not a walk-up):

```json
    "id": "global",
    "worktree": "/home/kyohei/Projects/adaptive-development-harness/.scratch/gate-a",
    "vcs": "git",
```

Control — `opencode debug config` from the harness repo root contains 0
occurrences of `sentinel-gate-a-8f3d` (`grep -c` → `0`), confirming the
sentinel in the first excerpt came from the fake project's `.opencode/`
layer only.

**Verdict: PASS.**

**Implication for the hoist:** the shipped `.opencode/opencode.json` is
loaded as a real config layer in a standalone third-party project, so
hoisting the shared denylist into its top-level `permission.bash` is
viable — proceed with the hoist (Experiment B's verdict still gates it
independently).

## Experiment B

**Goal:** prove that an agent's frontmatter `permission.bash` MERGES OVER
the config top-level `permission.bash` (union) with agent rules winning on
same-pattern conflict — the precondition for putting the shared denylist
once at config top level while agents keep role-delta frontmatter. A naive
same-pattern conflict test alone can pass under replace-semantics too
(replace also "wins"), so two sub-checks:

- **B1 (precedence):** top-level denies a harmless sentinel pattern, the
  agent's frontmatter ALLOWS the same pattern → resolved shows agent's
  allow winning.
- **B2 (merge/union):** top-level also denies a DIFFERENT pattern the
  agent's frontmatter never mentions, and the agent still has its own
  non-empty `permission.bash` block → resolved rules for that agent STILL
  contain the top-only deny. This is what distinguishes merge from replace.

**Setup (throwaway, `.scratch/gate-b/`, since removed):**
- `git init` inside `.scratch/gate-b/` (same standalone-project-root trick
  as Experiment A).
- `.scratch/gate-b/.opencode/opencode.json` with top-level `permission.bash`
  = `{ "*": "allow", "gate-b-sentinel-7c2a*": "deny",
  "gate-b-toponly-9k4e*": "deny" }`. (Adapted from the task's suggested
  project-root `opencode.json` to the `.opencode/` layer, because that is
  the exact hoist target per architecture.md; Experiment A already proved
  this layer loads.)
- `.scratch/gate-b/.opencode/agents/probe.md` (mode: primary) with
  frontmatter `permission.bash` = `{ "*": allow,
  "gate-b-sentinel-7c2a*": allow }` — non-empty block, mentions the
  sentinel, never mentions the top-only pattern.
- Both sentinel strings globally unique (filesystem grep: present only in
  the two fixture files; author's global config: 0 occurrences).

**Commands (OpenCode v1.18.34, cwd `.scratch/gate-b/`):**
- `opencode debug agent probe` (primary observation — resolved, flattened
  permission rules for the probe agent)
- `opencode debug config` (corroboration: denys really come from the
  config layer, not absent from it)
- control: `opencode debug agent lead` from the harness repo root (output
  shape reference for a flattened agent resolution)

**Evidence:**

`opencode debug agent probe` — bash rules of the resolved agent, verbatim
(config-layer entries first, agent frontmatter appended after):

```json
[
  { "permission": "bash", "pattern": "*",                    "action": "allow" },
  { "permission": "bash", "pattern": "gate-b-sentinel-7c2a*", "action": "deny"  },
  { "permission": "bash", "pattern": "gate-b-toponly-9k4e*",  "action": "deny"  },
  { "permission": "bash", "pattern": "*",                    "action": "allow" },
  { "permission": "bash", "pattern": "gate-b-sentinel-7c2a*", "action": "allow" }
]
```

- B1: the conflict is preserved as two entries, with the agent's
  `"gate-b-sentinel-7c2a*": allow` resolving AFTER the config's deny; the
  official permissions docs state "Rules are evaluated by pattern match,
  with the last matching rule winning" and "Agent permissions are merged
  with the global config, and agent rules take precedence" — so the
  effective action for the sentinel command is **allow, agent wins**.
- B2: `"gate-b-toponly-9k4e*": deny` is still in probe's resolved rules
  although probe's frontmatter never mentions it and has its own non-empty
  `permission.bash` block. Under replace-semantics the resolution would
  contain only the agent's 2 entries; it contains all 5 — union merge.

`opencode debug config` inside the fake project — resolved top-level
`permission` block (proves both denys were present in the config layer,
ruling out "the deny was never there" as an alternative B2 explanation):

```json
"bash": {
    "*": "allow",
    "gate-b-sentinel-7c2a*": "deny",
    "gate-b-toponly-9k4e*": "deny"
}
```

**Verdict — B1 (precedence): PASS. B2 (merge/union): PASS. Overall: PASS.**

**Implication for the hoist:** the shared denylist can live once in the
shipped config's top-level `permission.bash`; agents keeping role-delta
frontmatter neither lose the shared denys (union) nor are blocked from
their scoped allows (agent rules merge over and win) — proceed with the
hoist. Accepted consequence to document in README: an agent's frontmatter
can out-vote the shared denylist for its own role, same layer-wins
semantics as the config layers.
