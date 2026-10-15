# publish

Put the one-pager where the team reads it and hand the PO the sync agenda.

Reads `brief.md`. Writes `brief-public.md`, then Linear, Slack and Notion.

## Preflight

| Tool | Probe (read-only) |
|---|---|
| Plannotator | `plannotator_inbox` tool listed, or `plannotator inbox --help` exits 0 (default route only) |
| Linear MCP | `linear_get_project` on the bet's project |
| Slack MCP | `mcp({ connect: "slack" })`, read one message of the bet channel |
| Notion MCP | `notion_notion-fetch` on the epic (skip when there is none) |

## Steps

1. **Sanitise** `brief.md` into `brief-public.md`: drop candid notes, internal names,
   half-formed opinions — anything the owner would not say in the channel. The candid
   `brief.md` never leaves the spec dir.
2. **Route.** Default: owner review of `brief-public.md` through Plannotator (see SKILL.md
   Gates); apply their edits to both files and record the OK line. `--direct`: skip the
   review; the owner still sends the Slack draft (step 4).
3. **Linear project description** = the canonical home. Write `brief-public.md` into it with
   `linear_save_project`, keeping existing links (Notion epic) on top. Re-publishing replaces
   the earlier one-pager, nothing else.
4. **Slack draft to the PO** (small bets reach this from `brief`): a short, plain message in
   product language: what we want to do, the decisions we need as a numbered
   list, the Linear link, the PO tagged. Create it as a draft in the bet's existing
   thread (`intake.md`; none → ask the owner which channel) with
   `slack_slack_send_message_draft` (`channel_id`, `message`, `thread_ts`); the owner sends
   it. `attached_draft_exists` (one attached draft per channel) → tell the owner and paste the
   message in chat.
5. **Notion epic**: add the Linear project link. Only when Problem, Goal and Success Metrics
   are empty, fill each with one line from the brief. Leave everything else in the epic to
   product.

Done when the Linear project shows the one-pager, the PO's Slack draft is in the thread (or
pasted in chat), and the Notion epic links Linear. Record the three links in `brief.md`. Commit; next: hold
the PO sync, then `swap-bet sync <KEY>` with the notes.
