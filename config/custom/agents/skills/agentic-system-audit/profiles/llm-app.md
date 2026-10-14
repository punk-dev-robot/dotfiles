# Profile: llm-app

Load when an application calls models with tools, prompts, guardrails, playbooks, few-shot examples, or retrieved content, typically on behalf of end users or tenants.

## Lens A additions

- **Server-owned values:** tenant, user, price, amount, order/account IDs, and permissions come from authenticated context, never from model-supplied tool arguments. Trace each side-effecting tool's arguments to their source.
- **Side-effecting tools:** for each tool that mutates state, moves money, or contacts a person: server-side authorization, confirmation step, idempotency, reversibility, and what happens when the model calls it twice or with stale data.
- **Guardrail placement:** which guardrails run on input, before tool execution, and on output; whether a guardrail error, timeout, or unparsable verdict fails open.
- **Model control flow:** step/loop limits, structured-output parse failures, refusal handling, provider/model fallback, and whether fallback changes capability or safety behavior.
- **Context assembly:** history truncation and summarization, what is dropped first, and whether dropped content was carrying an instruction or constraint.

## Lens B additions

Extend the instruction map with every layer the app composes:

```text
base system prompt → tenant/brand/persona prompt → playbooks → few-shot examples
→ tool descriptions → retrieved/catalog content → remote prompt overrides/flags
→ guardrail prompts → eval rubrics
```

Find:

- remote overrides or flagged variants that drifted from repo prompts, tests, or evals;
- prompts claiming a tool or capability that per-tenant capability gating can remove (`GHOST_CAPABILITY`);
- tools available with no prompt guidance on when to use them (`HIDDEN_CAPABILITY`);
- business limits enforced only by prompt ("never refund over X") with no runtime check (`AUTHORITY_LEAK`);
- eval rubrics or judge prompts that contradict the production prompt.

## Lens C additions

- **Tool results as the model sees them:** do errors arrive as text the model will paraphrase to the user as a false claim? Do internal IDs, other users' data, or secrets reach model context or the user reply?
- **Evals as tests:** which prompt/playbook contracts have an eval that fails when the contract breaks; whether evals run automatically or only by hand; whether an LLM judge can pass a broken answer (tautological rubric).
- **User-visible failure:** what the end user sees when the model, a tool, or a guardrail fails.

## Contract chains

```text
untrusted input: source (user message, catalog/product data, retrieved docs, other tenants, prior model output)
                 ↔ delimiting/sanitization ↔ prompt position ↔ reachable tools ↔ runtime authorization ↔ side effect
side effect:     model intent ↔ tool args ↔ server-side validation/authorization ↔ confirmation ↔ effect
                 ↔ idempotency ↔ user-visible result
prompt:          repo prompt ↔ override/flag ↔ effective runtime prompt ↔ eval fixtures ↔ docs
data exposure:   PII/secrets ↔ prompt context ↔ model provider ↔ logs/telemetry/traces ↔ user reply
```

## Boundary comparisons

```text
tenant capability: enabled | disabled | partially configured
prompt source:     repo default | flag variant | remote override present | override fetch failed
model:             primary | fallback provider/model
conversation:      first turn | long conversation after truncation/summarization
guardrail:         pass | block | error | timeout
```

## Heuristics

- **Can user text reach a tool argument that should come from the server?**
- **What does the model see when the tool fails, and will it tell the user something false?**
- **Is this rule in the prompt or the code?** Money, permissions, and data scope belong in code.
- **Would an eval fail if this prompt clause were deleted?**
- **Which content in the context window did not come from us?**

## Success questions

```text
Which untrusted sources can influence which side-effecting tools?
Which tool arguments are server-owned, and are they enforced server-side?
What is the effective prompt for each tenant/flag combination, and is it tested?
Does any guardrail fail open?
What sensitive data reaches the model provider, logs, or the user?
```
