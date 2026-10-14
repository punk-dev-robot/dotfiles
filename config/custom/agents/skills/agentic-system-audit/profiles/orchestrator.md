# Profile: orchestrator

Load when agents spawn, delegate to, continue, or supervise other agents or sessions, and those agents have durable identity or lifecycle (agent harnesses, multi-agent runtimes, supervisor/worker systems).

## Lens A additions

Prove this liveness invariant for unresolved directly-owned assignments:

> Every unresolved directly-owned assignment must either remain capable of
> making progress without its owner, or have a reliable reconciliation path
> that brings the exact owner back when action is required.

Check:

- every identity layer: logical label, definition, harness session, owner, request, pending question, run, and any terminal/workspace/pane identity;
- stale/replacement identity binding across generations;
- lifecycle states such as `working`, `blocked`, `settling`, `unknown`, plus steerability, staleness, pending question/result, child gating, and cleanup convergence;
- unresolved-work liveness across owner idle/busy state, failed attention delivery, reminder recurrence, episode termination, and restart;
- parent/child distinctions where a working parent may itself be stale while a legitimately waiting parent projects blocked;
- every generation operation: fresh delegation, continuation, fork, replacement, completion, parent-child completion, question/reply, close, rollback, restart/recovery.

## Lens B additions

Extend the instruction map with controller scope, shared agent prompt, role body, and body-included files. Extend the capability chain with launch args and actual role/depth:

```text
definition → override composition → effective tools/skills/extensions/context
→ launch args → actual role/depth → model instructions → presentation
```

Find root/parent/leaf capability mismatches: a rule or tool that is correct at one depth and wrong or absent at another.

## Lens C additions

Inspect list, assignment/steer/reply/close acknowledgements, and completion delivery as model-visible surfaces. Compare compact and expanded UI views, definition views, completion renderers, and status widgets as human surfaces.

## Contract chains

```text
identity:   label ↔ definition ↔ session ↔ request ↔ owner ↔ terminal identity ↔ result/error/UI
state:      runtime evidence ↔ public state ↔ steerability ↔ eligibility ↔ displayed state ↔ next action
completion: completion ↔ durable result ↔ result file ↔ owner message ↔ model content ↔ human rendering ↔ cleanup
recovery:   failure ↔ retained evidence ↔ autonomous progress/attention owner ↔ wake/delivery
            ↔ recurrence/termination ↔ structured error ↔ model/human guidance ↔ retry boundary
```

## Boundary comparisons

```text
controller depth: root | direct agent/parent | nested child/leaf | unmanaged session
agent generation: fresh | exact-session continuation | fork
visibility:       compact UI | expanded UI (in addition to core surfaces)
outcome:          close (in addition to core outcomes)
```

## Test discrimination

Pair lifecycle harms with their nearest legitimate opposite, such as a stale working parent versus a parent correctly waiting on unresolved child work.

## Heuristics

- **What changes at continuation?** Generation-time facts described as dynamically refreshed are suspect.
- **What changes at root/child depth?** Global policy projected differently by depth is suspect.
- **Can unresolved work disappear from attention forever?** Prove either autonomous progress remains possible or reconciliation eventually wakes the exact responsible owner. Check hierarchy boundaries, owner idle/busy state, failed delivery, recurring versus one-shot attention, restart behavior, and episode termination.

## Success questions

```text
What changes by depth and generation?
Can unresolved directly-owned work remain unnoticed forever?
Which identity does each control operation target, and can it hit a stale generation?
```
