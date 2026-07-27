# Pi Multi-Agent Orchestration — Design

**Date:** 2026-07-27
**Status:** Approved design, pre-implementation
**Owner:** kuba.gaj

## 1. Goal & non-goals

**Goal.** Replace "one expensive model does everything" with **graduated orchestration**:
cheap models do the groundwork, frontier reasoning is *borrowed* only when a decision
is consequential, and heavy machinery is opt-in. Two outcomes: (a) lower token/$ burn on
the complex multi-repo Window Shop platform, (b) hands-on learning of orchestration
patterns before a future custom implementation.

**Non-goals.**
- Not building a bespoke orchestrator yet — deliberately compose mature packages first to learn.
- Not forcing heavy flows (punk SDD, fan-out) onto simple/medium tasks.
- Not adopting `@chankov/agent-fleet` now (v0.0.6, too immature) — revisit once it matures.

## 2. Architecture — two axes + a complexity dial

- **Horizontal (delegation)** via `@minhduydev/pi-subagents`: a role ladder that spawns
  worker agents in Herdr panes/worktrees with review gates.
- **Vertical (second opinion)** via `pi-advisor-flow`: any agent borrows a frontier
  "advisor" for consequential decisions, stalls, and final review. The advisor reviews /
  answers; it does not take over or run tools.
- **Complexity dial (opt-in, never forced):**
  - **simple** → 1 lean agent (+ optional advisor ping).
  - **medium** → manager + 1–2 specialists + review gate.
  - **complex/parallel** → add `@quintinshaw/pi-dynamic-workflows` fan-out.

## 3. Roles & ladder

```
manager / epic-owner   (tab 1, you talk to it) — fast/workhorse, thin context: board, delegation, status
   ⇅ principal / architect — deep/sota ON DEMAND: co-designs with manager, allocates model tiers, hard calls
   ├─ specialists (workhorse default): devops · observability · ai-eng · be-eng · fe-eng — execute in worktrees
   │     └─ recon (fast, read-only): findings written to disk, never into manager context
   └─ reviewer (deep, cross-model): independent gate before ship
```

- **manager⇄principal is a discussing pair**, not a strict parent→child. The manager is
  cheap and persistent (tab 1); the **principal is a separate deep model consulted
  on-demand** — it costs nothing until invoked (implemented via `pi-advisor-flow` at the
  top level). This is the "1 level more + advisor" ask.
- **Specialists are domain-typed** to match the platform: devops (`shopiac`/`shopargo`),
  observability, ai-eng (`shopai`), backend-eng (`shopmr`), frontend-eng.

## 4. Model tiers — Anthropic-first, dynamic, default-cheap → escalate

The cost lever is **not** a fixed model-per-role. It is: **default to cheap, and the
principal (or you) escalates only when a decision is consequential.** From experience,
most epics run at fable/sonnet; opus/sota is earned, not assumed.

| Tier | Model | When |
|---|---|---|
| **fast** | `claude-fable-5` | recon, groundwork, routine coordination |
| **workhorse** | `claude-sonnet-5` | most specialist execution, most epic coordination |
| **deep** | `claude-opus-5` | hard design calls, review gate |
| **sota** (rare) | current best available Anthropic model | final architecture sign-off, deadlocks |
| _cross-model_ | `gpt-5.6-sol` | _sparingly_ — a different family's second opinion only |

- **Budget bias:** ~$2,000 Anthropic (often extendable) vs ~$400–500 GPT → lean Anthropic;
  reserve `gpt-5.6-sol` for occasional cross-family review, not routine work.
- Each profile carries a **default tier + escalation ceiling**; the principal bumps a task
  up/down at runtime.

## 5. Agent profiles — `agents/*.md`

- **Global:** `~/.pi/agent/agents/*.md` · **Per-repo:** `.pi/agents/*.md` (both read by
  `pi-subagents`; profiles are owned by us, additive, no parent-prompt pollution).
- Each profile = **default model tier + escalation ceiling + tool allowlist + skill set +
  prompt** — this *is* the diet (§6) applied per role.
- **Exact frontmatter keys + `task_control` semantics are TBD** — confirm from
  `@minhduydev/pi-subagents` docs/examples during P1 (do not assume).

Proposed profiles: `manager`, `principal`, `specialist-devops`, `specialist-observability`,
`specialist-ai-eng`, `specialist-be-eng`, `specialist-fe-eng`, `recon`, `reviewer`.

## 6. Diet-C mapping (the quick token win)

Baseline harness ≈ **34k tokens** (78 skill frontmatters ~14k + 31 tools ~15k), measured on
a fresh `shopmr` start via Contextimate. Per-profile scoping targets:

