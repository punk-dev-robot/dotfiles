---
name: swap-linear
description: Team rules for Linear tickets on Swap's Agentic subteams (AGIA/AGIC/AGIK/AGIF/AGIP/AGIT/AGIX/AGID) — squad, Project, assignee, estimate, labels, cycle, relations — enforced before any create/update via the linear_* MCP tools. Also a read-only Triage mode over tickets assigned to me. Use when creating, updating, filing, splitting, or triaging a Linear ticket for Swap/Agentic Storefront.
argument-hint: "create <title> | update <KEY> | triage"
---
# swap-linear

**Persona:** I am Kuba Gaj. Write titles, descriptions, comments in first person as me.
Never refer to me in the third person.

**Source of truth:** Notion runbook "Creating Linear tickets and epics"
(`3bae3fb2dc2b80f89f23f4463a49ab13`) — re-fetch with `notion-fetch` when a rule feels off.
IDs pinned in [reference.md](reference.md); refresh instructions in its header.

**Tools:** `linear_*` on the direct `linear` server only (via `mcp`/`mcpScript`). One workspace
(`swap-commerce`); team rules chosen by team key. `KUB` tickets are NOT this skill — use the
steering rules in `linear-conventions`.

## Hard rules

- NEVER create on parent team `AGI`. Always a subteam.
- Every issue: existing **Project** (never invent; unknown → list Project candidates for the team
  and ask), **subteam**, **assignee** (person), **estimate**, required **labels**.
- Bug / KTLO / one-off → the KTLO Project, never a new epic.
- Epics are Linear **Projects** under a Q3 initiative. No `[EPIC]` parent issues. Ordering via
  `blocks` / `blockedBy`, not parent/child.
- Deprecated, do not use: squad labels (`agents-squad`…), `UAT`/`PROD` as labels.
- Mutations only through the confirm flow below. Never batch-create without showing every payload.

## Defaults (mine)

- Assignee: **me** (`d1db2cbb-cc29-4101-a793-8fa029e3e945`) for tickets I create, unless the
  work clearly belongs to someone else — then the squad lead from reference.md; confirm.
- Cycle: current cycle of the team, unless told "backlog" / "next". Resolve the cycle **UUID** first (`linear_list_cycles { teamId, type: "current" }`) and pass it as `cycle`; names/numbers are rejected. After a batch create, re-apply `cycle` via update on each identifier — create has been observed to drop it — and ask Kuba to spot-check one in the UI (`get_issue` does not echo cycle).
- State: `Triage` (create). Move only when asked.
- Priority: leave unset unless the request says urgent/high.

## Labels

- Always `platform: Storefront`.
- Bug → `Bug` + `Bug Source: PROD` **or** `Bug Source: UAT`. PROD → also a brand
  (`eleven-loves`, `manors`, … or `all-brands`).
- Will reach Done with no PR (investigation, query, ops) → `Query`.
- Bug against work already in `DEV`/`UAT`/`Done` → **new** ticket, `relatedTo` original, `re-test`.
  Never reopen the original.
- Label names in payloads: `platform: Storefront` is the grouped display name; the raw label is
  `Storefront`, per-team id (see reference.md). Brand labels (`eleven-loves`, `manors`) and
  `re-test` did **not** exist at pin time — if the runbook asks for one, say so and ask before
  creating it (`linear_save_issue_label`); never silently drop it.
- Wayfinder type labels on Agentic subteams are `research` / `spike` / `decision` / `task`
  (not `wayfinder:*`, that's `KUB`); create once per team on first use (confirm first) — see
  `swap-project`.
- No estimate possible → omit estimate; `pending-estimation` is auto-applied. When estimating
  later, remove `pending-estimation` yourself (`removeLabels`).

## Estimates

| pts | ≈ | use |
|---|---|---|
| 1 | 1h | bugs, small non-feature only |
| 3 | ½ day | minimum for a feature |
| 5 | 1 day | default feature slice |
| 8 | 2 days | max — bigger → split (propose the split) |

Once set, no take-backs; only splitting changes it. **The estimate is Kuba's call, not mine**: propose one with a one-line reason in the payload table, but never create with an estimate he hasn't seen and confirmed.

## Statuses (Agentic subteams)

`Triage` → `Backlog - General` (lead accepted) → `Todo` (in cycle) → `In Progress` →
`In Review` (PR) → `DEV` (merged develop) → `UAT` → `Done` (main). Manual: `QA`, `On Hold`,
`Canceled`, `Duplicate`. Say "`Triage` status" to distinguish from Triage mode below.

## Create / update flow

1. Resolve **team** from request (squad table in reference.md). Ambiguous → ask.
2. Resolve **Project**: if named, look up id; else `linear_list_projects` for the team, show
   candidates (+ KTLO), ask. Never guess.
3. Resolve assignee, estimate, cycle, labels, relations (`blocks`/`blockedBy`/`relatedTo`), links.
4. Render the payload as a table (team, project, title, assignee, estimate, cycle, labels, state,
   relations, description first line) and **wait for confirmation**.
5. `linear_save_issue` (create: no `id`; update: `id` = identifier). Report identifier + URL.
6. Multi-ticket splits: one table per ticket, one confirmation for the set, create in dependency
   order, then wire `blocks` using returned identifiers.

Description template (only what applies):

```
## Context
<why / where it came from — link Notion epic, Slack thread, parent Project>
## Goal
<one sentence>
## Acceptance
- <verifier: a check someone can run or observe>
## Notes
<constraints, out of scope, open questions>
```

Epic → `linear_save_project` with team(s), lead, initiative, description; same confirm step.

## Triage mode (read-only)

Trigger: "triage", "what's on my plate", "pick next".

1. `linear_get_notifications` (unread) + `linear_list_issues` assignee=me, state not
   Done/Canceled/Duplicate.
2. Per ticket: identifier, title, team, Project (or **missing**), estimate (or **missing**),
   state, cycle, blockers, age.
3. Rank: current-cycle `In Progress`/`Todo` first, then blocked-others, then by priority/age.
4. Propose **flow** per ticket: `fast` (clear, ≤3pt, bug-like) or `full` (needs research/spec),
   one line why.
5. Output a table + "suggest next: <KEY> (<flow>)". **No mutations** in this mode; if fixes are
   needed (missing Project/estimate), list them and offer the update flow.
