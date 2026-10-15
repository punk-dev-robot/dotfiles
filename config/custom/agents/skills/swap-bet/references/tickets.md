# tickets

Slice the signed spec into AGIT tickets a coding agent can pick up cold. You act as the bet's
manager: slice, create, wire the edges, then show the owner — no confirmation per ticket.

Reads `spec.md`. Writes Linear tickets + `tickets.md` from [templates/tickets.md](../templates/tickets.md).

**Hard rule:** `spec.md` not signed off (SKILL.md hard rule 1) → stop and say so.

## Preflight

| Tool | Probe (read-only) |
|---|---|
| Linear MCP | `linear_get_project` on the bet's project (small bet: `linear_get_issue` on `<KEY>`); `linear_list_issue_labels` finds the Storefront label |
| Plannotator | `plannotator_inbox` tool listed, or `plannotator inbox --help` exits 0 |

## Steps

1. **Slice** with `cock-to-tickets` rules (tracer-bullet vertical slices, blocking edges,
   prefactor first, expand–contract for wide refactors), plus:
   - **One ticket = one vertical slice of user value.** It may span repos and layers; its PRs
     get stacked by layer at `build`.
   - **Ticket 1 = the walking skeleton** from `spec.md`: thinnest end-to-end path behind a
     flag, verified, instrumented where cheap — it gives the "before".
   - Size each slice so every PR layer can land at a risk score ≤ 15 (see `build.md`) and the
     whole ticket fits one fresh agent context.
   - Every acceptance criterion in `spec.md` lands in some ticket's Verification.
   - A slice behind an `OPEN` spec decision gets a text line `Blocked by: D<n> (OPEN)` under
     its Verification and no native relation for it; it waits, the rest go ahead.
2. **Write each body** from [templates/ticket.md](../templates/ticket.md). Verification is
   always present and written so `verify-window-shop` can run it unaided. Agent-behaviour
   slices add a Perseus scenario (shopmr `writing-ai-testing-scenarios`) to Verification.
   Mark every code fact the ticket relies on `verified file:line` or `assumed`: recon
   summaries copied unchecked were wrong in the pilot.
3. **Create** in dependency order (blockers first) with `linear_save_issue`. Fixed fields on
   every ticket: team AGIT, the bet's project, assignee (owner unless the spec says
   otherwise), the Storefront label, the slice's points as the estimate. Then set native blocked-by relations.
4. **Post-hoc review**: send the owner the list (title · id · blocked by · one-line slice)
   through Plannotator inbox, or in chat when present. Record their feedback in `tickets.md`
   under `## Review feedback`.

**Small bet** (spec is one slice and `<KEY>` is an existing ticket): rewrite that ticket's
body from the template instead of creating one; keep its project, if any. More than one
slice → create the rest with the existing ticket as slice 1.

Done when every slice exists in Linear with fields and edges set, and `tickets.md` maps them.
Commit; next: `swap-bet build <KEY>` (frontier = tickets with no open Linear blockers
and no `OPEN` spec decision).
