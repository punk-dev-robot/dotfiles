---
name: swap-bet
description: >-
  Run a Swap Labs bet for Custom Agents (Linear AGIT) from ask to outcome. Use when a
  Custom Agents epic, bet or spike is picked up or moved forward (Notion PDE epic, AGIT
  project or ticket, Slack ask, one-line idea): one-pager and PO sync agenda, spec from
  PO decisions, AGIT tickets, stacked PRs, metrics close, or bet status.
argument-hint: "status <KEY> | <intake|brief|publish|sync|tickets|build|close> <KEY> [AGIT-n] [--direct]"
---
# swap-bet

A **bet** is a Swap Labs experiment the owner (the bet's Delivery Owner) runs end to end:
product, engineering, devops, ops. Swap Labs moves fast and picks its own process, so this
skill is a set of **defaults**, not a procedure. Skip any default that costs more than it buys
here, and write one line in the stage artifact (any section) saying what you skipped and
why.

## Hard rules

Only two. Everything else bends.

1. **Spec sign-off before tickets or build.** `tickets` and `build` refuse to start until
   `spec.md` is **signed off**: under `## Sign-off` there is a line with a real date and the
   owner's name, no `<…>` placeholder and no `_pending_`. A decision left `OPEN` at sign-off
   holds back only the slice it names; the spec stays editable after sign-off (`sync.md`).
2. **Access fails fast.** See [Preflight](#preflight). No workarounds, no continuing on
   partial data.

## Spec dir and `<KEY>`

- `~/dev/swapc/specs/<KEY>/` — its own git repo, never pushed. Commit after each stage:
  `git -C ~/dev/swapc/specs add <KEY> && git -C ~/dev/swapc/specs commit -m "<KEY>: <stage>"`.
- `<KEY>` is Linear-based, chosen at `intake` and recorded in `intake.md`. Default: the
  starter ticket of the bet's AGIT project (e.g. `AGIT-123`); with no ticket yet, the
  project slug (e.g. `ability-to-edit-order`). The Notion PDE key is only stored as a link.
- **Small bet** — a lone ticket, no project or epic: `<KEY>` is that ticket id. Same stages,
  scaled down: short brief, `publish` usually skipped (`brief` still drafts the PO message,
  its step 6), `tickets` rewrites that ticket.
  The spec sign-off still applies.

## Dispatch

Read `~/dev/swapc/specs/<KEY>/` first, then act on the argument:

| Arg | Do |
|---|---|
| `status <KEY>` | Which artifacts exist, last gate reached, sign-offs, next stage. Read-only, no preflight. |
| `<stage> <KEY>` | Load `references/<stage>.md` and run it. A missing input artifact → name it and stop, or run the earlier stage if the owner says so. |
| no stage | `status`, then propose the next stage. |

Every stage runs standalone in a fresh session: it reads only the spec dir and its sources.

| Stage | Does | Writes | Gate |
|---|---|---|---|
| [`intake`](references/intake.md) | pull the ask from any entry point, pick `<KEY>`, rate input richness | `intake.md` | — |
| [`brief`](references/brief.md) | research sized to the gap; one-pager + PO sync agenda | `brief.md` | — |
| [`publish`](references/publish.md) | owner OK → Linear project, Slack draft to PO, Notion link | `brief-public.md` | owner OK (`--direct` skips) |
| [`sync`](references/sync.md) | PO decisions → spec: go / park / research again | `spec.md` | **owner signs off spec** |
| [`tickets`](references/tickets.md) | vertical slices → AGIT tickets with blocked-by edges | `tickets.md` ([template](templates/tickets.md)) | post-hoc owner review |
| [`build`](references/build.md) | ready tickets → coding agents → stacked PRs | PR links, scores, Deploy order in `tickets.md` | per-PR defaults |
| [`close`](references/close.md) | metrics → kill / iterate / scale + learning | `outcome.md`, `outcome-public.md` | owner confirms post |

Skill or environment rough edges go to `~/dev/swapc/specs/_skill-feedback.md`; stage
artifacts keep bet facts only.

## Preflight

Every stage reference opens with an access table: each tool it needs and one cheap read-only
call. Run every applicable row before any other work, collecting failures rather than stopping at the
first. Any auth or access failure (expired token, 401/403, MCP server down, CLI missing) →

1. send **one** Plannotator inbox message (`plannotator_inbox` tool, `send_message`; without
   the tool, read `plannotator inbox --help`): a `Stopped: swap-bet <stage> <KEY> — access`
   line, then one bullet per failing tool with the exact command and the exact error text;
2. stop the stage. If the inbox itself is unreachable, say the same in chat.

Fail fast because a bet built on a missing source is worse than a late one, and the owner can
usually fix access in a minute.

## Gates and delegation

- **Owner review**: present → `plannotator-tui` on the artifact (feedback arrives as the next
  message). It is often not on PATH; open the pane directly:
  `herdr plugin pane open --plugin annotate --entrypoint doc --placement split --direction right --target-pane "$HERDR_PANE_ID" --focus --cwd "$PWD" --env PLANNOTATOR_TUI_FILE=<abs artifact path> --env PLANNOTATOR_TUI_DELIVER_TO="$HERDR_PANE_ID"`.
  Away → inbox `send_message` with the artifact as an attachment. Record the outcome
  in the artifact as one line: what was approved, by whom, when.
- **Keep the main session thin**: research and drafting go to subagents (`recon` per repo or
  MCP source, `researcher` for CLI reads like `bq`/`gcloud` and the web); read their summaries and the artifact only when
  gating. Every brief says: "Your final message is your full report; after any steer, still
  repeat the full report."
- **Reference, never copy** other skills: each stage names the ones it composes.
- End every stage by committing the spec dir and naming the next command, e.g.
  `swap-bet sync AGIT-123`, runnable here or in a new session. Pausing mid-stage:
  `punk-handoff`.
