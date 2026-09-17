# Ticket stages write local artifacts, gated by plannotator, published only on agreement

A ticket runs through stages (`intent`, `research`, `spec`, `plan`); each stage ends by writing one
artifact into `~/dev/swapc/specs/<KEY>/` — its own git repo beside the work repos, committed per
stage, never pushed. Gates after `spec` and after `plan` go through `plannotator_submit_plan`;
because plannotator only accepts files inside the cwd, the artifact is copied to
`docs/.scratch/<KEY>-<stage>.md` for submission and accepted edits are applied back to the spec
dir, which stays the source of truth. Publishing to Linear or Notion is a separate explicit step
through the `comms` role, after sign-off, from a sanitised `<KEY>-public.md`. Candid notes never
leave the spec dir. Owned by the `punk-sdlc` skill and the `planner` role.

Local-first because the artifact is a working draft: cheap to rewrite, diffable, and an audit trail
of how the spec evolved, with no half-formed opinion visible to the team. Publishing on agreement
keeps the team's surfaces free of drafts and makes the gate meaningful — the sign-off, not the
write, is what makes an artifact public.

**Concrete-first for Swap**, not generic: the skill speaks Swap's terminology and Swap's ticket
rules. Tenancy is by **team key** inside the single `swap-commerce` workspace — Agentic subteams
(AGIA…AGID) follow the `swap-linear` rules, team `KUB` follows the `linear-conventions` steering
rule. A generic pipeline extracts later if private use demands it; the work that pays for this
today is at Swap.

Rejected: **Notion-first artifacts** (product's annotation surface, but every draft edit becomes a
team-visible revision and Notion is not diffable); **Linear documents as source of truth** (ties
drafting to the tracker, no local history, and mixes drafts with what the squad reads);
**a generic skill first** (two abstractions to maintain before either had been dogfooded once).

Consequences: the spec dir must exist on the runtime host (the mac) at the same path, and is
unbacked-up by design. Sign-off is manual in this increment — a Linear/Notion comment poller is a
sketch, not a commitment.
