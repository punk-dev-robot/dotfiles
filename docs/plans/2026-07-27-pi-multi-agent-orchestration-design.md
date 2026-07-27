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
most work runs at haiku/sonnet; opus/fable is earned, not assumed.

| Tier | Model | When |
|---|---|---|
| **fast** | `claude-haiku-4-5` | recon, groundwork, routine coordination |
| **workhorse** | `claude-sonnet-5` | most specialist execution, most epic coordination |
| **deep** | `claude-opus-5` / `opus-4-8` | hard design calls, review gate, interactive default (`pi`) |
| **sota / ceiling** | `claude-fable-5` | **top Anthropic model, most expensive — above opus.** Principal, final architecture sign-off, deadlocks. Use sparingly. |
| _cross-model_ | `gpt-5.6-sol` | _sparingly_ — a different family's second opinion only |

Note: `claude-fable-5` is Anthropic's ceiling (not a cheap/fast model). Ladder cheap→expensive: `haiku-4-5` < `sonnet-5` < `opus-5` < `fable-5`.

### Role → model mapping (from community + our own use; tunable)

Philosophy the community converged on: **"best orchestration > best model."** Fable
plans/arbitrates with taste; cheaper models do the volume; a strong independent
critic loop catches bugs. Our mapping (jinn split is a *hint*, not a spec — we run
it Pi-native):

| Role | Launcher | Model | Why |
|---|---|---|---|
| orchestrator / principal / arbitrator | `pip` | `claude-fable-5` | plans, reads whole diffs, product/UI taste, breaks ties |
| manager / coordination | `pim` | `claude-opus-4-8` ↔ `gpt-5.6-sol` | delegation + board; Ctrl+P cycles to the GPT family |
| implementer / dev | `pid` | `claude-opus-4-8` ↔ `gpt-5.6-terra` | follows instructions, good FE taste; Ctrl+P alt for cheap codegen |
| reviewer / QA | `piqa` | `openai-codex/gpt-5.6-sol` | cross-family critic, 1.1M context, browser QA via agent-browser |
| recon | `pir` | `claude-haiku-4-5` ↔ `gpt-5.6-luna` | cheapest read-only groundwork; Ctrl+P alt |

(↔ = primary model + a Ctrl+P-cyclable alternate via `--models`, for mid-session family switching.)
| default | `pi` / `pif` | settings default (`opus-4-8`) | full session |

Budget: ~$2k Anthropic vs ~$400–500 GPT — GPT-Sol is the reviewer seat (bounded by
risk threshold/stop condition), not the volume worker, to keep GPT spend contained.

- **Budget bias:** ~$2,000 Anthropic (often extendable) vs ~$400–500 GPT → lean Anthropic;
  reserve `gpt-5.6-sol` for occasional cross-family review, not routine work.
- Each profile carries a **default tier + escalation ceiling**; the principal bumps a task
  up/down at runtime.

## 5. Agent profiles — `agents/*.md`

- **Global:** `~/.pi/agent/agents/*.md` · **Per-repo:** `.pi/agents/*.md` (both read by
  `pi-subagents`; profiles are owned by us, additive, no parent-prompt pollution).
- **Confirmed schema (pi-subagents):** frontmatter is minimal — `description` + `tools`
  (comma-separated allowlist); filename = `agent_type`; body = the agent's brief.
  Example: `.pi/agents/general.md` with `tools: read, grep, find, ls, bash, edit, write`.
- **Model tiering is NOT a profile field.** pi-subagents has no `model:` — a child inherits
  the parent's model. So horizontal tiering comes from **Herdr-direct `agent start -- --model <id>`**
  launches (or inheritance), and vertical tiering from **`pi-advisor-flow`** (executor/advisor
  models). The extension-diet lever is **`PI_TASK_CHILD_NO_EXTENSIONS=1`**.
- So a profile encodes **tools + prompt** (+ diet); model tier is layered at launch.

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
- **Critic loop (the core win):** Fable plans → implementer (`opus-4-8`/`luna`) builds
  → **`gpt-5.6-sol` reviews** (code + browser QA), optionally a second pass. A strong
  independent critic is what makes idea→polished-feature work with little babysitting.
- **Nobody signs off on their own work.** Implementer implements, GPT-Sol reviews,
  Fable arbitrates disagreement. The reviewer must pass before `task_control` ship.
- **Reviewer needs an explicit risk threshold + stop condition** in its brief, or
  GPT-Sol's edge-case diligence loops forever and burns budget. Stop when met; report.
- **Escalation:** if Fable can't resolve a disagreement within N turns → escalate to you
  with **both positions + attribution** (Herdr notification / `pi-ask-herdr`).

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

