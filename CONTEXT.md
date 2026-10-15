# Dotfiles

Personal configuration for two hosts: an Omarchy (Arch + Hyprland) mini-pc and a
work macOS laptop. Deployed by dotter. This glossary fixes the vocabulary used
when deciding what Omarchy owns and what stays mine.

## Language

### Migration verdicts

Every config in the repo gets exactly one verdict against Omarchy.

**Keep**:
My config wins. Dotter deploys it in place of Omarchy's.
_Avoid_: override, mine, custom

**Adopt**:
Omarchy's config wins. My version is retired from the repo (or parked in
`config/.disabled/`).
_Avoid_: drop, delete, default, omarchy's

**Tweak**:
Omarchy's config is the base; my deltas are layered through Omarchy's own
user-override points (e.g. `~/.config/hypr/bindings.lua`).
_Avoid_: patch, extend, customize

### Ownership

**Omarchy-owned**:
A file Omarchy installs and may rewrite on update. Never edited directly; only
tweaked through an override point.
_Avoid_: system file, upstream

**Override point**:
A file or directory Omarchy documents as the place for user changes and
promises not to overwrite (`~/.config/hypr/*.lua`, `~/.config/omarchy/*`).
_Avoid_: hook, config dir, user config

### Repo layout

**Host profile**:
A `.dotter/<hostname>.toml` selecting the dotter packages and variables for one
machine (`omarchy`, `kubas-mac`).
_Avoid_: target, machine config

**Museum**:
`config/linux/`: the pre-Omarchy Arch/Hyprland stack, kept intact until each
entry had a verdict. Removed in KUB-105 after every entry's verdict was
implemented (Keep/Tweak ported, Adopt retired); term kept for history in
older docs/ADRs.
_Avoid_: legacy, old config

**Omarchy package**:
`config/omarchy/`: artifacts that exist only because of Omarchy (override-point
files, Omarchy-specific dotter entries). Names the Keep/Tweak-verdicted
artifacts ported from the museum; Adopt-verdicted material is not here —
Omarchy's own copy wins and nothing of mine ships.
_Avoid_: linux config, overrides dir

### Desktop

**Scratchpad**:
A named Hyprland special workspace holding one app, toggled by a key; launches the
app if it is not running. Defined in the omarchy package, not by a daemon.
_Avoid_: dropdown, hyprscratch, special

### Agent context

**Harness**:
A runtime that loads context files and exposes tools to a model — coding-agent
CLIs (pi, Claude Code, codex, opencode) and custom SDK-built agents alike.
_Avoid_: agent, CLI, tool

**Context file**:
A markdown file (`AGENTS.md`, `CLAUDE.md`) a harness reads into the system
prompt at startup. Prose only; no tool-specific guidance.
_Avoid_: rules file, instructions, memory, prompt

**Global context**:
The single harness-agnostic context file, `~/.config/punk/AGENTS.md`. Every
harness's own global slot is a symlink to it. Holds only what applies to every
harness in every session.
_Avoid_: shared rules, base AGENTS.md

**Project context**:
A repo's own `AGENTS.md`: identity, layout, commands, repo-specific rules.
`CLAUDE.md` beside it is only a shim pointing at it.
_Avoid_: repo rules, CLAUDE.md

**Steering**:
Guidance injected into the prompt by an extension, conditioned on the task and
on which tools are active. Phase 2; not written into context files.
_Avoid_: rules, instructions, hints

**Enforcement**:
Blocking or rewriting a tool call via hooks. Distinct from steering: steering
advises, enforcement prevents.
_Avoid_: guardrail, policy, ban

**Poteto mode**:
The opt-in pi-pstack-herdsman playbook mode (`/poteto-mode`) for the lead
session: match a task to a playbook, then delegate its steps to the pstack
roster.
_Avoid_: pstack mode, controller mode

**pstack roster**:
The 11 `pstack-*` leaf agent definitions the poteto-mode playbooks name.
Ours are dotter templates on our model tiers and tool kits; names must match
the package's.
_Avoid_: pstack agents, poteto agents

### Ticket workflow

**Stage**:
One unit of the bet pipeline run by the `swap-bet` skill (`intake`, `brief`,
`publish`, `sync`, `tickets`, `build`, `close`). Ends by writing an artifact;
either gated or automatic.
_Avoid_: phase, step, milestone (a milestone is Linear's grouping inside a Project)

**Bet**:
A Swap Labs experiment (team AGIT) run end to end by its Delivery Owner, from
ask to kill / iterate / scale. Keyed by a Linear id; product tracks it as a
Notion epic.
_Avoid_: feature, initiative

**Intake**:
First stage and its artifact `intake.md`: the ask pulled from any entry point
(Notion epic, Linear, Slack, one sentence), the `<KEY>`, and its **richness**
(`one-liner` / `partial` / `PRD`), which sizes the brief's research. Replaces
the older `intent` stage and its `fast`/`full` flow.
_Avoid_: intent, ticket summary

**Brief**:
The one-pager plus PO sync agenda (decisions with options and a
recommendation) written by the `brief` stage.
_Avoid_: research doc, PRD (product's)

**Artifact**:
The file a stage writes (`intake.md`, `brief.md`, `spec.md`, `tickets.md`,
`outcome.md`).
Lives in the spec dir, committed per stage.
_Avoid_: document, output, deliverable

**Spec dir**:
`specs/<KEY>/` beside the work repos in the workspace root; one per ticket or
Project, holds every artifact for it. Its own git repo, not pushed.
_Avoid_: feature dir, workspace, folder

**Verifier**:
A concrete check named in the spec that proves an acceptance criterion
("query X returns 0 rows", "p95 < 300 ms", "screenshot matches"). Run during
`build` (e.g. `verify-window-shop`); no dedicated "verifier agent" noun.
_Avoid_: acceptance test, validator, verifier agent

**Gate**:
A stage boundary that stops until a human decides. Has an owner (me, squad
lead, product). Only mandatory gate: owner sign-off on the spec (`sync`);
`publish` and `close` default to an owner OK.
_Avoid_: checkpoint, approval, review (review is a stage)

**Sign-off**:
The recorded approval at a gate — plannotator approve, or a Linear/Notion
comment. Unblocks the next stage.
_Avoid_: approval, LGTM, ack

**Publish**:
Explicit step copying an artifact to where the team reads it: Linear project
description, Slack post to the PO, Notion epic link. After owner OK by default
(`--direct` skips it for the brief), never automatic, and always from a
sanitised public copy — candid notes stay in the spec dir.
_Avoid_: export, attach (`sync` is the stage after the PO meeting)

**Project**:
The planning container in Swap shape (what `cock-wayfinder` calls a map): a Linear Project under an initiative,
description holding Destination / Notes / Decisions-so-far / Not-yet-specified
/ Out-of-scope, tickets inside it on the doing subteam, ordered by milestones
and blocking relations. Team `Kuba` keeps the older parent-issue **map**.
_Avoid_: epic, roadmap, map (for Swap)

**Frontier**:
Tickets in a Project (or under a map) that are not done and have no open
blockers — what can be picked next.
_Avoid_: next up, ready queue

**Triage**:
Our read-only mode over tickets others assigned to me: rank, flag missing
fields, propose the next stage. Distinct from Linear's `Triage` status, which is
always written with the word "status".
_Avoid_: pick, inbox

**Team rules**:
Ticket rules bound to a Linear team key: Agentic subteams follow the Swap
runbook, `KUB` follows our own. Selected by team key; there is only one
workspace.
_Avoid_: tenant, profile, workspace
