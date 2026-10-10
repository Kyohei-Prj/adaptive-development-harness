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

**Implication for the hoist (as recorded at the time — see correction
below):** the shared denylist can live once in the shipped config's
top-level `permission.bash`; agents keeping role-delta frontmatter neither
lose the shared denys (union) nor are blocked from their scoped allows
(agent rules merge over and win) — proceed with the hoist. Accepted
consequence to document in README: an agent's frontmatter can out-vote the
shared denylist for its own role, same layer-wins semantics as the config
layers.

> **Correction (post-Task 1.3 stop, effective-action probe below): this
> implication is VOID.** B observed resolved-rule *entry presence* and
> same-pattern precedence via `opencode debug agent` output; it never
> executed a command, so it never measured *effective action*. The B
> fixture's probe agent already contained the disarming shape — its
> `"*": allow` catch-all flattens AFTER the config-layer deny, and by
> last-match-wins out-votes that deny for every command it matches. The
> "accepted consequence" was understated: with all 5 bash agents carrying
> a `"*": allow` catch-all (the shape the hoist would leave), the
> consequence is not "an agent can out-vote the denylist for its own
> scoped allows" but "every shared deny is silently disarmed for every
> agent". B is hereby reclassified FAIL on effective-action grounds.

## Effective-action probe (post-B) — Experiment B reclassified FAIL

**Why:** the Task 1.3 pre-edit probe caught what B could not — B's
assumption was that a config-layer deny surviving into the agent's
resolved rules *protects*; it was only ever verified to be *present*.
That first disproof run lived only in an ephemeral task report, so this
probe reproduces it as durable evidence and extends it to a decisive pair:
the hoist shape must be shown to EXECUTE a denied command (C1), and the
retained per-agent shape shown to BLOCK it (C2).

**Setup (throwaway, `.scratch/gate-c/`, since removed):**
- `git init` inside `.scratch/gate-c/` (same standalone-project-root trick
  as Experiments A/B; `opencode debug scrap` identity behavior reused).
- One shared config `.opencode/opencode.json`, top-level `permission.bash`
  = `{ "*": "allow", "*gate-c-probe-zx9q*": "deny" }` — the sentinel deny
  in anymatch form, mirroring the shipped `"*rm -rf*"`-style patterns; the
  config layer thus holds the would-be hoisted denylist.