- **`task_control` semantics** — lifecycle (`status/handoff/verify/review/ship/metrics`)
  confirmed present; exercise them in P1/P2. Profile schema confirmed (§5).
- **Model tiering is not native to pi-subagents** (§5) — horizontal tiering needs
  Herdr-direct `--model` launches; validate the mechanism in P1.
- **Extension interplay / harness creep** — `pi-subagents` + `pi-advisor-flow` +
  context-mode/OM/Pix tool overlap could re-inflate the harness. *This is the learning part;*
  measure per profile.
- **Model budget** — keep GPT usage sparing; Anthropic-first.
- Herdr 0.7.5 vs package expectations: acceptable (bleeding edge, expected).

## 15. Operational notes (from P1 spike)

- **Agent profiles are discovered at `session_start`.** New/edited `agents/*.md` require a
  fresh Pi session before `Task(agent_type=...)` sees them (same as package installs).
- **pi-subagents runtime self-wires** via the package `pi.extensions` (`dist/task-runtime.js`);
  it registers the lowercase `task` + `task_control` tools. Do **not** hand-create
  `.pi/extensions/task.ts` — it conflicts (double-registers `task`/`task_control`) and can't
  bare-import the package anyway (managed pkgs live in `npm/node_modules`, off the default
  resolver). The `doctor` `runtime-wrapper-missing` / `packaged-runtime-drift` errors are
  **confirmed non-blocking** package-author advisories — delegation works without a wrapper.
- **CRITICAL profile gotcha:** an `agents/*.md` file must start with `---` on **line 1**.
  A leading `<!-- ... -->` comment (e.g. copied from the README's path annotation) pushes
  `---` off line 1, breaks the YAML frontmatter parser, and pi-subagents silently discovers
  **zero** profiles (`task` → "no agents available"). Fixed 2026-07-27; all 7 profiles now
  discover: `ai-eng, be-eng, devops, fe-eng, observability, recon, reviewer`.
- Discovery validated via `pi -p` (lists all 7 agent_types). A full spawn (recon writing its
  findings file in a Herdr pane) is best confirmed in a normal interactive session — nested
  `pi -p` foreground delegation hangs on the pane spawn and is not a valid test harness.

## 16. P2 — Advisor + review gate

**Advisor (`pi-advisor-flow`).** Config: Dotter-managed `~/.pi/agent/advisor.json`.
- `executor` **omitted** on purpose — each launcher's `--model` stays the executor; only the
  advisor + gates are global.
- `advisor: anthropic/claude-fable-5` (ceiling), `advisorEffort: high`. Cross-family option:
  switch to GPT-5.6-Sol via `/advisor-models` (confirm the exact provider id there).
- Gates: plan + failure + completion on; **auto-loop consult at 3** (matches escalate-after-N),
  **budget 5 calls/session** (cost guard), block-on-blocked, `gateFailureMode: block-session`.
- Privacy: `advisorRedactSecrets: true`, `advisorGitContext: summary` (never file contents),
  `deploy` tool output excluded.
- **`alwaysOn: false`** — opt-in per session with `/advisor` (avoids executor drift and advisor
  overhead on delegated children). Flip to `true` later if you want it always active.
- Enable per session: `/advisor` (uses the launcher model as executor). Principal sessions
  (`pip`, already fable) should override with a cross-family advisor: `/advisor advisor=<gpt-sol>`.

**Review gate.** Two paths:
- Same-family: delegate to the `reviewer` profile via `task`; gate with `task_control` `verify`
  → `review` (`reviewer_task_id`) → `ship`. Reviewer inherits the delegator's model.
- Cross-family (recommended for real critique): launch `piqa` (GPT-5.6-Sol) in its own Herdr
  pane, feed it the diff/worktree, and treat its verdict as the gate. Nobody reviews own work.

**Escalation.** Advisor auto-loop gate (3) + manager brief; on unresolved disagreement the
manager summarizes both positions with attribution and asks you (Herdr notification).

## 14. Decisions log

- Composable stack on `pi-subagents` (not agent-fleet, not minimal DIY).
- `agents/*.md` profiles, user-owned, global + per-repo.
- Ladder: manager ⇄ principal (on-demand) → domain specialists → recon / reviewer.
- Dynamic Anthropic-first tiers; default cheap, escalate on consequence; principal allocates.
- Topology: clean manager tab 1; one tab per active work item; split panes within.
- punk = opt-in, per-phase, worktree-per-phase.
- No `/plan` in Pi → drive phases via a `todo` implementation plan.
