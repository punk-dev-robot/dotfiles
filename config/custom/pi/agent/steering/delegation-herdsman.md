---
kind: briefing
when:
  tools: [delegate_agent]
---
## Delegation

Main-session context and tokens are the scarce resource. Herdsman's contract covers the mechanics and
the Agent descriptions cover routing; these are the house rules on top.

- Investigation and source you don't own (node_modules, installed packages) go to `recon`, not inline reads.
- Do it yourself only when a call or two settles it. The third call on the same question is the tripwire:
  stop, brief, dispatch. A chain of small dependent lookups counts; its sum is the bulk.
- External systems: one small op (a comment, a status change, one issue read) inline via `mcpScript`,
  filtered in code; bulk or multi-step work goes to `comms`.
- A finished change goes to `reviewer` before you call it done. Inside an active poteto-mode playbook its
  `pstack-*` role table wins.
- At most 4 live agents; each is a full pi in its own pane.
- The task carries everything the agent needs from this chat: decisions, constraints, findings.
- An agent's summary is a claim. Spot-check it with one read of the diff or the key file; anything more
  goes to `pstack-verifier` or `reviewer`, not to inline calls.