- `recon` / `manager`: lean tool allowlist + minimal skills → target **<12k harness**.
- `specialist-*`: fuller edit/bash/lsp/CBM tools, curated skills → target **<20k**.
- Keep `context-mode` on specialists/recon (its token-saving earns its cost); drop it from
  `manager` (pure delegation).
- Dominant lever is the **46 project skills** auto-discovered from `shopmr/.agents/skills`;
  `~/.config/claude/skills` is already NOT loaded by Pi.

## 7. Herdr topology

- **Tab 1 = manager only, kept clean** (renamed via `pi-rename-pane`).
- **One tab per active work item** — a parent task/phase, or a standalone medium task when
  there is no parent level. Named for the work item.
- **Split panes within a task tab** for that item's specialist(s) + recon/reviewer.
- You live in tab 1; switch tabs to watch an item; focus a pane to jump in. `pi-subagents`
  owns lifecycle/worktrees; `@ogulcancelik/pi-herdr` provides clean control tools.

## 8. Advisor & review flow ("2 models, escalate on disagreement")

- **Advisor (vertical):** manager/specialist call `ask_advisor` on consequential calls;
  advisor reviews, does not run tools. Cheap-by-default, frontier-on-demand.
- **Review gate (horizontal):** `reviewer` (cross-model — e.g. opus reviewing sonnet's
  work) must pass before `task_control` ship.
- **Escalation:** disagreement after N turns → escalate to you with **both positions +
  attribution** (Herdr notification / `pi-ask-herdr`), so budget isn't burned looping.

## 9. punkfl0w / Linear integration (opt-in, per-phase)

- punk SDD flow is **heavy → opt-in**, not the default. Light path: manager delegates a
  task straight to a specialist worktree.
- When used, the unit is a **phase**, not the whole epic: run `speckit.punk.*` per phase,
  **worktree per phase** — unless a phase carries big parent tickets, then a worktree per
  big ticket.
- Shape: **epic → phases → (worktree/phase) → tasks**. `taskstoissues` syncs to Linear
  (e.g. AGI-####); ship gate updates the issue.

## 10. Package set (Dotter-managed `settings.json`)

| Role | Package | Status |
|---|---|---|
| Delegation runtime (core) | `@minhduydev/pi-subagents` | mature 0.7.1 |
| Advisor / second-opinion | `pi-advisor-flow` | 0.2.6 |
| Herdr control tools | `@ogulcancelik/pi-herdr` | 0.4.0 |
| Nice pane naming | `pi-rename-pane` | 0.1.1 |
| Fan-out (opt-in) | `@quintinshaw/pi-dynamic-workflows` | mature 3.4.1 |
| SDD + Linear spine | `punkfl0w` (existing) | `~/dev/oss/punkfl0w` |

## 11. Validation (ties into installed observability)

Use the `@spences10/pi-telemetry` + `pi-observability` stack to **measure the win**:
compare tokens/$ for one real epic run orchestrated vs. the old single-expensive-model
baseline. Success = lower total cost at equal/better quality + a full epic driven
manager → specialist → review → ship.

## 12. Phased implementation plan

- **P0 — Diet + install (quick win).** Add the package set to `settings.json`; author one
  lean `recon`/`specialist` profile; verify harness drop via Contextimate. *Immediate token win.*
- **P1 — Profiles + topology.** Author the role profiles (confirm `pi-subagents` schema
  first); wire Herdr tab/pane topology + `pi-rename-pane`.
- **P2 — Advisor + review.** Configure `pi-advisor-flow` (executor/advisor models, gates);
  set up the reviewer cross-model gate + escalation.
- **P3 — SDD + fan-out.** Wire punkfl0w per-phase + Linear; add `pi-dynamic-workflows` for
  opt-in fan-out.
- **Learning checkpoint after each phase** — measure harness/token deltas, note surprises.

## 13. Risks & open questions

- **`pi-subagents` profile schema + `task_control` semantics** — confirm from docs in P1.
- **Extension interplay / harness creep** — `pi-subagents` + `pi-advisor-flow` +
  context-mode/OM/Pix tool overlap could re-inflate the harness. *This is the learning part;*
  measure per profile.
- **Model budget** — keep GPT usage sparing; Anthropic-first.
- Herdr 0.7.5 vs package expectations: acceptable (bleeding edge, expected).

## 14. Decisions log

- Composable stack on `pi-subagents` (not agent-fleet, not minimal DIY).
- `agents/*.md` profiles, user-owned, global + per-repo.
- Ladder: manager ⇄ principal (on-demand) → domain specialists → recon / reviewer.
- Dynamic Anthropic-first tiers; default cheap, escalate on consequence; principal allocates.
- Topology: clean manager tab 1; one tab per active work item; split panes within.
- punk = opt-in, per-phase, worktree-per-phase.
- No `/plan` in Pi → drive phases via a `todo` implementation plan.
