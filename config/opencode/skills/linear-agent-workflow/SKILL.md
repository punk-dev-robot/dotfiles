---
name: linear-agent-workflow
description: Use when managing agent tasks, Linear issues, spec-driven work, task handoffs, or discovered follow-up work through Linear and Composio.
---

# Linear Agent Workflow

Use Linear as the shared task layer for agent work. Keep the workflow lightweight while it is being validated.

## Defaults

- Source of truth for task state: Linear.
- Transport: Composio Linear MCP tools when available, Composio CLI when MCP is unavailable.
- Initial team: `62f87de9-2d7b-401d-8bbd-749477d7a773`.
- Do not assume Linear Projects; this workflow starts team-scoped.
- No local task database, SQLite file, or per-worktree hidden state.
- No wrapper CLI initially.
- No continuous agent journal initially.
- Hooks should remind or prime only; they must not write to Linear automatically.

## When To Use

Use this workflow when the user asks to:

- Plan or track implementation tasks in Linear.
- Work from a Linear issue.
- Sync spec-driven development work with Linear.
- Create follow-up work discovered during implementation.
- Hand off task context between worktrees or agents.

Do not force Linear into tiny one-off local tasks unless the user asks.

## Prime

At session start or before taking over an existing task, gather compact context.

Prefer:

1. Infer active Linear issue from branch name, user prompt, or explicit issue key.
2. Fetch the issue and its team/state/parent/sub-issues when relevant.
3. Fetch recent comments only when handoff context is needed.
4. List ready open issues in the current team/context when no active issue is known.
5. State the next useful action briefly.

Prime is read-only. Do not update Linear during prime.

## Task Model

Keep the model flexible during discovery.

Allowed patterns:

- One Linear issue per task.
- One Linear issue per phase, with detailed tasks remaining in local spec artifacts.
- Parent issue plus sub-issues for a larger feature.
- Labels or title prefixes only when they reduce ambiguity.
- Blocking relations only for real hard dependencies.

For spec-driven work, compare two modes before standardising:

- Linear-as-tasks: Linear replaces most or all `TASKS.md` tracking.
- Linear-as-phases: Linear tracks phases or milestones; detailed tasks remain local.

Choose Linear-as-tasks only if it materially improves speed, quality, or token use. Otherwise prefer Linear-as-phases.

## Creating Issues

Before creating anything:

1. Search existing issues in the team/context.
2. Check likely duplicates by title, parent, and nearby work.
3. Confirm team-scoped state/label IDs before using them.
4. Paginate; Linear list calls often default to small page sizes.

Create the smallest useful issue. Prefer clear title and concise description over rigid templates.

## Discovered Work

When out-of-scope work appears:

1. Decide whether it blocks current work or is follow-up.
2. Create or draft a Linear issue in team `62f87de9-2d7b-401d-8bbd-749477d7a773`.
3. Link it to the source issue when useful.
4. Add one short handoff comment only if context would otherwise be lost.
5. Suggest `wt switch --create <issue-key-slug> --base main` for a new worktree, but do not spawn it without explicit user request.

## Lightweight Handoff

Skip journal comments by default. If handoff context is useful, keep it short:

```markdown
Handoff: <short summary>

Done:
- ...

Next:
- ...

Blocked by:
- ...
```

This format is optional. Do not comment on every state transition.

## Composio Linear Rules

- Use `LINEAR_LIST_LINEAR_TEAMS` before team/state/label-sensitive writes unless IDs are already confirmed.
- Use `LINEAR_LIST_LINEAR_STATES` for workflow states; state IDs are team-scoped.
- Use `LINEAR_LIST_LINEAR_LABELS` for labels; avoid group/container labels.
- Use `LINEAR_LIST_LINEAR_ISSUES` with pagination for broad reads.
- Use `LINEAR_GET_LINEAR_ISSUE` before updating an issue.
- Use `LINEAR_RUN_QUERY_OR_MUTATION` for comments, relations, dependencies, or fields missing from dedicated tools.
- Description updates overwrite existing descriptions; omit fields you do not intend to change.

## Safety

- Never delete Linear issues automatically.
- Never bulk-write without a dry-run summary and explicit approval.
- Never auto-post from hooks.
- Prefer comments for handoff, not mutable descriptions.
- Keep Linear clean; avoid noisy status comments.
