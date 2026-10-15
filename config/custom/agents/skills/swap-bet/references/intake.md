# intake

Pull the ask from wherever it arrived, fix `<KEY>`, and say how much of it is already decided.

## Preflight

Rows for the entry points this bet actually names; Linear and Slack always.

| Tool | Probe (read-only) |
|---|---|
| Linear MCP | `linear_list_teams` lists AGIT; `linear_get_project` on the bet's project if known |
| Notion MCP | `notion_notion-fetch` on the epic URL / PDE page |
| Slack MCP | `mcp({ connect: "slack" })`, then `slack_slack_search_public` for `<KEY>` (step 1's search, one call for both) |

The ds-proto chat viewer is a link for humans: record it, no probe.

## Steps

1. Gather every entry point given: Notion epic (PDE key or URL), Linear project or issue,
   Slack thread or channel, chat-viewer link, or a raw sentence. Follow the obvious links one
   hop (epic → Linear project and Slack channel; project → Notion epic resource). Leave a
   missing link missing.
   **Always search Slack** for the ticket id and topic, small bets included: the PO and
   context can live only in a thread.
   Record the PO and the bet's existing thread (permalink, channel id, `thread_ts`).
2. Choose `<KEY>`: the starter ticket of the AGIT project if one exists, else the project
   slug. Offer the choice to the owner only when both exist and it is unclear which the bet
   should live under. Create `~/dev/swapc/specs/<KEY>/`. A slug `<KEY>` stays the key when a
   starter ticket appears later: record the ticket in `intake.md`, keep the dir name.
3. Rate **richness** — how much of the epic template (Problem, Goals, Success Metrics, Scope,
   UX, Commercial Value, Technical Approach, Dependencies & Risks, Open Questions) the input
   already answers: `one-liner`, `partial`, or `PRD`. `brief` sizes its research from this.
4. Write `intake.md` from [templates/intake.md](../templates/intake.md); quote the ask
   verbatim, link every source. Unknowns the owner can settle in a sentence: ask them now as
   one numbered round with a recommended answer each (`cock-grilling` style). Everything else
   goes to `brief`.

Done when `intake.md` names `<KEY>`, every source link, the richness, and the open unknowns.
Commit; next: `swap-bet brief <KEY>`.
