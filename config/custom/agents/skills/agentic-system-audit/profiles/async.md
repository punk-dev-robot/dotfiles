# Profile: async

Load when agent runs are triggered by, or emit, queue messages, pub/sub events, schedules, or webhooks. Audit only where agent contracts cross the async boundary; generic messaging review belongs to a general audit.

## Lens A additions

- **Delivery semantics:** assume at-least-once unless proven otherwise. What is the dedupe/idempotency key, and does it cover the side effect or only the handler entry?
- **Non-deterministic retry:** a redelivered message re-runs the model, which may decide differently after attempt 1 already acted partially.
- **Ack timing:** ack before the model call, after the side effect, or somewhere between; what each choice loses or repeats.
- **Visibility/lease timeout vs latency:** a slow model run outlives the lease, gets redelivered, and two runs act concurrently.
- **Ordering:** per conversation/user/entity key; what the agent does with out-of-order or stale events whose state has since changed.
- **Poison messages:** model output or malformed events that fail every retry; DLQ ownership, alerting, and replay safety.
- **Atomic emission:** state write plus publish (outbox or equivalent); what downstream sees if one succeeds and the other fails.
- **Fan-out and schedules:** one event triggering several agents with conflicting actions; overlapping scheduled runs.
- **Webhooks:** signature verification, replay protection, and trusting payload fields that should be re-fetched.

## Lens B additions

Event payloads and re-fetched state become prompt context. Find instructions that assume fresh state when the context comes from a possibly stale event.

## Lens C additions

- Event schemas: producer, consumer, and docs agree; versioning across deploys where old and new code run side by side.
- Tests: duplicate delivery, out-of-order delivery, and partial failure covered by a discriminating test, not only the happy path.
- Operators: a failed or dead-lettered agent run is visible to a human with enough context to act.

## Contract chains

```text
delivery: producer ↔ schema ↔ broker ↔ consumer validation ↔ dedupe ↔ agent run ↔ side effect ↔ ack ↔ retry/DLQ
context:  event payload ↔ re-fetched state ↔ prompt context ↔ decision
emission: agent decision ↔ state write ↔ publish (outbox) ↔ downstream consumer
```

## Boundary comparisons

```text
delivery: first | redelivery after success | redelivery after partial effect | redelivery while first run still active
order:    in order | out of order | stale (state changed since emission)
failure:  transient | poison | DLQ replay
deploy:   same schema | producer/consumer on different schema versions
```

## Heuristics

- **What happens if this message is delivered twice? While the first run is still going?**
- **If the model decides differently on retry, which decision wins, and what did the first one already do?**
- **Is this event's data still true when the agent acts on it?**
- **Who finds out when an agent run dead-letters?**

## Success questions

```text
Can any delivery pattern repeat a side effect?
Is the agent's context fresh enough for the action it takes?
Are state changes and emitted events consistent under partial failure?
Is every failed run visible and safely replayable?
```
