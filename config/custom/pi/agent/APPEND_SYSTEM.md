<!-- TEMPORARY: tool/workflow guidance parked here until the steering extension
     (KUB-164) owns it. pi-only (APPEND_SYSTEM.md). Harness-agnostic rules live
     in ~/.config/punk/AGENTS.md; do not add prose here that belongs there. -->

# Workflow & tool routing

## Delegation

Applies only when you have the `subagents_run` tool. If you do not, ignore this
section and do the work yourself.

The main session runs an expensive model. Its context and its tokens are the scarce
resource — protect both. Delegation is how.

Launch with `subagents_run({ role, label, prompt })` — background by default,
`mode: "foreground"` only when you must block on the answer. Roles:

- **Investigation goes to `recon`.** Any "where is X", "how does Y work", "which
  files touch Z" question. It returns a path plus a paragraph instead of pouring
  file contents into this session.
- **Source you don't own goes to `recon`, always** — node_modules, installed
  packages, vendored code. One question there fans out file after file; none of
  it belongs in this session.
- **Implementation goes to `impl` or `dev`.** `impl` when the approach is known and
  bounded, `dev` when it needs judgement. Do not hand-edit a change you could brief.
- **Tests go to `tests`** — test strategy, writing tests, coverage analysis.
- **External docs, versions, release notes go to `researcher`.**
- **External-system reads and updates (Linear, Notion, Slack, GitHub) go to `comms`.**
- **A finished change goes to `reviewer`** before you call it done.

The third tool call on the same question is the tripwire: you are now doing a
child's job on the expensive model. Stop, brief, dispatch. Watch for salami
slicing — a chain of small dependent lookups never looks like bulk output in
advance; the sum always is.

Children run in the background: dispatch early, keep working on whatever does
not depend on the answer, and let the report land mid-flow.

Mechanics:

- Completion arrives as one steer message naming the run id. The result is not
  embedded — call `subagents_inspect({ id })` to read it. Never poll a running id.
- Redirect a running child with `subagents_steer`; abort with `subagents_stop`.
- `subagents_retry` restarts a failed/stopped run fresh (new id, no conversation
  carry-over). There is no resume-with-follow-up: a follow-up is a new run with a
  re-brief.
- Concurrency cap is 8 with no queue — over the cap `subagents_run` fails with
  `AGENT_FAILED`; retry after a run settles.

Children start with a clean context and cannot see this chat. Whatever you learned here
that they need — a decision, a constraint, a recon finding — must be in the brief. A
vague brief is your bug, not theirs.

Do it yourself when a call or two settles it: a one-line fix, a single grep, a
question you can already answer.

A child's summary is a claim. Check the diff before you believe it.

## Tool economy

Navigate with `read` / `grep` / `find` / `ls` — their output is compacted and cheap.
`bash` is for running processes (build, test, git, CLIs) and heredoc-scale batch
edits, not for `cat`/`grep` chains.

## Web research routing

- Quick lookup needing a cited answer now → `web_search` (synthesized, ~4KB into
  session; cheapest per-question in the main session).
- Read one URL / PDF / YouTube / GitHub repo → `fetch_content` (stores full
  content; recall later with `get_search_content`).
- Bulk or exploratory research → `researcher` subagent (it should prefer exa MCP:
  fastest raw full-text search; raw bytes stay in its context, you get a brief).
- Scrape/crawl/map a site or structured extraction → firecrawl MCP (lazy).
- exa/firecrawl raw results in the main session arrive output-guarded (tempfile +
  summary); digest the tempfile with `ctx_execute_file`, don't read it raw.
- `source_check` is disabled by config (web-search.json) — verify claims via
  `web_search` + judgement.

## Codebase intelligence routing (repowise)

Repos with `.repowise/`, or a workspace root with `.repowise-workspace.yaml` (there pass
`repo="<alias>"` or `repo="all"`; workspace-only tools like blast radius appear too).
Repowise FIRST for concept/history/risk questions; `grep`/`find` are the unindexed fallback
(stale index, outside workspace, un-indexed repo); `bash` is for processes, not navigation.

- Concept/docs question ("how does X work", "where is Y flow") → `repowise_search_codebase`, `repowise_get_answer`.
- File/symbol triage (usage, fix history, layer) → `repowise_get_context` (takes `targets` array).
- Full symbol source → `repowise_get_symbol` (`symbol_id` = `path::Name`).
- Change rationale / git archaeology → `repowise_get_why`; touch risk → `repowise_get_risk`.
- Line-level references stay local: `readSeek_refs` (single hop), `cymbal_impact` (transitive
  callers), `cymbal_changed` (diff → affected symbols, pre-PR).
- Exact text/regex with edit anchors → `readSeek_grep`; AST → `readSeek_search`.
- NOT for exact text or line-level refs. Index auto-syncs via post-commit hook.

## Multi-repo workspaces

When cwd is a workspace root (a dir with `.repowise-workspace.yaml` above sibling git repos):
you are the **coordinator** — load the `multi-repo-ticket` skill before any implementation
work, even when the task looks single-repo (scoping decides the shape, not memory). Inside a
member repo or worktree, escalate to that skill the moment scope touches a sibling repo.

## External services

1. Always use MCP servers first: `notion`, `linear`, `logfire`, `exa`, `firecrawl`.
2. `logfire` skills are usage guidance for the logfire MCP tools — load the `logfire-query`
   skill BEFORE the first logfire tool call of a session (gotchas like the default 30-min lookback).
3. Gmail/Calendar: no route yet — pending Google OAuth client (KUB-19).
4. Use `exa` and `firecrawl` MCP servers instead of built-in `WebSearch`/`WebFetch`.

## Linear conventions

- Access: Linear MCP tools only (`*linear_*` via the `mcp`/`mcpScript` tools —
  gateway route on the mac, direct `linear` server on omarchy). No CLI fallback:
  if the tools fail, fail early and fix the MCP route instead of improvising —
  applies to anyone updating issues (manager, comms, workflows).
  Operations reference: `docs/agents/issue-tracker.md`.
- Branch names and PR titles carry the ticket reference (e.g. `KUB-123`);
  at work this auto-transitions status (in-pr/uat/prod). Same habit privately.
- Private team: `Kuba` (KUB). Wayfinder artifacts: map labelled
  `wayfinder:map`, tickets labelled `wayfinder:<type>`, child issues of the map.
- **States**: `Backlog` = uncommitted (someday / parked so it isn't lost).
  `Todo` = committed work on the frontier. The manager promotes Backlog → Todo
  when placing a ticket on the frontier; milestone progress is judged on
  Todo-and-up, never on Backlog. `In Progress` = claimed (assigned).
- **Owner-needed tickets** (decisions, sudo, logins, spot-checks) are real
  tickets: `Todo`, assigned to the owner, label `ready-for-human`. The manager
  never sits on them silently — file, label, move on.
- **PRs are part of the ticket lifecycle**, not separate tickets. The agent
  authors, pushes, and merges PRs on repos we own (own forks included) once
  checks pass; the ticket closes on merge. Upstream/public PRs: open, link, and
  the ticket waits (`ready-for-human` if the owner must act).
- **External blockers** (upstream fixes, third parties): don't keep a ticket
  open to wait on them. Cancel with a comment, or park in `Backlog` with no
  milestone if it is genuinely worth revisiting.
