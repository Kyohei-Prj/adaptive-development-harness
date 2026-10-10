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
