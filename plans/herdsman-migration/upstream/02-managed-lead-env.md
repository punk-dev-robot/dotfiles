# Managed Leads (`delegate_project`) get no identity env, unlike delegated agents

**Version:** pi-herdsman 0.26.0, Pi 1.2.0.

## What happens
Delegated agents start with `PI_HERDSMAN_AGENT_DEFINITION`, `PI_HERDSMAN_LABEL`,
`PI_HERDSMAN_OWNER_SESSION_ID`, `PI_SUBAGENT_CHILD=1` and `PI_SUBAGENT_PARENT_SESSION`
(`agent-controller.ts:5767-5781`, `herdr.ts:587-620`). We verified these at runtime.

A managed Lead started by the Manager's `delegate_project` goes through
`startHerdrAgentInPane` (`lead-runtime.ts:~6966`) with no `--env`. Its only identity is
`--session-id <assignment.id>`.

## Why it matters
Other extensions in the Lead process can't tell a managed Lead from a user-started session:
- Telemetry (an OTel extension turning these vars into resource attributes) records managed
  Leads as top-level sessions, with no link to the Manager.
- Session-lifecycle extensions that hand off or restart a "main" session can't recognise that
  the Manager owns the Lead, and may start work outside Herdsman's ownership graph.

## Proposal
Pass a small identity env to managed Leads, e.g. `PI_HERDSMAN_ROLE=managed-lead`,
`PI_HERDSMAN_ASSIGNMENT_ID`, and `PI_SUBAGENT_PARENT_SESSION=<manager session>`. Keep
`PI_SUBAGENT_CHILD` unset if Leads shouldn't be treated as leaf children.
