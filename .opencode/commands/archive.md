---
description: Move a merged slug's planning docs out of the live docs/ tree and into docs/_archive/, to prevent stale docs misleading a future /grill or /plan session
agent: lead
---
Archive the planning docs for `$1`. Only do this after `$1`'s feature
branch(es) have actually been merged to main — confirm with me first if
you're not sure that's already happened.

Steps:
1. Confirm with me that `$1` has been merged to main, if it isn't obvious from `git log main` containing the slug's phase commits.
2. `mkdir -p docs/_archive` if it doesn't exist.
3. `git mv docs/$1 docs/_archive/$1`.
4. Commit: `git add -A && git commit -m "chore($1): archive planning docs after merge"`.
5. Confirm to me that it's done, and note that `docs/_archive/$1/` remains available for reference (git history and grep both still find it) — it's just out of the live tree so a future `/grill` or `/plan` session for unrelated work won't stumble on it and treat it as current.

Do not delete the docs outright — archive, don't destroy. If I explicitly ask you to delete instead of archive, confirm that's really what I want before doing it.
