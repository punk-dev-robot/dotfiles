---
name: swap-project
description: Chart a chunk of Swap/Agentic work too big for one session as a Linear Project of decision tickets on the doing subteams, then work the Project one ticket at a time until the route to the destination is clear. Use when planning a new epic/feature/project on AGIA…AGID, or when asked to pick the next ticket in an existing Project. Derived from cock-wayfinder; tickets follow swap-linear rules.
disable-model-invocation: true
---

> Derived from `cock-wayfinder` for Swap's Agentic teams; the word "wayfinder" is not used in Linear. Differences: the **map is a Linear Project**
> (Swap deprecated `[EPIC]` parent issues), tickets live on the doing subteam inside that Project
> and are created through the `swap-linear` skill (team, Project, assignee, estimate,
> `platform: Storefront`), ordering uses Project milestones + native `blocks`/`blockedBy`. Vocabulary:
> `Project`, `frontier`, `gate` — see dotfiles `CONTEXT.md`. Team `KUB` keeps `cock-wayfinder`.

A loose idea has arrived, too big for one agent session, and wrapped in fog: the way from here to the **destination** isn't visible yet. Wayfinding is about finding that way, not charging at the destination. This skill charts the way as a **Linear Project** (the map), then works its **decision tickets** (questions whose resolution is a decision, not slices of a build to execute) one at a time until the route is clear.

The destination varies per effort, and naming it is the first act of charting: it shapes every ticket. It might be a spec to hand off and iterate on, a decision to lock before planning starts, or a change made in place like a data-structure migration. The Project is domain-agnostic: engineering work, course content, whatever fits the shape.

## Plan, don't do

Wayfinder is **planning** by default: each ticket resolves a decision, and the map is done when the way is clear, with nothing left to decide before someone goes and does the thing. The pull to just do the work is usually the signal you've reached the edge of the map and it's time to hand off. An effort can override this in its **Notes**, carrying execution into the map itself, but absent that, produce decisions, not deliverables.

## Refer by name

