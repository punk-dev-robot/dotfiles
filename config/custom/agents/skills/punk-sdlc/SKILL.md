---
name: punk-sdlc
description: Run a ticket through the staged pipeline — intent, research, spec, plan — one artifact per stage in the ticket's spec dir, gated by plannotator before anything reaches the team. Use when a ticket arrives underspecified, when asked to spec/estimate/decompose one, or to report where a ticket stands.
argument-hint: "<intent|research|spec|plan> <KEY> | status <KEY>"
---
# punk-sdlc

**Persona:** I am Kuba Gaj. Artifacts read in first person as me.

**Vocabulary** is fixed by dotfiles `CONTEXT.md` § Ticket workflow: *stage, flow, intent,
artifact, spec dir, verifier, gate, sign-off, publish, Project, frontier*. Use those words.

**Spec dir:** `~/dev/swapc/specs/<KEY>/` — its own git repo, never pushed. One dir per ticket
(or per Project when the ticket is inside one). Commit after each stage:
`git -C ~/dev/swapc/specs add <KEY> && git -C ~/dev/swapc/specs commit -m "<KEY>: spec v2"`.

## Dispatch

Read `~/dev/swapc/specs/<KEY>/` first, then act on the argument:

| Arg | Do |
|---|---|
| `status <KEY>` | list which artifacts exist, the flow chosen at intent, the last gate reached, and the next stage. Read-only. |
| `<stage> <KEY>` | run that stage. Missing prior artifact → run the earlier stage first, or say which one is missing and stop. |
| no stage | `status`, then propose the next stage. |

Each stage is one `planner`-role dispatch (`subagents_run`, or `agent("planner", …)` in a
workflow) with the stage, the `<KEY>`, and the spec dir in the brief. The planner drafts; this
session gates. Keep the artifact out of this session's context — read the planner's summary and
the file only when gating.

## Stages

| Stage | Does | Reads | Writes | Gate |
|---|---|---|---|---|
| `intent` | fetch ticket + Project + linked docs; restate as problem / outcome / affected systems / constraints / unknowns; choose the flow | Linear, Notion links | `intent.md` | none |
| `research` | codebase (`repowise_*`, ts+py monorepos), Notion, Slack threads, web best-practice; complexity read | repos, MCP | `research.md` | none |
| `spec` | assumptions as options with a recommended default, acceptance criteria, a verifier per criterion, out of scope | `intent.md`, `research.md` | `spec.md` | **plannotator** → me |
| `plan` | per-repo breakdown, order, risks, estimates, ticket split (3/5/8) | `spec.md` | `plan.md` | **plannotator** → me, then a `swap-linear` confirm per proposed ticket |

**Flow**, chosen at intent and recorded in `intent.md`:

- `fast` — bug, ≤3 points, ask is clear: intent → a one-paragraph spec inline in `spec.md` →
  plan. Research only when asked.
- `full` — every stage. Pick `full` when the unknowns list in `intent.md` holds anything a
  reviewer would ask about.

## Gates

A gate stops the pipeline until I decide. Submit with `plannotator_submit_plan`.

It only accepts files **inside the cwd**, and the spec dir is outside every work repo. So:
copy the artifact to `docs/.scratch/<KEY>-<stage>.md` under the cwd, submit that copy, then
apply the accepted edits back to the artifact in the spec dir and commit. The spec dir stays
the single source of truth; the copy is scratch.

Sign-off is the plannotator approval (or a Linear/Notion comment when I reply there). Record it
in the artifact — one line: what was approved and when. No sign-off → no next stage.

## Publish

Publishing is a separate explicit step through the `comms` role, never part of a stage and
never automatic. It happens only after sign-off:

1. Sanitise: write `<KEY>-public.md` in the spec dir — drop candid notes, internal names,
   half-formed opinions, anything I would not say in the ticket. Candid notes stay local.
2. Show me the sanitised copy.
3. `comms` posts it: Linear issue description patch or `linear_save_document` on the issue /
   Project; Notion page under the epic page when product needs to annotate, linked back to
   Linear.

## Other skills

Reference, never duplicate:

- Technique: `cock-grilling` (unknowns), `cock-domain-modeling` (vocabulary), `cock-research`
  (external evidence), `cock-codebase-design` (seams, module shape).
- Ticket writes: `swap-linear` on Agentic subteams (AGI*), `swap-project` when the ticket lives
  inside a **Project** or one needs charting. Team `KUB` follows the `linear-conventions`
  steering rule instead.
- Multi-repo execution after plan: `multi-repo-ticket`.

## Stage templates

[intent.md](templates/intent.md) · [research.md](templates/research.md) ·
[spec.md](templates/spec.md) · [plan.md](templates/plan.md) — the shape each artifact takes.
Drop a heading only when it is genuinely empty, and say so rather than leaving it blank.
