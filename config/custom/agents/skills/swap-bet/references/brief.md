# brief

Research the bet just enough to fill what the input leaves open, and come out with a
**one-pager** plus a **PO sync agenda**: the decisions product must make, each with options
and a recommendation.

Reads `intake.md`. Writes `brief.md` from [templates/brief.md](../templates/brief.md).

## Preflight

Decide the sources first (step 1), then probe only those (and Slack always for a small bet).

| Tool | Probe (read-only) |
|---|---|
| Logfire MCP | `logfire-swap_project_list` (read `logfire-swap_query_schema_reference` before the first real query) |
| BigQuery | `bq ls -n 1` |
| Firestore | `gcloud firestore databases list --project=swap-cloud` (env choice: shopmr `connecting-to-swap-db`; `swap-cloud` = PROD, `swap-cloud-uat` = UAT/DEV) |
| Slack MCP | `mcp({ connect: "slack" })`, read one message of the bet channel |
| Notion MCP | `notion_notion-fetch` on the epic |

Repos need no probe: `recon` reads them through repowise.

## Steps

1. **Size the research to the gap.** From `intake.md` richness:
   - `one-liner` → full research: what exists today, how often the need shows up, where the
     change lands, how to measure it.
   - `partial` → only the empty template sections.
   - `PRD` → a gap report (what the PRD leaves open or gets wrong) + Technical Approach +
     Open Questions. Leave the product sections to the PRD.
2. **Fan out, one subagent per source**, each writing a short findings file in the spec dir
   (`.findings-<source>.md`) and returning a paragraph:
   - `recon` per repo touched (any `~/dev/swapc` repo; usually `shopmr` `apps/agents` and
     `apps/storefront-widget`): where the change lands, existing patterns, flags, tests.
     Repowise first.
   - `researcher` for every live source: Logfire MCP (traces, latency, cost; shopmr
     `replaying-logfire-conversations`, `bug-debug` know the span shapes), Slack threads,
     the Notion PRD, BigQuery (CS analytics: resolution rate per topic per merchant),
     Firestore conversations and brand settings, and anything external (`cock-research`).
     `recon` stays on repos.
   Give each the bet's question, the source, and the `<KEY>` dir; they cannot see this chat.
3. **Think about measurement** — every brief has the Metrics & evals section, nothing waits
   on it. Name the signal (default: resolution rate for the target topic, before vs after),
   its source and whether it is instrumented today. When agent quality is touched, propose
   evals first (`tools/agents-testing` Perseus, AAO nudge evals). Prefer an instrumentation
   slice early when the baseline is missing. Lightdash `cs-agent-performance` and the chat
   viewer are links for humans.
4. **Write `brief.md`** — one page. Every claim links its evidence (file:line, trace,
   query, thread). The PO sync agenda is a `cock-grilling` round: numbered decisions, each
   with options and a recommendation.
   - **Read the ask literally**: "make entries clickable" means all entries. A rec that cuts
     scope sits next to the full-scope option (backend + UI), sized too.
   - **Size in points**, never time: Fibonacci 1, 2, 3, 5, 8, 13 per slice, the team's
     Linear estimate scale. `tickets` copies them into the Linear estimate.
5. Delete the `.findings-*` files once folded in.
6. **Small bet**, when `publish` will be skipped: create the PO's Slack draft now, as in `publish.md`
   step 4.

Done when every template section is filled or marked `n/a — <why>`, and every agenda item has
options and a recommendation. Commit; next: `swap-bet publish <KEY>`; small bet: hold the PO sync, then
`swap-bet sync <KEY>`.
