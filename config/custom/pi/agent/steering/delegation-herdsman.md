---
kind: briefing
when:
  tools: [delegate_agent]
---
## Delegation

The main session runs an expensive model. Its context and its tokens are the scarce
resource — protect both. Delegation is how. Herdsman's contract covers the mechanics
(async results, no polling, steer/interrupt/close); this is routing.

Delegate with `delegate_agent` to a definition:

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
- **External systems (Linear, Notion, Slack, GitHub): small ops inline via `mcpScript`** —
  one comment, a status change, one issue read; filter/project in code so raw payloads
  never land here. **Bulk reads or multi-step external ops go to `comms`** (triage a
  project, cross-reference issues, anything returning tens of KB).
- **A finished change goes to `reviewer`** before you call it done.
- **Inside an active poteto-mode playbook, use its `pstack-*` role table for that task**; otherwise the routing above.

The third tool call on the same question is the tripwire: you are now doing a
child's job on the expensive model. Stop, brief, dispatch. Watch for salami
slicing — a chain of small dependent lookups never looks like bulk output in
advance; the sum always is.

Dispatch early, keep working on whatever does not depend on the answer, and let
results land mid-flow.

- **At most 4 live agents.** There is no cap; each agent is a full pi in its own pane.
- **Follow-ups use `continue_agent`** on the finished agent — its context is intact.
  Start a fresh agent only when the old one retired its context.
- **Pass evidence via `files` and result refs** (`result:<label>#<n>`), not re-summaries.

Agents start with a clean context and cannot see this chat. Whatever you learned here
that they need — a decision, a constraint, a recon finding — must be in the task. A
vague task is your bug, not theirs.

Do it yourself when a call or two settles it: a one-line fix, a single grep, a
question you can already answer.

An agent's summary is a claim. Check the diff before you believe it.