Every map and ticket is an issue, so it has a **name**: its title. In everything the human reads (narration, the map's Decisions-so-far), refer to it by that name, never by a bare id, number, or slug. A wall of `#42, #43, #44` is illegible; names read at a glance. The id and URL don't vanish; a name wraps its link, but they ride _inside_ the name, never stand in for it.

## The Project (the map)

The map is a **Linear Project** under the quarter's Agentic initiative, lead = me, the canonical artifact. Its tickets are issues **inside the Project**, each on the subteam that will do the work. Create the Project with `linear_save_project` (name after the effort, no `[EPIC]` prefix; add a subteam only if it will ship tickets; never default the parent `AGI` on). Add the Project link to the Notion epic if one exists.

The map is an **index**, not a store. It lists the decisions made and points at the tickets that hold their detail; a decision lives in exactly one place, its ticket, so the map never restates it, only gists it and links.

**Tracker operations (Linear, `linear_*` MCP tools, direct server):**

- Map body → Project `description` (`linear_save_project`, `id` = project id).
- Ticket → `swap-linear` create flow with `project` = this Project, type label (`Research`/`spike`/`decision`/`task`) plus any team-local topic label that fits (e.g. AGIA `Monitoring and Alerting`) on top of the required labels; `Research` exists workspace-wide, create the other three on the subteam on first use (`linear_save_issue_label`, confirm first), `milestone` = the stage it belongs to when milestones exist. Estimate: propose per ticket in the confirmation table (typical: research/decision `1`–`3`, task by real size) — Kuba confirms or changes every one before create.
- Blocking → `blocks` / `blockedBy` on `linear_save_issue`.
- Frontier query → `linear_list_issues` with `project` = id, state not Done/Canceled, then drop any with open `blockedBy`, then drop assigned ones.
- Claim → `assignee` = me, state `In Progress`. Resolve → resolution comment (`linear_save_comment`), state `Done`, `Query` label if no PR, append to Project description Decisions-so-far via `patch` op `insert_after` (anchor `## Decisions so far`).
- **Publish hygiene**: research artifacts live in `~/dev/swapc/specs/<project>/<KEY>.md` and may hold my candid notes (people, politics, rapport). Before posting anything to Linear/Notion/Slack, write `<KEY>-public.md` with those removed — facts, links, open questions only — and post that. Never publish the private file.
- Out of scope → state `Canceled` + one line in the Project's Out-of-scope section.

### The map body

The whole map at low resolution, loaded once per session (`linear_get_project`). Open tickets are **not** listed: they are open issues in the Project, found by query.

```markdown
## Destination

<what reaching the end of this map looks like: the spec, decision, or change this effort is finding its way to. One or two lines; every session orients to it before choosing a ticket.>

## Notes

<domain; skills every session should consult; standing preferences for this effort>

## Decisions so far

<!-- the index: one line per closed ticket, enough to judge relevance, then zoom the link for the detail the ticket holds -->

- [<closed ticket title>](link): <one-line gist of the answer>

## Not yet specified

<!-- see "Fog of war": in-scope fog you can't ticket yet; graduates as the frontier advances -->

## Out of scope

<!-- see "Out of scope": work ruled beyond the destination; closed, never graduates -->
```

### Tickets

Each ticket is an **issue inside the Project** on the doing subteam (never a child issue of anything, never on `AGI`); its identifier (`AGIK-123`) is its identity. Its body is the question, sized to one 100K token agent session:

```markdown
## Question

<the decision or investigation this ticket resolves>
```

Each ticket carries a **type label**, one of `Research` (existing workspace label), `spike`, `decision`, `task` (see [Ticket Types](#ticket-types)). These replace cock-wayfinder's `wayfinder:*` namespace: on Agentic subteams nothing collides, and squad leads read `decision` where they would not read `grilling`. Decision-type tickets close with the `Query` label (no PR), per runbook.

A session **claims** a ticket by assigning it to the dev driving the map, **first**, before any work, so concurrent sessions skip it. That assignee _is_ the claim: an open, unassigned ticket is unclaimed.

Blocking uses the tracker's **native** dependency relationship: essential because it renders the frontier _visually_ in the tracker's own UI, so the human sees what's takeable without opening the map. Only a tracker that lacks native blocking falls back to a body convention. A ticket is **unblocked** when every ticket blocking it is closed; the **frontier** is the open, unblocked, unclaimed children, the edge of the known.

The answer isn't part of the body; it's recorded on resolution (see [Work through the map](#work-through-the-map)). Assets created while resolving a ticket are linked from the issue, not pasted in.

## Ticket Types

Every ticket is either **HITL** (human in the loop, worked _with_ a human who speaks for themselves) or **AFK**, driven by the agent alone. A HITL ticket only resolves through that live exchange; the agent never stands in for the human's side of it (a grilling agent that answers its own questions has broken this).

- **Research** (AFK): Reading documentation, third-party APIs, or local resources like knowledge bases to surface a fact a decision waits on. Resolved by a subagent that calls the Skill tool with "research". Use when knowledge outside the current working directory is required.
- **Spike** (HITL) — cock-wayfinder's *prototype*: Raise the fidelity of the discussion by making a cheap, rough, concrete artifact to react to (an outline, a rough take, a stub, or UI/logic code) by calling the Skill tool with "prototype". Links the prototype as an asset. Use when "how should it look" or "how should it behave" is the key question.
- **Decision** (HITL) — cock-wayfinder's *grilling*: Conversation. The default case. Always call the Skill tool twice, for "grilling" and "domain-modeling".
- **Task** (HITL or AFK): Manual work that must happen before a _decision_ can be made: nothing to decide, prototype, or research, but the discussion is blocked until it's done. Signing up for a service so its API can be judged, provisioning access, moving data so its shape can be seen. This is the one type that _does_ rather than decides, and it earns its place by unblocking a decision, not by delivering the destination. The agent drives it alone where it can (AFK); otherwise it hands the human a precise checklist (HITL). Resolved when the work is done; the answer records what was done and any resulting facts (credentials location, new URLs, row counts) later tickets depend on.

## Fog of war

The map is _deliberately_ incomplete: don't chart what you can't yet see. Beyond the live tickets lies the **fog of war**: the dim view of decisions and investigations you can tell are coming but can't yet pin down, because they hang on questions still open. Resolving a ticket clears the fog ahead of it, graduating whatever's now specifiable into fresh tickets, one at a time, until the way to the destination is clear and no tickets remain.

The map's **Not yet specified** section is where that dim view is written down: the suspected question, the area to revisit later. It's the undiscovered frontier _toward_ the destination: everything here is in scope, just not sharp enough to ticket. Write as loosely or as fully as the view allows; it doubles as a signpost for collaborators reading where the effort is headed.

**Fog or ticket?** The test is whether you can state the question precisely now, _not_ whether you can answer it now.

- **Ticket when** the question is already sharp, even if it's blocked and you can't act on it yet.
- **Not yet specified when** you can't yet phrase it that sharply. Don't pre-slice the fog into ticket-sized pieces: it's coarser than a ticket, and one patch may graduate into several tickets, or none, once the frontier reaches it.

**Not yet specified** excludes what's already decided (Decisions so far), what's already a live ticket, and what's out of scope (the next section).

## Out of scope

Fog only ever gathers _toward_ the destination. The destination fixes the scope, so work beyond it is **out of scope**: it isn't fog, and it doesn't belong in **Not yet specified**. It gets its own **Out of scope** section on the map: work you've consciously ruled out of _this_ effort. Scope, not sharpness, lands it here.

Out-of-scope work never graduates (the frontier stops at the destination), so it returns only if the destination is redrawn, and then as a fresh effort, not a resumption.

Ruling something out of scope is a scoping act, not a step on the route. When a ticket that already exists turns out to sit past the destination (mis-scoped in while charting, or exposed by a resolution), **close it** (a closed ticket is unambiguously off the frontier) and leave one line in the **Out of scope** section: the gist plus why it's out of scope, linking the closed ticket. It stays out of **Decisions so far**, which records the route actually walked; a scope boundary isn't a step on it.

## Invocation

Two modes. Either way, **never resolve more than one ticket per session**, with the exception of research tickets.

### Chart the map

User invokes with a loose idea.

1. **Name the destination.** Call the Skill tool twice, for "grilling" and "domain-modeling", to pin down what this map is finding its way to: the spec, decision, or change. The destination fixes the scope, so it's settled first.
2. **Map the frontier.** Grill again, **breadth-first** this time: fan out across the whole space rather than deep on any one thread, surfacing the open decisions and the first steps takeable now. **If this surfaces no fog** (the way to the destination is already clear, the whole journey small enough for one session), you don't need a map. Stop and ask the user how they'd like to proceed.
3. **Create the Project**: pick the initiative (ask if unclear), Destination and Notes filled in, Decisions-so-far empty, the fog sketched into **Not yet specified**. Show the payload, confirm, `linear_save_project`.
4. **Create the tickets you can specify now** inside the Project via `swap-linear` (one confirmation for the set), then wire blocking edges in a **second pass** (issues need ids before they can reference each other). Wiring sorts them into the frontier and the blocked; everything you can't yet specify stays in the fog: the **Not yet specified** section.
5. **Fire the research subagents.** For each `research` ticket you just created, spin up a subagent that calls the Skill tool with "research" to resolve it in parallel, capturing its findings on a throwaway `research/<name>` branch with a context pointer from the ticket.
6. Stop: charting is one session's work; it hand-resolves nothing.

### Work through the map

User invokes with a Project (URL, id, or name). A ticket is **optional**: without one, you pick the next decision, not the user.

1. Load the **Project** description: the low-res view, not every ticket body.
2. Choose the ticket. If the user named one, use it. Otherwise take the first frontier ticket in order. **Claim it**: assign it to yourself before any work.
3. Resolve it. **Zoom as needed**: fetch the full body of any related or closed ticket on demand; call the Skill tool for whichever skills the `## Notes` block names. If in doubt, call the Skill tool twice, for "grilling" and "domain-modeling".
4. Record the resolution: post the answer as a **resolution comment**, set the issue `Done` (label `Query` when no PR), and **append a context pointer** to the Project's Decisions-so-far.
5. Add newly-surfaced tickets (create-then-wire); graduate any fog the answer has made specifiable, clearing each graduated patch from **Not yet specified** so it lives only as its new ticket. If the answer reveals that a ticket (this one or another) sits beyond the destination, **rule it out of scope** rather than resolving it on the route. If the decision invalidates other parts of the map, update or delete those tickets.

The user may run unblocked tickets in parallel, so expect other sessions to be editing the tracker concurrently.
