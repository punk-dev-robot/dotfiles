---
kind: briefing
when:
  tools: ["*linear*", "mcp__gateway"]
---
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
