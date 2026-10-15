# close

> Next — not yet piloted. Usable; note rough edges in `~/dev/swapc/specs/_skill-feedback.md`.

Read what the bet did to its metric and call it: **kill**, **iterate**, or **scale**, with
the learning.

Reads `spec.md` (metrics plan), `brief.md`, `tickets.md`. Writes `outcome.md`, then
`outcome-public.md` for Slack and Notion.

## Preflight

Rows for the sources the metrics plan names, plus the posting targets.

| Tool | Probe (read-only) |
|---|---|
| BigQuery | `bq ls -n 1` |
| Logfire MCP | `logfire-swap_project_list` |
| LaunchDarkly | `ldcli projects list --json` — only when the bet ran an LD experiment. Missing: `eget launchdarkly/ldcli --to ~/.local/bin` |
| Slack MCP | `mcp({ connect: "slack" })`, read one message of the bet channel |
| Notion MCP | `notion_notion-fetch` on the epic |

## Steps

1. **Pull the numbers** the metrics plan promised, before vs after release, each with its
   query or link: BigQuery (resolution rate per topic per merchant), Logfire (latency, cost,
   errors), eval runs, LaunchDarkly experiment results (`run-launchdarkly-experiment`; it
   never creates metrics — a missing metric becomes a metric-add ticket, not a workaround).
   Delegate the queries to `researcher` / `recon`; keep the numbers, not the raw output.
2. **Draft `outcome.md`**: verdict (kill / iterate / scale) and why, the numbers against the
   target, what we learned about the problem, skipped defaults (default — reason), and what we learned about how we worked
   (`cock-retro` categories; skill lessons go to `~/dev/swapc/specs/_skill-feedback.md`).
3. **Owner confirms.** Sanitise to `outcome-public.md`, review through Plannotator (SKILL.md
   Gates), record the OK line.
4. **Post** the public outcome to the bet's Slack channel and the Notion epic.

Done when the owner-confirmed outcome is posted in both places and linked from `outcome.md`.
Commit the spec dir.
