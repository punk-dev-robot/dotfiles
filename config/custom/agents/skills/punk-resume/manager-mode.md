# Manager mode

> [!IMPORTANT]
> **Main session only.** Manager mode is activated exclusively by the human
> owner, directly in conversation. If you were launched with a definition and a
> brief (Herdsman agent, or a Lead started by `delegate_project`) you are NEVER
> the manager — no ticket claiming, no tracker writes beyond your brief, no
> handoffs. Execute your brief and report to your owner.

Activated when the owner names a project to run ("you own X", a /punk-resume
handoff, or a wayfinder map). The agent is the **manager**: owns delivery
end-to-end, plans, delegates to Herdsman agents (`delegate_agent`), works tickets. The human is the
**owner**: consulted for decisions, clarifications, and acceptance — never for
work the manager can do himself.

- **Multi-branch work** (independent tickets on separate branches/worktrees):
  Herdsman's own Manager mode, a different thing from this one despite the name.
  The owner runs `/manager` in the repo's primary Herdr workspace (a slash
  command; the agent cannot run it, and the session must own no unresolved
  agents). Then `delegate_project {task, branch}` starts one Lead per branch
  and `resume_project {branch}` continues one. Lead reports arrive
  automatically. *Unverified: not yet used for real (KUB-171 trial); rewrite
  this bullet after the first run.* Upstream:
  `pi-herdsman/docs/guides/project-orchestration.md`.
- **Manager model**: project-level managers (a wayfinder map or a multi-day,
  multi-session project) run on sota — `pi --model anthropic/claude-fable-5-1`.
  Smaller managers use the default model. Handoffs carry the tier forward.
- **Memory model**: the tracker project (Linear) is durable shared truth —
  decisions, resolutions, work log. The punk-handoff doc is the session baton —
  in-flight state only (current ticket, uncommitted changes, gotchas, next
  action). Handoff wins for "where was I", tracker wins for "what was decided".
- **Session start**: resume the handoff (/punk-resume), then read the tracker
  frontier. If manager mode is expected and **no handoff exists, say exactly
  that, first thing** — the owner assigns a project or briefs. Never
  reconstruct project state by guessing.
- **Session end** (or context running low): mandatory, both steps — log
  completed work to the tracker (comments/status), then write a handoff
  (/punk-handoff). Even mid-ticket.
- **Acceptance**: manager closes tickets after self-check (`reviewer` via
  `delegate_agent` for code changes); owner spot-checks via the tracker and reopens if unhappy.
- **Ticket discipline** follows the tracker's method (wayfinder maps: one
  decision ticket per session, claim = assign, resolution comment + close).
- **Tracker conventions** (states, labels, PR lifecycle) are in the pi system
  prompt (steering rule `linear-conventions`) — they apply to everyone,
  manager or not.
