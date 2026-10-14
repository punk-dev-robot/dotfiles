---
name: multi-repo-ticket
description: >
  Coordinate work in a repowise workspace (a parent dir with
  .repowise-workspace.yaml, e.g. ~/dev/swapc). Use whenever a session starts at a
  workspace root — before any implementation, even when work looks single-repo —
  and when work inside a member repo grows to touch a sibling repo, when a Linear
  ticket names multiple workspace repos, or when the user asks to run or scope a
  multi-repo ticket/project. Coordinator is plan-only; per-repo work runs in
  executor agents in worktrees.
---

# Multi-repo ticket coordination

You are the **coordinator**: an interactive pi session at the workspace root
(`~/dev/swapc`). You plan, brief, review, and sequence. **Executors** — one pi
per affected repo, each in its own worktree — make every member-repo edit.

**Coordinator writes only** the ticket file (`.tickets/`) and root-level `*.md`.
Every code change goes through an executor, even a one-liner: dispatch it with a
small brief instead of editing. Executors never message each other; the contract
section of the ticket file is their interface.

## Entry modes

- **Ticket mode** (steps below): input is one Linear ticket touching 2+ repos.
- **Project mode**: input is a project needing scoping. Research with repowise
  workspace tools and recon subagents, then create right-sized Linear tickets —
  some will be single-repo/single-worktree, some multi-repo sets. Governance
  (claiming, resolution comments, acceptance, session-end handoff) follows
  `~/.agents/skills/punk-resume/manager-mode.md`. Then run each multi-repo
  ticket through ticket mode.

> [!NOTE]
> Scoping decides the shape, not the entry point. When step 2 shows exactly one
> affected repo, degrade cheaply: one worktree, one executor (or a single
> `wt switch --create` + normal session there) — skip the ticket file and merge
> ordering. The coordinator habit costs one scoping pass; the machinery is only
> for genuinely multi-repo work.
## Ticket mode

1. **Claim** — read the Linear ticket; assign yourself / move to in-progress
   (gateway MCP; Linear is synced at gates only — never per work-loop).
2. **Scope** — determine affected repos and ordering from the workspace index:
   `get_blast_radius`, `get_context repo="…"`, `get_risk repo="all"`, contracts.
   Derive the **contract-first order**: schema/registry repo → provider →
   consumer. Check collisions with in-flight work: `wt-ticket list` plus every
   file in `~/dev/swapc/.tickets/` — the workspace index only reflects merged
   state, so in-flight branches are visible ONLY through these two sources.
3. **Ticket file** — write `~/dev/swapc/.tickets/<TICKET>.md` from the template
   below: contract decision first, then a self-contained brief per repo.
   A brief must stand alone: executors cannot see this conversation.
4. **Worktrees** — `wt-ticket create <TICKET-slug> <repo>...` (same branch name
   in every repo; seeds each worktree's repowise index in the background).
5. **Executors** — load the `herdr` skill for pane mechanics. Per repo:
   `herdr_layout pane_split` with `cwd` = the worktree, `herdr_agent start`
   (kind `pi`), then `prompt` with: the ticket id, the path to the ticket file,
   and which repo section is theirs. After each `prompt`, `read` the pane and
   confirm the text was submitted, not sitting in the input box — a prompt sent
   while pi is still booting stays unsubmitted (send `enter` if so); otherwise
   `wait` settles on an idle agent that never started.
   Model: default (SOTA) — these are full
   sub-orchestrators that protect their own context via their subagents. For a
   trivial single-file brief, start the pane with a cheaper model instead
   (`pi --model …`).
6. **Monitor** — `herdr_agent wait`. On `done`: review the diff yourself
   (`git -C <worktree> diff`), tick the repo's checklist line in the ticket
   file, add findings. On `blocked`: inspect, unblock or revise the brief and
   re-prompt. If the contract must change mid-flight, update the contract
   section first, then re-brief every affected executor.
7. **Merge** — strictly in the contract-first order from step 2. PRs carry the
   ticket id in branch/title (auto-links in Linear). Gate-sync: post PR links to
   the ticket.
8. **Close** — after all merges: resolution comment + close in Linear
   (gate-sync). Teardown order matters: close the executor panes FIRST (a pi
   process holding the worktree cwd blocks directory deletion), then
   `wt-ticket remove <TICKET-slug>` (add `--force` only when discarding
   uncommitted work), then delete the ticket file. Done means: every checklist
   line ticked, every worktree removed, Linear closed.

## Ticket file template

```markdown
# <TICKET-ID>: <title>

Linear: <url> · Branch: <TICKET-slug> · Status: planning|executing|merging|done

## Contract decision

<the cross-repo interface change, exact: schema/topic/route/field names.
This section is the executors' shared interface — keep it authoritative.>

## Merge order

1. <repo> (contract/registry)
2. <repo> (provider)
3. <repo> (consumer)

## Repos

### <repo-a>  — [ ] done
Brief: <self-contained: what to change, where, acceptance criteria, how to
verify locally. Assume no knowledge of the coordinator conversation.>

### <repo-b>  — [ ] done
Brief: <…>

## Log

- <date> <event: dispatched / reviewed / blocked-on-X / merged>
```

## In-flight index semantics (reference)

- Each worktree owns an isolated `.repowise/` (seeded by `wt-ticket create`).
  Inside a worktree, always `repowise update --no-workspace` — a bare
  `repowise update` there triggers a workspace-wide update instead.
- Workspace-level tools (blast radius, contracts) reflect merged base state
  only; they go current again as merges land in contract-first order.
