# Profile: web

Load when agent runs are triggered by HTTP, WebSocket, or SSE requests, or stream responses to a client. Audit only where agent contracts cross the request boundary; generic web-service review belongs to a general audit.

## Lens A additions

Trace the request path:

```text
request → authentication → tenant/store resolution → conversation/session load
→ agent run → tool calls → stream → persistence → response end
```

Check:

- **Identity propagation:** the authenticated identity reaches tools and data access; nothing downstream trusts identity from the request body or model arguments.
- **Cancellation:** client disconnect, client abort, or server timeout mid-run. Does the abort signal reach the model call and in-flight tools, or does the run continue and complete its side effect unobserved?
- **Lost response:** a side effect completes but the response never arrives, the client retries, and the effect repeats.
- **Concurrent turns:** two messages for one conversation at once. Ordering, history write races, and which run's view of state wins.
- **Persistence timing:** whether history/state is saved before, during, or after the stream ends, and what survives a mid-stream failure.
- **Timeouts:** load balancer, gateway, and server timeouts vs worst-case model plus tool latency.

## Lens C additions

- In-stream error frames vs HTTP status vs what the client renders; whether a partial stream can render as a complete answer.
- Client parser vs server frame schema (tool-call events, deltas, termination markers).
- API docs and DTOs vs actual request/response shapes.

## Contract chains

```text
request identity: auth context ↔ tenant/session resolution ↔ tool/data scoping ↔ logs/traces
stream:           model chunks ↔ tool events ↔ transport frames ↔ client parser ↔ UI ↔ persisted transcript
cancellation:     client abort/disconnect ↔ server signal ↔ model call ↔ tool call ↔ side effect ↔ persisted state
```

## Boundary comparisons

```text
request outcome: completed | client disconnect | server timeout | upstream model error mid-stream | client retry of same request
concurrency:     single turn | concurrent second message in same conversation
caller:          authenticated | anonymous/guest | expired session
connection:      continuous | reconnect/resume
```

## Heuristics

- **What happens if the user closes the tab mid tool call?**
- **What happens if the client retries a request whose side effect already happened?**
- **Can a half-finished stream look like a complete answer?**
- **Where does each request get its tenant, and can anything later override it?**

## Success questions

```text
Does cancellation stop side effects, or only stop rendering?
Can a retried or concurrent request repeat a side effect or corrupt conversation history?
Does the client always learn that a run failed?
Is every tool scoped by the authenticated identity?
```