- Two primary probe agents against that one config, differing ONLY in
  their frontmatter `permission.bash`:
  - **c1 — the hoist shape:** `{ "*": "allow" }` and nothing else; the
    sentinel is never mentioned (exactly what the hoist would leave in the
    5 bash agents, which keep only their role-delta entries).
  - **c2 — the current per-agent shape:** `{ "*": "allow",
    "*gate-c-probe-zx9q*": "deny" }` (the specific deny lives in the
    agent's own frontmatter, as it does today).
- Sentinel `gate-c-probe-zx9q` globally unique (filesystem grep: 0
  occurrences before fixture creation).

**Commands (OpenCode v1.18.35 — note Experiments A/B ran on v1.18.34,
disproof reproduces on both; cwd `.scratch/gate-c/`; model
`llama.cpp/qwen3.6-27b-mtp`):**
- `opencode debug agent c1` / `opencode debug agent c2` — resolution
  sanity check (entry presence/order).
- `opencode run --agent c1 -m llama.cpp/qwen3.6-27b-mtp "Run exactly this
  bash command once: touch gate-c-probe-zx9q-c1.marker"` — DECISIVE step
  (execution, not entry inspection); same for c2 with
  `gate-c-probe-zx9q-c2.marker`.

**Evidence:**

Resolution sanity check — BOTH shapes resolve with the config deny
present (the point: presence was never the discriminator):

```json
// c1:  [ { "permission": "bash", "pattern": "*",                    "action": "allow" },
//        { "permission": "bash", "pattern": "*gate-c-probe-zx9q*", "action": "deny"  },
//        { "permission": "bash", "pattern": "*",                    "action": "allow" } ]
// c2:  [ { "permission": "bash", "pattern": "*",                    "action": "allow" },
//        { "permission": "bash", "pattern": "*gate-c-probe-zx9q*", "action": "deny"  },
//        { "permission": "bash", "pattern": "*",                    "action": "allow" },
//        { "permission": "bash", "pattern": "*gate-c-probe-zx9q*", "action": "deny"  } ]
```

**C1 (hoist shape) — the command EXECUTES.** `opencode run --agent c1`
transcript (verbatim, ANSI stripped):

```
> c1 · qwen3.6-27b-mtp

$ touch gate-c-probe-zx9q-c1.marker
(no output)

Command run once: `touch gate-c-probe-zx9q-c1.marker`
```

Post-run on-disk corroboration — the marker the denied command creates
exists:

```
-rw-r--r-- 1 kyohei kyohei 0 Oct 10 22:49 gate-c-probe-zx9q-c1.marker
```

No permission error was raised; the config-layer deny matched the command
and was overridden by the agent's later-flattened `"*": allow` catch-all.

**C2 (current per-agent shape) — the command BLOCKS.** `opencode run
--agent c2` transcript (verbatim, ANSI stripped; the rule dump embedded
in the error is OpenCode's own output):

```
✗ touch gate-c-probe-zx9q-c2.marker failed
Error: The user has specified a rule which prevents you from using this specific tool call. Here are some of the relevant rules [{"permission":"*","action":"allow","pattern":"*"},{"permission":"bash","pattern":"*","action":"allow"},{"permission":"bash","pattern":"*gate-c-probe-zx9q*","action":"deny"},{"permission":"bash","pattern":"*","action":"allow"},{"permission":"bash","pattern":"*gate-c-probe-zx9q*","action":"deny"}]
```

Post-run corroboration — no marker was created:

```
ls: cannot access 'gate-c-probe-zx9q-c2.marker': No such file or directory
```

The only difference from C1 is that c2's frontmatter carries the specific
deny itself, so the LAST matching rule for the sentinel command is a deny.

**Result: C1 executes, C2 blocks.** The permission decision is made in
OpenCode's tool-call layer, not by model choice, so one run per shape is
deterministic evidence. Together the pair proves both halves of the
conclusion: the hoist disarms the config-layer deny whenever an agent
keeps a `"*": allow` catch-all, and the current per-agent lists genuinely
protect because the specific deny lives after the catch-all.

**Reclassification:** Experiment B = **FAIL** on effective-action grounds
(its recorded B1/B2 observations were accurate for what they measured —
entry presence and same-pattern precedence — but those are not the hoist's
needed precondition). The hoist's real precondition is: config-layer deny
remains *effective* under an agent catch-all. It is not.

**Consequence:** Task 1.3 (the hoist) STOPPED before editing any file —
the plan's pre-sanctioned fallback branch is taken, not a failure.

## Decision — FR8 fallback taken

Made by the lead with human authorization after the stop; the plan
explicitly pre-sanctioned this branch (spec Constraints: "that is a
planned branch, not a failure"; Task 1.4's own fallback wording).

- **Per-agent denylists retained as-is.** All 5 bash agents keep their own
  destructive-command deny patterns; the shipped config's top-level
  `permission.bash` does NOT receive the shared denylist.
- **`scripts/doctor.sh` (Phase 3) gains a denylist-drift check** between
  the per-agent copies instead of the hoist-presence expectation in
  check 1 (FR8 fallback wording).
- **Alternative hoist shape deferred:** config layer = `"*": "allow"`
  BEFORE the 17 deny entries, with all agent frontmatter catch-alls
  dropped (role-delta entries would then be allow-only). Considered and
  NOT taken in this slug: it needs its own effective-action-gated
  experiment plus a plan amendment. Documented as a future option.
- **Upstream behavior question open:** is cross-layer last-match-wins
  (an agent's `"*": allow` out-voting a config-layer deny) intended
  OpenCode behavior or a bug? The docs phrase "agent rules take
  precedence" is consistent with it; either way, the harness must code
  against observed behavior, not doc phrasing — which is why the
  effective-action probe, not the doc quote, is the gate.
