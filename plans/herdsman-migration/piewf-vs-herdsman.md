# piewf vs pi-herdsman: decision brief and migration plan

Date: 2026-10-14. Author: pi main session (cwd ~/dev/oss). Synthesizes three recon briefs in this directory; moved here from `~/dev/oss/.research/`:

| Brief | Covers |
|---|---|
| [`piewf.md`](piewf.md) | pi-extensible-workflows 6.2.1: architecture, tools, roles, execution, config |
| [`herdsman.md`](herdsman.md) | pi-herdsman 0.26.0: architecture, tools, definitions, execution, config |
| [`current-setup.md`](current-setup.md) | Inventory of the current pi setup: packages, roles, steering, extensions, skills, telemetry, history |

Every claim in this file traces to evidence (file:line) in one of those briefs. Nothing here was built or
run except reads, a few `grep`s, and `wc`. Items marked **VERIFY** are unconfirmed.

---

## 0. TL;DR

1. **The current piewf setup is degraded right now.** piewf 6.1 moved roles into a separate
   `@piewf/pi-ext-roles` package. That package has **two install modes**, and only one is present here:
   - `npm|pnpm install -g` provides the standalone **`pi-role` launcher**, which starts one native pi with a role.
     This one *is* installed (pnpm global 0.2.0, `~/.local/share/pnpm/bin/pi-role`).
   - `pi install npm:@piewf/pi-ext-roles` provides the **Pi extension**, whose preparation hook makes
     `subagents_run({role})` / `agent(..., {role})` work. Its README says: "For workflows, enable this Pi extension
     explicitly alongside workflows … The independent library and `pi-role` CLI do not require workflows."
     This one is **not** in `settings.json`.

   As a result:
   - Roles, model aliases, and tool/extension selectors are not being applied. Every child runs on the main
     model (opus/high) with the full main toolset. The three recon children that produced these briefs did
     exactly that.
   - piewf 6.2.1 also removed the `Workflow: …\nAgent: …` prompt header. That silently broke Logfire role
     attribution and punk-steering's `isSubagent()` fallback.
   - Role skill selectors (`cock-*`, `logfire-query`, the disabled `punk-sdlc`/`swap-*` skills) match nothing
     on this host.

   Whichever way the decision goes, something has to change.
2. **Herdsman fits the direction you gravitate to.** It is Herdr-native, visible, and built on ownership.
   Its features line up almost exactly with the *accepted losses* from the Aug-25 pi-subagents → piewf
   migration (`~/dotfiles/plans/piewf-subagents-migration.md`):

   | Accepted loss in the piewf move | Herdsman feature |
   |---|---|
   | Visible-terminal agents | Every agent is a real `pi` in its own Herdr pane |
   | `subagent_resume` follow-ups | `continue_agent` on the saved session |
   | `lead` nesting impossible | `agents:` allowlist gives one level of delegating agents, plus the Manager→Lead tier |
   | Children survive parent exit | Separate processes, re-bound after restart |
   | Automatic roster | `agent_definitions` is injected at start, and `list_agents` refreshes it |

   It also covers what `multi-repo-ticket` and `punk-resume/manager-mode` hand-roll with `herdr_agent`: the
   Manager's `delegate_project` uses branch worktrees and durable assignments.
3. **What Herdsman lacks is the piewf workflow engine.** It has:
   - no deterministic JS workflows, no budgets, no checkpoints, no structured `outputSchema`;
   - no blocking "run and wait" call;
   - no per-call model override;
   - no concurrency cap;
   - no OTel.

   Children are heavier: each is a full TUI pi with its own startup and its own extensions. The only saved
   workflow, `pr-principal-review.js`, runs about weekly and is always triggered by hand. **Decided:** rewrite it as a
   Herdsman-driven skill (Phase 6). It can be lost if needed, so piewf is removed entirely.
4. **Recommendation: run a time-boxed trial (about 1 week) of Herdsman as the only delegation system.**
   - Remove piewf and `@piewf/herdr` completely. No hybrid, no package filter, and no two delegation tool sets at once.
   - This is not a fair fight yet: today's piewf is misconfigured. A cheap control arm (repair piewf in about 1 h,
     §1.2) makes the comparison honest. At minimum, judge Herdsman against a *repaired* piewf, not the
     broken one.
   - Run the pre-trial verification checklist (§4) and put the runaway-cost guards in place (§3.7) before day 1.
   - The switch is cheap and reversible: punk-steering already gates rules on tool presence, so the
     delegation briefing flips automatically.
5. **Both projects carry similar maturity risk.** Each is single-author, agent-assisted, and shipping several
   releases a week with breaking minors. piewf has about 54 tags and broke on 6.0 and 6.1 in Oct. Herdsman is
   5 weeks old, with 55 tags and 7 breaking releases. Herdsman has more tests (~963 cases, 3-OS CI, live smoke
   harness). piewf has more mechanism, so there is more to break.

---

## 1. Philosophies side by side

| Axis | piewf | Herdsman |
|---|---|---|
| Core idea | **Script-as-plan.** The model writes a deterministic JS workflow, the host journals and replays it. Standalone `subagents_*` is the "simple tier". | **Ownership graph.** "Each unresolved unit of work has one executor." Pi owns conversations, Herdr owns processes/panes/worktrees, Herdsman connects them. |
| Where children run | In-process Pi SDK sessions inside the parent pi. `@piewf/herdr` can move a session to a pane, opt-in. | A separate interactive `pi` per agent, in its own Herdr pane (`herdr agent start --kind pi`). |
| Parent/child coupling | Parent crash kills all children. Standalone runs are not reconnected. | Independent processes. After a restart they are re-bound only on an exact identity match, otherwise `unknown`/`lost` (fail-closed). |
| Waiting | Background (steer-wakes-turn) **or** `mode: "foreground"` blocking. | Async only. The parent must not poll. Results wake the owner's turn exactly once. |
| Context in → child | Prompt only. `contextFiles` filter. Resource selectors with globs. | `task` + an explicit `files` channel (inline ≤128 KiB, else path refs). `inheritProjectContext` / `inheritGlobalContext` booleans. |
| Context out → parent | Inline when it fits in window and ~50 KB, else a descriptor. `evidence()` offloads. | Persisted result, delivered as `result:<label>#<n>` refs that can be forwarded without re-summarizing. |
| Child context limit | Normal compaction. | **Context retirement.** Threshold auto-compaction is cancelled and the agent must hand off. Retired sessions cannot be continued. |
| Nesting | Workflow children can spawn children. Standalone subagents cannot nest. | Lead → delegating agent → leaf, plus Chief → Manager → Lead supervision. Leads can message peers. |
| Worktrees | `withWorktree()` / subagent `worktree`. Requires a clean tree. | Only at the Manager→Lead level (`delegate_project {branch}`). Plain agents share the caller's cwd. |
| Guardrails | Budgets (tokens/$/time/launches), checkpoints, ceilings, frozen configs, `RESUME_INCOMPATIBLE`. | Fail-closed identity, a completion gate (a delegator cannot finish with open children), health attention messages, a 600 s bash cap in agents. |
| Prompt design | A 168-line skill with DSL rules. The model must learn a DSL plus 12+ tools. | "Structure over instruction": verb-first tools, an `available_tools` list per record, a roster-agnostic contract. But it is large: `SKILL.md` is 510 lines and a runtime contract is injected everywhere. |
| Observability | Trajectory web UI (Gantt, transcripts, controls), `/workflow` and `/subagents` navigators. No OTel. | `/herdsman` menu, a widget, `/herdsman stats` (tokens and $ across the owned tree), `inspect_agent` / `read_agent_transcript`. Panes can be watched live. No OTel. |
| Extensibility | `registerWorkflowExtension` (functions, aliases, hooks, transports). | Deliberately thin. Optional integrations go over an event-bus bootstrap (≤64 KiB). Memory, tools, and providers are out of scope. |
| Remote | — | A Docker/Tailscale SSH agent box you attach to as a remote Herdr machine. |

**Fit with your stated preferences** (simplicity, Herdr-first, visible work, manager/ticket model,
fail loud): Herdsman wins on visibility, durability across restarts, and nesting. It also fails closed by
design, which matches "fail loud". piewf wins on deterministic pipelines, budgets, and cheap lightweight
fan-out. Your usage is interactive and conversational: 241 standalone runs (recon 51, dev 49,
researcher 37, reviewer 30, impl 28, comms 24, tests 11, planner 3) against one saved workflow. That
profile favours Herdsman's model.

### 1.1 Reversing the August decision: do its reasons still hold?

The Aug-25 reasons for moving pi-subagents → piewf come from `plans/piewf-subagents-migration.md`:

| Aug reason | Still true? | Herdsman |
|---|---|---|
| One config surface (roles + workflows together) | Weaker. Since 6.1, roles are a separate package with a separate settings file. | One surface (`agents/*.md` + `pi-herdsman/config.json`). But it has no workflows, so keeping piewf for workflows means two surfaces again. |
| "Focus on piewf, user contributes to it" | Still true. A soft/social reason. | Leaving piewf costs you the contributor relationship and upstream influence. |
| Kill pi-subagents' "parent idle while child runs" batch-barrier bugs | Herdsman is async with turn-wake and a completion gate. No batch barrier. | OK by design. Verify in the trial. |

Budgets, the concurrency cap, foreground runs, and `outputSchema` were **not** among the stated Aug reasons. They came
bundled with piewf. They look essentially unused in standalone runs (**VERIFY**: grep
`~/.config/pi/agent/subagents/*/request.json` for `outputSchema` / `budget` / `foreground`).

The trade is therefore lopsided toward Herdsman *for interactive delegation* and toward piewf *for
pipelines*. Honest accepted losses: Trajectory, foreground, the cost guardrails, and contributor status.

### 1.2 Control arm: what "repair piewf" costs (~1 h)

1. `pi install npm:@piewf/pi-ext-roles`, and add it to `settings.json`.
2. Fix the role skill selectors: `cock-*` → the current names (`tdd`, …). Drop `logfire-query` and the disabled skills.
3. punk-steering `isSubagent()`: piewf children have no unique env marker (**VERIFY**). Fallback is the
   tool-absence check alone, which is already the primary signal.
4. Attribution: piewf no longer prefixes prompts. Re-add a role marker via a preparation hook, or use the run
   `label` if pi-otel can see it (**VERIFY**).

If you want a real A/B, run piewf on some days and Herdsman on others.

---

## 2. Gap analysis: what you use today and what happens to it

| Current capability (piewf) | Herdsman equivalent | Gap / action |
|---|---|---|
| `subagents_run({role, prompt})` background | `delegate_agent {definition, task, label, files}` | Direct. |
| `mode: "foreground"` | none | Gone by design. Brief: "end turn or do independent work". |
| `subagents_inspect` / `steer` / `stop` / `retry` | `list_agents`, `inspect_agent`, `read_agent_transcript`, `steer_agent`, `interrupt_agent`, `close_agent`, `continue_agent` | Superset. `continue_agent` is a real follow-up, which piewf lacked. |
| Concurrency 8, `AGENT_FAILED` over cap | Unlimited | Pane/tab churn and cost risk. Enforce by steering: say "≤4 parallel". |
| Model aliases (`workhorse`, `strong`, `sota`…) | Literal `model` + `thinking` per definition | Inline the literal ids. There is no alias layer. Note that `pi-task-models` and `advisor.json` already use literal ids. |
| Per-call `model` override | none | Make a definition per model variant when needed (e.g. `reviewer-sol`). |
| Tool selectors with `!*` + globs | `tools` closed allowlist (does it take `*` globs? **VERIFY**), `excludeTools` | Port the lists. MCP tools are name-matched. |
| Extension allowlist with globs (`**/pi-mcp-adapter/**`) | `noExtensions: true` + `extensions: [<path>]`, values passed unchanged to `pi --extension` | **Friction.** Needs concrete paths into `~/.config/pi/agent/npm/node_modules/...`. These break on reinstall layout changes. The alternative is to leave extensions on and restrict by `tools`. See §4.2. |
| Skill selectors | `noSkills` / `inheritSkills` / `skills: [path]` | Paths, not names. The `cock-*` names are already broken. Use explicit SKILL.md paths. |
| `contextFiles: []` / `["project","cwd"]` | `inheritGlobalContext` / `inheritProjectContext` | Direct. |
| `overrideSystemPrompt: true` | `systemPromptMode: replace` | Direct. Herdsman still appends its own contract and identity blocks. |
| `outputSchema` | none | Results are prose. Roles already return "paragraph + path". OK. |
| `worktree` option on subagent | Manager `delegate_project {branch}` → managed Lead in a worktree | Different shape. Herdsman rejects "dev subagent in a worktree"; it does Lead-per-branch instead. |
| `workflow` + `pr-principal-review.js` | none | **Decided:** port to a Herdsman-driven skill (Phase 6). |
| Trajectory UI | Herdr panes + `/herdsman` | Trajectory is lost. Live panes partly replace it. |
| Logfire role attribution (broken now) | Env `PI_HERDSMAN_AGENT_DEFINITION` (`agent-controller.ts:5776`), `PI_HERDSMAN_OWNER_SESSION_ID`, `PI_SUBAGENT_CHILD=1`, and `PI_SUBAGENT_PARENT_SESSION` (`herdr.ts:587-625`, set whenever an owner exists). Verified in source, not yet at runtime. | **Better.** Add them as resource/span attributes in your pi-otel fork. That gives role and parent linkage without prompt parsing. |
| punk-steering `isSubagent()` (broken now) | `PI_SUBAGENT_CHILD=1` / `PI_HERDSMAN_*` env | **Better.** Replace both heuristics with an env check. |

### Overlap with other installed extensions

| Package / local piece | Verdict under Herdsman | Why |
|---|---|---|
| `pi-extensible-workflows` | **Remove** (decided) | Delegation is replaced; the one workflow becomes a skill. |
| `@piewf/herdr` | **Remove** | Pane handoff for piewf agents. Moot. |
| `@piewf/pi-ext-roles` (pnpm global `pi-role` launcher only; Pi extension not enabled) | **Leave the launcher; optionally `pnpm rm -g` after go** | The Pi extension is needed only for a piewf rollback. |
| `@ogulcancelik/pi-herdr` | **Keep** | Herdsman has no generic pane/layout/run tools. punk-handoff, plannotator-tui, and terminal-browser need them. |
| `@henryqw/pi-herdr-btw` | **Keep** | Side threads ≠ owned agents. |
| `@henryqw/pi-herdr-rename` | **Test for conflict** | Herdsman renames Lead tabs to `Lead`/`Manager`/`Chief` when a tab name is numeric or canonical. If pi-herdr-rename writes tab names, they may ping-pong. The rename package probably wins after its first write, because Herdsman only touches numeric/canonical names (**VERIFY**). |
| `herdr-agent-state.ts` (Herdr integration) | **Keep (required)** | Herdsman injects it into every child. It is a symlink into dotfiles, so `herdr integration install pi` writes into the repo. Same as today. |
| `pi-advisor-flow`, `plannotator`, `pi-ask-user`, OM, context-mode, mcp-adapter, web-access, caveman | **Keep** | Out of Herdsman's scope. Decide per definition which load in children (§4.2). |
| `punk-steering` | **Keep, patch** | `isSubagent()` uses env. Rewrite `delegation.md`. Update role names in guards. |
| `context-nudge.ts` / `punk-handoff` | **Keep** | They apply to the Lead. Herdsman's context retirement covers agents. |
| `pi-lsp` empty-steer patch | **Keep** | Still relevant for agent sessions. |
| Skill `multi-repo-ticket` (disabled) | **Retire → Manager mode** | Same job: an executor per worktree that monitors and reviews. Herdsman makes it durable. |
| Skill `punk-resume/manager-mode.md` | **Rewrite mechanics** | Tracker logic stays. "Delegate to subagents" becomes `delegate_agent`; multi-branch work becomes `/manager` + `delegate_project`. Herdsman's "managed Lead" covers the "if launched with a brief you are never the manager" rule. |
| Skill `punk-sdlc` (disabled) | **Port later** | Dispatch `planner` via `delegate_agent`. Publish via `comms`. |
| Tool allowlist `config/custom/pi/webui/settings.json` | **Edit** | Swap the `subagents_*` / `workflow*` pins for the Herdsman tools (`delegate_agent`, `continue_agent`, `list_agents`, `steer_agent`, `interrupt_agent`, `reply_agent`, `close_agent`, `inspect_agent`, `read_agent_transcript`, `message_supervisor`, `list_peers`, `message_peer`, plus staff/manager tools). Drop the stale `herdr_start_worktree` and `ask_user_question`. |

---

## 3. Risks and open questions

1. **Token overhead.** Herdsman injects a large runtime contract into the Lead and every agent, and
   `SKILL.md` is 510 lines. Measure with contextimate in the trial. Your steering footprint is ~7.4 KB main and
   ~1.8 KB recon child today.
2. **Per-agent weight.** Each agent is a full pi start. If a child loads the full extension set, OM and the
   advisor run per child, which costs extra model calls. Disable them in child definitions.
3. **Async-only discipline.** No foreground mode. Your "third tool call = tripwire" style still works. A
   pattern like "dispatch 3, wait, synthesize" becomes "dispatch 3, end turn, results wake me". Since this
   session already worked that way, the change is minor.
4. **Fail-closed rough edges.** One malformed definition kills the whole roster. A build-hash mismatch after
   `pi update` forces restarting every running session. `unknown`/`lost` agents need a manual `close_agent`.
5. **Mac host.** The Lead must run inside a Herdr pane on the same machine, because sockets are per machine.
   Install Herdsman on the mac too. The tested baseline is Herdr 0.9.3 / Pi 1.1.0; this host runs Herdr 0.9.4 /
   Pi 1.2.0, so smoke-test on both. Container mode is optional and could become a remote agent box
   later.
6. **Bundled roster collisions.** Bundled `researcher` and `reviewer` share names with your roles. A global
   file with the same name *overlays* the bundled one, it does not replace it. Set `bodyMode: replace` and
   restate every field. Disable the bundled `scout`, `implementer`, and `generalist` via
   `enabled: false` overlays so the roster matches your routing.
7. **Runaway cost.** There is no budget and no concurrency cap, agents survive parent exit, and dev may nest.
   Nesting is bounded by design: agents spawned by agents are always leaves, and only definitions with
   `agents:` can delegate. Before day 1:
   - make `/herdsman stop` (kills the proven-owned tree) muscle memory;
   - set a Logfire spend alert, e.g. daily `pi.cost.usd` > $X;
   - add a "≤4 live agents" line to the steering rules;
   - end each day with `herdr agent list` to catch orphans.
8. **Cross-project peers.** The peer registry is user-global and spans Herdr sockets. Harmless, but
   expect peers from other projects to show up.

---

## 4. Migration plan

Phases are ordered. Each one ends at a checkable state. Rollback is in §5.

### Phase 0: prepare (≈30 min)

- [ ] btrbk snapshot / `git -C ~/dotfiles status` clean.
- [ ] Record a baseline before anything changes, for comparison:
  - contextimate breakdown of a fresh main session;
  - Logfire cost of one typical recon + dev dispatch (role attribution is broken, so use session ids).
- [ ] Open a Linear ticket in `KUB`: "Trial pi-herdsman as delegation layer". Branch/PR titles carry
  `KUB-n`.
- [ ] Fix the stale-doc drift found by recon regardless of outcome, as a separate commit:
  - `~/dotfiles/AGENTS.md:16,36` and `docs/reference/piewf-role-config.md` still point at
    `pi-extensible-workflows/roles/`;
  - `piewf doctor --role` no longer exists.

### Pre-trial verification (before Phase 1, each ≈5 min)

- [ ] ~~Package filter syntax~~: moot, because piewf is removed entirely (decision round 1).
- [ ] **Dotter template mechanics** for `agents/*.md` (§4.2). Run a dry run (`dotter -v -d`) on a single template definition, then
  check that `/herdsman definitions` reads the rendered file.
- [ ] **Child env.** Spawn one Herdsman agent and run `env | grep -E 'PI_(HERDSMAN|SUBAGENT)'`. Do the same for a
  managed Lead (`/manager` → `delegate_project`). This decides the `isSubagent()` predicate and the otel
  attributes. If the vars are missing, fall back to the `<active_agent name=…/>` system-prompt marker.
- [ ] Does `extensions:` accept a package source (`npm:pi-mcp-adapter`), or does it need a path (§4.2)?
- [ ] Does `tools:` accept globs (`repowise_*`)?
- [ ] pi-herdr-rename vs Herdsman tab naming: open one Lead and watch the tab title for 2 min. If they fight,
  resolve it before the trial, not during.
- [ ] Land the pi-otel env-attribute patch (Phase 4) **before** the trial. Without it you get no cost data.

### Phase 1: install side by side, delegation switched to Herdsman (≈1 h)

1. Add `"npm:pi-herdsman"` to `~/dotfiles/config/custom/pi/agent/settings.json` `packages`.
2. In the same file, remove `"npm:pi-extensible-workflows"` and `"npm:@piewf/herdr"`.
   Leave the global `pi-role` pnpm launcher alone; it is harmless. Uninstall it later if unused.
   Leave `pi-ext-roles/` and `workflows/` in dotfiles until the go decision, so rollback stays one step.
3. `herdr integration status`. Confirm the pi integration is current; it is already present at v8.
4. Restart pi inside Herdr. Check:
   - `/herdsman` opens;
   - `list_agents` shows the bundled roster;
   - `subagents_*` and `workflow*` are gone.
5. Because `delegation.md` is gated on `when.tools: [subagents_run]`, it now disappears from the prompt
   automatically. Confirm with `/steering`.

### Phase 2: definitions (port 8 roles) (≈2 h)

Location: `~/dotfiles/config/custom/pi/agent/agents/*.md`. That falls under the recursive dotter map
`config/custom/pi/agent → ~/.config/pi/agent`, so the files are live at `~/.config/pi/agent/agents/`. No dotter
edit is expected (**VERIFY** with `dotter -v -d`).

Field translation:

| piewf role field | Herdsman definition field |
|---|---|
| `description` | `description` |
| `model: workhorse` / `strong` / `sota` / `review-openai` | `model: anthropic/claude-sonnet-5-5` + `thinking: medium`, etc. (literal ids from `pi-ext-roles/settings.json` aliases) |
| `tools: ["!*", …]` | `tools: [ …explicit names… ]`. Expand `repowise_*` / `ctx_*` explicitly unless globs are supported. Drop `workflow_result`. |
| `skills: ["!*", "cock-tdd"]` | `noSkills: true` + `skills: [~/.agents/skills/tessl__tdd/SKILL.md]` (paths) |
| `extensions` selectors | §4.2 decision |
| `overrideSystemPrompt: true` | `systemPromptMode: replace` |
| `contextFiles: []` | `inheritProjectContext: false`, `inheritGlobalContext: false` |
| `contextFiles: ["project","cwd"]` | `inheritProjectContext: true`, `inheritGlobalContext: false` |
| body | Keep the persona and rules. **Delete** the `workflow_result` completion contract (Herdsman delivers the final turn). Add "if blocked, `ask_owner`" in place of `BLOCKED:` returns, or keep `BLOCKED:` as plain text, which also works. |
| (new) `agents:` | `dev: [recon, researcher, tests]`, `reviewer: [recon]`. Restores the "lead"-style nesting. Everything else stays a leaf. |

Role map:

| Current role | Definition | Notes |
|---|---|---|
| `recon` | `recon` (standalone) | Read-only tools + repowise + ctx_search. Disable bundled `scout` (`enabled: false` overlay). |
| `researcher` | `researcher` overlay, `bodyMode: replace` | Drop `source_check` (disabled in your web-search.json). Needs the web-access extension loaded. |
| `dev` | `dev` | `agents: [recon, researcher, tests]`. |
| `impl` | `impl` | Disable bundled `implementer`. |
| `tests` | `tests` | |
| `reviewer` | `reviewer` overlay, `bodyMode: replace` | Keep `sota` (fable). Herdsman's "internal review ≠ sign-off" framing fits "never signs off own work". |
| `comms` | `comms` | Needs mcp-adapter. |
| `planner` | `planner` | Fix skill paths. The `punk-sdlc` / `swap-*` skills are currently disabled, so leave them out until re-enabled. |
| (bundled) `generalist` | `enabled: false` | |

Done when `/herdsman definitions` lists exactly the 8 definitions, each with the correct source, and no
validation error.

#### 4.2 Decision: extensions in children

The constraint: `extensions:` values go to `pi --extension` unchanged, so they must be **paths**, not globs.

| Option | How | Pros | Cons |
|---|---|---|---|
| **A: explicit paths (recommended)** | `noExtensions: true` + `extensions:` with concrete paths for the 9 currently allowlisted packages (otel, rtk, fff, caveman, context-mode, advisor-flow, mcp-adapter, context-include, punk-steering) | Keeps today's lean children | Paths into `~/.config/pi/agent/npm/node_modules/<pkg>/<entry>` are brittle across package updates. Put them in one shared `@./_child-extensions.md`? No: `@` includes only affect the body, not the frontmatter, so list them per file or template with dotter. |
| B: inherit everything | Omit `noExtensions`, restrict by `tools` | Zero path maintenance | OM, pine-of-glass, plannotator hooks, herdr-rename, btw, learning-nudge, and repowise-augment all run per child. Cost, noise, and hook side effects. |
| C: dotter template | Template the definition files with a `{{child_extensions}}` variable | One SSOT for the path list | Reintroduces templating, which you removed in Aug. |

**Decided: C (dotter template).** `pi --help` confirms the constraint: `--extension, -e <path>`
accepts a file or `builtin:<name>`, and `--no-extensions` still honours explicit `-e` paths. So option A's paths have to live somewhere,
and a template gives you one SSOT for them.

Template design:

- **Source and mapping.** Sources go in `~/dotfiles/config/custom/pi/agent-definitions/<name>.md` (handlebars). Each
  file gets its own entry in `.dotter/global.toml`, like `"config/custom/pi/agent-definitions/recon.md" = { target =
  "~/.config/pi/agent/agents/recon.md", type = "template" }`. Alternatively, template the whole dir if dotter allows it (**VERIFY**).
  The sources sit *outside* `config/custom/pi/agent/`, so the recursive symlink map doesn't also deploy them raw.
- **Variables** live in `[base.variables]`, with per-host overrides in `.dotter/<host>.toml`:
  - `herdsman_ext_*`: one variable per extension entry path, e.g.
    `herdsman_ext_mcp = "~/.config/pi/agent/npm/node_modules/pi-mcp-adapter/<entry>"`.
    Take the entry from each package's `package.json` `pi.extensions`.
  - `model_workhorse` / `model_strong` / `model_sota` / `model_review_openai`: these **replace the piewf alias layer**,
    which Herdsman lacks. One SSOT, and `pr-review` can reuse them.
  - Optionally `child_extensions_lean`, a rendered YAML list partial shared by the read-only roles.
- **Costs:**
  - Edits need a `dotter deploy`, unlike today's live symlinks. That is the reason you dropped templating in Aug.
  - **Don't use the `/herdsman definitions` model/thinking editor.** It writes global override files, which collide
    with rendered templates. Change models via dotter variables instead.
  - Package entry paths can move on a package major version. Add a tiny check, e.g. a `local/bin/herdsman-defs-check`
    that greps every `herdsman_ext_*` path exists, or a punk-steering precondition probe on main sessions.
- **Absolute paths:** whether `--extension` expands `~` is unknown, so render absolute paths with `{{home}}`-style variables
  (**VERIFY** that dotter exposes a home variable, else define one per host).

### Phase 3: steering (≈1 h)

- [ ] **New `steering/delegation.md`**, gated `when.tools: [delegate_agent]`. Routing only: Herdsman's runtime
  contract already covers the mechanics (async, no polling, results wake the turn, steer/interrupt/close).
  Do not duplicate them; duplication also violates Herdsman's "one invariant, one meaning".
  - Keep:
    - main-model context is scarce;
    - the role routing table (recon / researcher / impl / dev / tests / comms / reviewer);
    - third tool call = tripwire;
    - salami-slicing warning;
    - "a child's summary is a claim, check the diff";
    - full briefs, because children see nothing.
  - Add:
    - pass evidence via `files` and refs, not re-summaries;
    - "≤4 parallel agents" (no cap exists);
    - follow-ups via `continue_agent`, not fresh agents, unless context was retired.
  - Delete the piewf API lines (foreground, `subagents_inspect`, `AGENT_FAILED`, no-resume).
- [ ] Rename the old file to `delegation-piewf.md.disabled`, or delete it. Git keeps the history.
- [ ] `guard-bash.md`, `guard-read-outside-repo.md`, `web-research.md`: role names stay the same (recon,
  researcher) if you keep your names. Only the wording "dispatch `recon`" carries over, which is fine.
- [ ] **punk-steering `index.ts` `isSubagent()`**: replace the herdr-tool-absence and `"Workflow: "` heuristics
  with
  `process.env.PI_SUBAGENT_CHILD === "1" || !!process.env.PI_HERDSMAN_AGENT_DEFINITION`.
  This matters: Herdsman children *can* have herdr tools, so the old check would classify them as "main" and
  run strike-3 → punk-handoff inside a child.
  - Add a resolver test.
  - Also check that managed Leads (Manager → Lead) count as main: they should get handoff, and they carry
    `PI_HERDSMAN_*` too. **VERIFY** which env vars a managed Lead receives versus a delegated agent, and
    branch on `PI_HERDSMAN_AGENT_DEFINITION` (agents only?).
- [ ] `linear-conventions.md` "manager, comms, workflows" wording: trivial.
- [ ] `multi-repo.md`: points to the disabled `multi-repo-ticket`. Rewrite it to "workspace root → `/manager`,
  `delegate_project` per repo/branch", or leave it until that skill is re-enabled.

### Phase 4: observability (≈1–2 h, in your fork `~/dev/oss/pi-otel`)

- [ ] Read `PI_HERDSMAN_AGENT_DEFINITION`, `PI_HERDSMAN_LABEL`, `PI_HERDSMAN_OWNER_SESSION_ID`, and
  `PI_SUBAGENT_PARENT_SESSION` at startup. Set them as resource attributes, e.g. `pi.agent.role`,
  `pi.agent.label`, `pi.parent.session.id`.
- [ ] Update the CTE in `~/dotfiles/docs/reference/logfire-pi-role-attribution.md` to
  `coalesce(attributes->>'pi.agent.role','main')`, and drop the regex on `pi.user_prompt`. This also fixes
  the attribution that is broken today.
- [ ] Optional: link the trace to the parent using the owner session id. Herdsman passes no `TRACEPARENT`
  to the pane process; check whether `herdr agent start` inherits the env.
- [ ] Ledger: add an experiment row to `docs/otel_retro/…experiments-ledger.md` covering cost per delegated
  task, piewf baseline vs Herdsman, and delegation volume.

### Phase 5: config hygiene (≈30 min)

- [ ] `config/custom/pi/webui/settings.json`: swap the pinned tools (§2 table) and drop the stale pins.
- [ ] `/herdsman` → Settings. Proposed: `spawnPlacement: subtree` (default, one tab per direct agent).
  Try `split` if tabs get noisy. Keep `contextRetirement: true` and `defaultLeadExecution: flexible`.
  The file `~/.config/pi/agent/pi-herdsman/config.json` is written by the UI. Leave it out of dotfiles
  for the trial, and adopt it into dotfiles as `type="template"` later if stable.
- [ ] Watch the `pi-herdr-rename` interplay for a day. If they fight, disable one side's tab writes.
- [ ] `.gitignore` in repos you work in: `.pi-herdsman/` (project-local scratch; Herdsman says untracked).

### Phase 6: `pr-principal-review.js` → skill `pr-principal-review` (≈1–2 h, decided)

Usage is about weekly and always manual, so a skill is enough. It lives at
`~/dotfiles/config/custom/agents/skills/pr-principal-review/SKILL.md` and deploys to `~/.agents/skills`.

**Definitions** (all templated, §4.2). There is no per-call model override, so you need one definition per model:

| Definition | Model | Tools / notes |
|---|---|---|
| `reviewer` | `{{model_strong}}` | read-only + `bash` for `gh pr diff` |
| `reviewer-sol` | `{{model_review_openai}}` | same body as `reviewer`, shared via `@./_reviewer-body.md` (`@` includes are valid in the body) |
| optional `reviewer-sota` / `reviewer-sota-openai` | | only if you keep the `sota` flag |
| `arbiter` | `{{model_sota}}` | read + write; writes `reviews/PR-<n>-review-<A>-vs-<B>.md` |

**Procedure** (skill body, executed by the Lead):

1. Resolve the PR/base and the diff.
2. `delegate_agent` `reviewer` and `reviewer-sol` in parallel with the same brief: principal-level,
   high-priority findings only, ending with `FINDINGS: <n>`. End the turn.
3. Once both results arrive, run up to `rounds` debate rounds. In each round, `continue_agent` each side,
   passing the other side's result ref in `files`. Each side marks every finding AGREE / CONTEST /
   MAINTAIN / WITHDRAW and answers `CONSENSUS: yes|no`. Stop early when both say yes.
4. `delegate_agent arbiter` with all result refs in `files`. It writes the report and returns a verdict
   plus its top 3 findings.
5. The Lead relays the report path. It does **not** re-review.

**Delta vs the workflow:**
- Lost: determinism and replay. The Lead counts the rounds itself.
- Gained: each reviewer runs in its own pane, so you can watch the debate live.
- **Context-retirement risk:** a reviewer that retires mid-debate cannot be continued. The skill must handle
  that case by starting a fresh reviewer with the prior result ref plus the other side's ref.

This also stands in for piewf's `/review`, `/parallel-review` and `/review-loop` starters.

### Phase 7: skills and docs (≈1 h)

- [ ] `punk-resume/manager-mode.md`: change the delegation verbs to `delegate_agent`. Multi-branch work
  goes through `/manager` + `delegate_project`. Keep the tracker rules.
- [ ] `multi-repo-ticket` (disabled): mark it superseded by Herdsman Manager mode in its README, or delete it.
- [ ] `punk-sdlc` (disabled): when re-enabled, swap `subagents_run`/`agent("planner")` for
  `delegate_agent planner`.
- [ ] Docs:
  - `~/dotfiles/AGENTS.md`: replace the "When editing agent roles" section with the Herdsman definitions path
    and schema link.
  - `docs/reference/piewf-role-config.md` → `docs/reference/herdsman-agent-definitions.md`.
  - `CONTEXT.md`: add Lead / Agent / Manager / Chief / herd terms, avoiding the "subagent" and "role" overloads.
- [ ] **ADR 0005: "Delegation layer: pi-herdsman over piewf".** No ADR covers this today; the rationale is
  spread over `plans/`. Record context, the accepted losses (foreground, budgets, Trajectory, workflows), and
  the restored capabilities.

### Phase 8: mac host

- [ ] Same settings (shared via dotfiles). Run `herdr integration install pi` on the mac.
- [ ] Run the smoke tests (§6) there. Remember `hm()` / sockets per machine: a Lead on Linux cannot own agents
  on the mac.

---

## 5. Rollback

1. In `settings.json`: remove `npm:pi-herdsman`, restore `npm:pi-extensible-workflows` and
   `npm:@piewf/herdr`, and add `npm:@piewf/pi-ext-roles`. Adding the extension (the global `pi-role` launcher alone is not enough) fixes the roles regression too.
2. Restore `steering/delegation.md` from git and keep the env-based `isSubagent()` patch; it is harmless
   under piewf.
3. Close the running agents (`/herdsman stop`), then `rm -rf ~/.config/pi/agent/pi-herdsman/`.
   `agents/*.md` are inert without Herdsman.

---

## 6. Trial acceptance checklist (decide at end of week)

**Functional**
- [ ] `delegate_agent recon` from the main session. The result wakes the turn, and the pane closes after.
- [ ] A recon child has exactly its tools:
  - `repowise_*` and `ctx_search` work;
  - no `edit`, no `bash`;
  - punk-steering briefings are present (check `/steering` in the child pane);
  - `isSubagent()` is true, so there is no handoff on strikes.
- [ ] `dev` delegates `recon` (nested), and the completion gate holds.
- [ ] `continue_agent` on a finished dev gives a follow-up with its context intact.
- [ ] Restart the main pi mid-run. The agent re-binds, or shows as `unknown` and can be closed.
- [ ] `/manager` from the primary workspace with `delegate_project` on 2 branches. Worktrees are created and
  the Leads appear. Compare against the old `multi-repo-ticket` flow.
- [ ] Logfire shows `pi.agent.role` per child session, and cost attribution works.

**Economics** (compare to the Phase 0 baseline)
- [ ] Main-session system prompt delta from the Herdsman contract. Acceptable threshold: **you decide**,
  e.g. ≤ +5 KB.
- [ ] Cost and latency per typical recon dispatch: separate pi plus extension startup, against in-process.
- [ ] Pane/tab noise is tolerable (`spawnPlacement`).

**Go/no-go**
- Go:
  1. Delete `pi-ext-roles/` and `workflows/` from dotfiles, and optionally `pnpm rm -g @piewf/pi-ext-roles @piewf/cli`.
  2. Write ADR 0005.
  3. Promote this file into `~/dotfiles/plans/`.
- No-go: roll back (§5). The `pi-ext-roles` install fixes today's regression.

---

## 7. Decisions log

### Round 1 (2026-10-14)

| # | Question | Decision |
|---|---|---|
| 1 | piewf workflows | Run about weekly, always by hand. **Rewrite as a Herdsman skill** (Phase 6). **piewf is removed entirely**; no hybrid. |
| 2 | Child extensions | **C: dotter template** (§4.2). The template variables also carry the model ids, which replaces the piewf alias layer. |
| 3 | Definition naming / roster | **Open. Separate decision, needs more detail.** Likely a combination of your names, tools, extensions and system prompts with the Herdsman bundled defs. See §7.1. |
| 4 | Manager mode | Correct: it is a **runtime mode**. `/manager` from a Lead in a Herdr *primary* workspace claims the lease, and `/manager leave` drops back to Lead (`autoActivateManager: false` by default). Nothing to decide up front. Retire `multi-repo-ticket` and rewrite the mechanics in manager-mode.md after the first real `/manager` use. |
| 5 | pi-ext-roles | **Partly right.** The global pnpm install exists, but it only provides the `pi-role` launcher (a separate native pi with a role). Applying `role:` inside `subagents_run` / workflows needs the **Pi extension** (`pi install npm:@piewf/pi-ext-roles`; README: "enable this Pi extension explicitly alongside workflows"). That is not in `settings.json`. Runtime evidence: this session's recon children ran on `claude-opus-5-5` / high with the full main toolset (`herdr_*`, `plannotator_submit_plan`). Moot now that piewf is going; relevant only for rollback. |

### Round 2 (2026-10-14): roster, part 1

| # | Question | Decision |
|---|---|---|
| 6 | Plan files | Committed (`6bc30c8`). `plans/` is gitignored; force-added like the earlier plans. |
| 7 | Names | **Keep all 8 of your names** (`recon`, `researcher`, `dev`, `impl`, `tests`, `reviewer`, `comms`, `planner`). Disable bundled `scout`, `implementer`, `generalist` via `enabled: false` overlays. |
| 8 | `researcher` / `reviewer` collision | **Overlay with `bodyMode: replace`**, restating every field. |
| 9 | System prompt + context | **1:1 with today.** `systemPromptMode: replace`, `inheritProjectContext: false`, `inheritGlobalContext: false` for recon, researcher, impl, reviewer, comms, planner. `append` + `inheritProjectContext: true` + `inheritGlobalContext: false` for dev, tests. |
| 10 | Delegation edges | **`dev: [recon, researcher, tests]` only.** Everyone else, `reviewer` included, is a leaf for the trial. |

### Round 3 (2026-10-14): roster, part 2 (extensions, tools)

| # | Question | Decision |
|---|---|---|
| 11 | Base extension partial | `pi-otel`, `pi-fff`, `context-mode`, `pi-mcp-adapter`, `pi-context-include`, `punk-steering`, `@gotgenes/pi-anthropic-auth`, `pi-multi-account`. **`pi-rtk-optimizer` dropped**: no measured savings and it causes issues. Per-role adds as today: `pi-web-access` for researcher and planner, `ponytail` for dev. |
| 12 | Caveman | It's for the Lead/Manager you talk to. **Off in all children** (agent call): child output is evidence the Lead reads, and dropping it removes the per-role exception. |
| 13 | Advisor in children | **Keep `pi-advisor-flow` in all 8 for now.** Herdsman's own escalation is `ask_owner` (the user's "ask_parent"); it asks the direct owner and must be the final call. Revisit after the trial: advisor vs `ask_owner` overlap. |
| 14 | Local extensions | Add `bash-output-guard` to bash-capable roles and `context-events` to all children. `repowise-augment` and `pi-lsp` stay out. |
| 15 | Tools | 1:1 port with the `repowise_*` / `ctx_*` globs. Drop `workflow_result`. `dev` gets the `agent` sentinel. |

### Round 4 (2026-10-14): roster, part 3 (models, skills, escalation)

| # | Question | Decision |
|---|---|---|
| 16 | Models | **Dotter variables as the alias layer, with short `provider/family` values** that pi resolves to the newest model at launch. Runtime test (`pi -p --mode json --model "<p>"`): `anthropic/sonnet` → `claude-sonnet-5-5`, `anthropic/opus` → `claude-opus-5-5`, `anthropic/fable` → `claude-fable-5-1`, `openai-codex/sol` → `gpt-6.1-sol`. Bare `sonnet` → `openai-codex/gpt-5.6-terra`, so the **provider prefix is mandatory**. Herdsman passes a pinned `model` through unchanged (`agent-definitions.ts:791`). `thinking` is a separate field. Accepted: a new release silently changes the model, which Logfire's model attribute shows. |
| 17 | Skills | 1:1 to paths, dropping dead ones (`logfire-query`, `punk-sdlc`, `swap-*`). dev: tdd, codebase-design, mcp-scripting. tests: tdd, mcp-scripting. researcher: research, mcp-scripting. planner: research, domain-modeling, codebase-design, mcp-scripting (no `grilling`: a child can't interview the user). impl: none. Others: mcp-scripting. |
| 18 | Escalation | **Delete the `BLOCKED:` convention from the bodies.** Use the `ask_owner` rule from Herdsman's contract. Trial it and revisit if it is awkward. |

Facts found while preparing round 3:

- Herdsman `tools` accepts `*` globs (schema, `herdsman.md` §Fields). Still confirm at runtime.
- piewf child allowlist entry `**/pi-claude-auth/**` matches **no installed package**. Anthropic auth comes from
  `@gotgenes/pi-anthropic-auth` (`./src/index.ts`) and `pi-multi-account` (`./index.ts`). Under `noExtensions: true`
  with an explicit `anthropic/*` model, children may fail to authenticate unless these load (**VERIFY**).
- Extension entries (under `~/.config/pi/agent/npm/node_modules/`): `pi-otel/dist/index.js`,
  `pi-rtk-optimizer/index.ts`, `@ff-labs/pi-fff/src/index.ts`, `pi-caveman/extensions/caveman.ts`,
  `context-mode/build/adapters/pi/extension.js`, `pi-advisor-flow/dist/index.js`, `pi-mcp-adapter/index.ts`,
  `@d3ara1n/pi-context-include/src/index.ts`, `@dietrichgebert/ponytail/pi-extension/index.js`,
  `pi-web-access/dist` (a **directory**: check `--extension` accepts it, else `dist/index.js`). punk-steering is
  local: `~/.config/pi/agent/extensions/punk-steering/`.
- Skill paths: `tdd`, `codebase-design`, `research`, `domain-modeling`, `grilling` → `~/.agents/skills/tessl__<name>/SKILL.md`;
  `mcp-scripting` → `~/.config/pi/agent/npm/node_modules/pi-mcp-adapter/skills/mcp-scripting/SKILL.md`.
  `logfire-query` is **not installed**.

### 7.1 Open: definition roster design (next round)

### Round 5 (2026-10-14): roster, part 4 (template layout)

| # | Question | Decision |
|---|---|---|
| 19 | Template location | **In-map**: `config/custom/pi/agent/agents/<name>.md`, each with a per-file `type = "template"` entry in `.dotter/global.toml` (the `lsp.json` precedent). This supersedes the separate `agent-definitions/` dir in §4.2. The disabled bundled defs (`scout`, `implementer`, `generalist`) are plain files in the same dir. |
| 20 | Variables | New `[base.variables]`: list variables `ext_base`, `ext_web`, `ext_ponytail`, `ext_bash_guard`, `ext_context_events` (entries relative to `~/.config/pi/agent/`), rendered as `{{home_dir}}/…` via `{{#each}}`, plus `model_workhorse`, `model_strong`, `model_sota`, `model_review_openai`. `home_dir` already exists per host. Add `local/bin/herdsman-defs-check` to check that every rendered path exists. A `dotter -d` dry run on one definition comes first. |

### 7.1 Resolved roster (summary of rounds 2–5)

| Definition | Base | Model / thinking | systemPrompt / context | Extensions (beyond `ext_base`) | Skills | `agents:` |
|---|---|---|---|---|---|---|
| `recon` | standalone | workhorse / low | replace / none | context-events | mcp-scripting | — |
| `researcher` | overlay, `bodyMode: replace` | strong / high | replace / none | web, bash-guard, context-events | research, mcp-scripting | — |
| `dev` | standalone | strong / high | append / project | ponytail, bash-guard, context-events | tdd, codebase-design, mcp-scripting | recon, researcher, tests |
| `impl` | standalone | workhorse / medium | replace / none | bash-guard, context-events | — | — |
| `tests` | standalone | workhorse / medium | append / project | bash-guard, context-events | tdd, mcp-scripting | — |
| `reviewer` | overlay, `bodyMode: replace` | sota / high | replace / none | bash-guard, context-events | mcp-scripting | — |
| `comms` | standalone | workhorse / medium | replace / none | bash-guard, context-events | mcp-scripting | — |
| `planner` | standalone | strong / high | replace / none | web, context-events | research, domain-modeling, codebase-design, mcp-scripting | — |
| `scout`, `implementer`, `generalist` | overlay | `enabled: false` | | | | |

- `ext_base`: pi-otel, pi-fff, context-mode, pi-mcp-adapter, pi-context-include, punk-steering, pi-anthropic-auth,
  pi-multi-account, pi-advisor-flow. No rtk, no caveman.
- `inheritGlobalContext: false` everywhere. Tools are ported 1:1 with globs, `workflow_result` is dropped, and dev
  gets the `agent` sentinel.
- Bodies: drop the `workflow_result` contract and `BLOCKED:`. Use `ask_owner` for escalation.

### Round 6 (2026-10-14): execution order

| # | Question | Decision |
|---|---|---|
| 21 | Order | Phase 0 → Phase 2 templates with a `dotter -d` dry run (before the install) → pi-otel patch → Phase 1 install plus runtime checks → Phase 3 → trial. |
| 22 | pi-herdr-rename | The user is unhappy with it anyway. **Remove `npm:@henryqw/pi-herdr-rename` in Phase 1**, so the conflict check is dropped. |
| 23 | `isSubagent()` | Correction to Phase 3: the tool-absence check already classifies our 8 definitions correctly, because their `tools:` lists exclude `herdr_*`. The real gaps are a definition without a `tools:` list, and **managed Leads**: they would run punk-handoff into a pane Herdsman doesn't own. The `Workflow:` branch is dead. Open: managed Leads → subagent behaviour on strikes? Land in Phase 3? |

### Progress (2026-10-14)

- KUB-171 created. Doc drift fixed (`8270b29`).
- **pi-otel patch**: fork branch `punk-dev-robot/pi-otel@feat/KUB-171-herdsman-agent-attrs` (`35328bc`, based on upstream
  0.3.0; 35/35 tests). Phase 1 swaps `"npm:pi-otel"` for the `git:` source of that branch. The old fork branch
  `feat/thinking-dropped-attr` is not included. Logfire doc now reads `otel_resource_attributes->>'pi.agent.role'` (`53ff7e2`).
- **Finding: managed Leads get no env vars.** `delegate_project` starts the Lead via `startHerdrAgentInPane`
  (`lead-runtime.ts:6966`) with no `--env`; only `--session-id <assignment.id>`. Delegated agents get
  `PI_HERDSMAN_*`, `PI_SUBAGENT_CHILD=1`, and `PI_SUBAGENT_PARENT_SESSION` (`agent-controller.ts:5767-5781`, `herdr.ts:587-620`).
  Consequences: managed Leads read as `main` in Logfire, and `isSubagent()` cannot tell them apart by env.
- Logfire MCP routes are swapped: `logfire-swap` = personal org (`kuba-gaj`/`coding-agent`, pi data), `logfire` = work org.
  The user will swap the auth caches later.
- **Baseline** recorded in [`baseline.md`](baseline.md), with SQL you can rerun. Over 14d (7 days with data): children cost
  $130 against $178 for main sessions, so 42% of spend. Over the last 3d it's 59%, because children have run on opus since ~Oct 8.
  First-turn input for a fresh main session: p50 39k, p90 52k tokens.
- **Correction to §0:** the `Workflow: …` prompt prefix is **still present** through Oct 14 (baseline query). What broke
  is that roles stopped being applied (between Oct 2 and Oct 8), not the prefix. So `isSubagent()`'s `Workflow:` fallback still works under piewf
  today. It only becomes dead once piewf is removed.
- **Phase 2 definitions are deployed but inert until install.** 11 files in `config/custom/pi/agent/agents/` plus `[base.variables]`
  in `.dotter/global.toml` plus `local/bin/herdsman-defs-check`. Herdsman's own parser (run from a /tmp copy) accepts all 11.
  `dotter deploy` and the check pass (103 paths). Deviations from §7.1:
  - `reviewer` sets `agents: []`. The bundled reviewer delegates to the disabled `scout`, and overlays inherit unset
    fields, so without it the definition fails to resolve.
  - The bodies of recon, planner and comms were fixed: recon has no inherited AGENTS.md, punk-sdlc is disabled, and "workflow" wording is gone.
  - Correction to §4.2: global definitions load from `getAgentDir()/agents` = `~/.config/pi/agent/agents/`.
  - Not verified: rendering for mac, and runtime acceptance of `--extension`/`--skill` paths, child auth and tool globs (Phase 1).
- **Smoke test** (`pi -e npm:pi-herdsman` in a separate Herdr pane, settings untouched; `-e` takes package sources):
  - **Blocker found and fixed:** the `/tools` allowlist (`config/custom/pi/webui/settings.json`) disables new static tools, so
    the Lead had Herdsman's prompt but no tools. Added the 21 Herdsman tool names. The Phase 5 pin swap is partly done; the piewf
    pins stay until removal.
  - **Bug found and fixed:** Herdsman skips symlinked definitions (`readdir` + `entry.isFile()`, `agent-definitions.ts:159`),
    so the `enabled:false` overlays deployed as symlinks were silently ignored. They're now `type = "template"` (real copies). Verified:
    the 3 are listed as disabled and `delegate_agent scout` is rejected. Worth an upstream issue: no warning is shown.
  - Passed: `recon` gets exactly its tools plus `ask_owner`, repowise works, no edit/bash. `impl` session file shows
    `claude-sonnet-5-5`/`medium`, so short model ids and `thinking` take effect. Children launched with no path/auth/model errors,
    so the `noExtensions` + explicit-paths children authenticate. Both were cleaned up after finishing.
  - Child env, verified at runtime: `PI_HERDSMAN_AGENT_DEFINITION`, `_LABEL`, `_OWNER_SESSION_ID`, `_RUN_ID`, `_MAILBOX`,
    `_WORKSPACE_ID`, `_OWNER_DISPLAY`, `_ALLOWED_AGENT_DEFINITIONS`, `PI_SUBAGENT_CHILD=1`, `PI_SUBAGENT_PARENT_SESSION`, `PI_OFFLINE=1`.
  - Not yet tested: nested dev→recon, `continue_agent`, restart re-bind, `/manager`, researcher web tools, mac.
- **Format test, all 8 definitions** (live `delegate_agent` per definition, with the real child command lines recorded from `/proc`):
  - Command lines match §7.1 exactly per definition: `--model`/`--thinking`, `--tools` (globs kept; Herdsman appends
    `ask_owner`, `mcp__`, and the delegation tools for dev), `--skill` paths, `--no-extensions` plus `-e` paths (Herdsman prepends its own
    agent extension and `herdr-agent-state.ts`).
  - Each command line, replayed headless (`pi -p`, sonnet/low): exit 0, no error/warn lines, so every extension and skill path loads.
  - Live tool lists match the definitions. The probes worked: ctx_search (recon), web_search (researcher), fetch_content (planner),
    repowise (reviewer), mcp status (comms, 14 servers), bash plus env (impl), skill path (tests). **Nested dev → recon works.**
  - Steering briefings arrive per tool set (punk-steering loads). No caveman anywhere. Ponytail active in dev
    (checked by replay: "PONYTAIL MODE ACTIVE — level: full").
  - **`mcp-scripting` is inert in children**: its frontmatter has `disable-model-invocation: true`, so pi loads it but never shows it
    to the model. The same was true under piewf. Open: drop it from the definitions?
  - Still untested: `continue_agent`, restart re-bind, `/manager`, mac.

### Round 7 (2026-10-14): scripting

| # | Question | Decision |
|---|---|---|
| 24 | `mcp-scripting` skill | Leave it hidden. Upstream made it manual-only (pi-mcp-adapter PR #478, merged 2026-09-01, `disable-model-invocation: true`); there is no setting to flip it. The `mcpScript` tool description covers the basics. |
| 25 | pi native codemode | **Keep pi-mcp-adapter and enable `codemode` everywhere.** Main: `"defaultTools": ["+codemode"]` in `settings.json` plus a `codemode` pin in the `/tools` allowlist. Children: `codemode` in every `tools:` list **and** `- "builtin:codemode"` in `extensions:`, because `--no-extensions` also drops pi's built-in extensions and Herdsman's `--tools` overrides `defaultTools`. Verified: main runs a script; a live Herdsman `recon` child runs a script whose `ALL_TOOLS` equals its allowlist, so codemode can't get around it. `herdsman-defs-check` skips `builtin:` entries. Native pi MCP stays off (`-builtin:mcp`). |
| 26 | MCP scope per definition | Accept for the trial: `mcp`/`mcpScript` reach every gateway server, so read-only roles are read-only by prompt only (as under piewf). Follow-up in Backlog: **KUB-172**. Tool globs are not the lever: codemode only sees the session's active tools. |
- **Phase 3 prepared (inert until install):**
  - `steering/delegation-herdsman.md`, gated on `delegate_agent`. The old `delegation.md` (gated on `subagents_run`) stays
    until the go decision; checked that each session gets exactly one of them.
  - `isSubagent()` moved into `resolver.ts` as a pure function: herdsman env → no herdr tools → `Workflow:` prefix.
    **The `Workflow:` check stays until piewf is removed**: today's piewf children have `herdr_*` tools (roles not applied),
    so that prefix is the only thing classifying them. Test 23/23; it fails when the env branch is removed.
  - Upstream issue drafts in `upstream/` (symlinked definitions skipped silently; managed Leads get no env). Not posted yet.
- **Upstream issues posted:** boadij/pi-herdsman#390 (symlinked definitions ignored), #391 (managed Leads get no env). Both offer a PR.
- **Phase 1 switched (2026-10-14):** `settings.json` adds `npm:pi-herdsman`; removes `pi-extensible-workflows`, `@piewf/herdr`,
  `@henryqw/pi-herdr-rename`; `pi-otel` now comes from `git:github.com/punk-dev-robot/pi-otel@feat/KUB-171-herdsman-agent-attrs`.
  - pi installs git packages with `--omit=dev`, so upstream's "build in `prepare`" (`7be94cc`) fails (needs husky and tsc).
    The fork branch commits `dist/` and sets `prepare: husky || true` (`c59e25c`). **Rebuild and commit `dist/` after any fork change.**
  - `ext_base` now points children at the git copy of pi-otel.
  - Phase 5: piewf tool pins (`subagents_*`, `workflow*`) and stale `herdr_start_worktree`/`ask_user_question` removed from the `/tools` allowlist.
- **End-to-end check with the real config** (fresh pi, no `-e`): no `subagents_*`/`workflow`; Herdsman tools and codemode present;
  only `delegation-herdsman` briefing loads; recon answered correctly; **`continue_agent` reuses the session**; Logfire shows
  `pi.agent.role=recon`, `pi.agent.label=e2e-recon`, `pi.parent.session.id` set. **Trial can start.**
- **Phase 6 done (`5ba27af`):** `reviewer-sol` (`{{model_review_openai}}`) + `arbiter` (`{{model_sota}}`, read+write, no bash);
  shared reviewer body in `agent-bodies/reviewer.md` via `@../agent-bodies/reviewer.md` (outside `agents/`: Herdsman parses every
  `*.md` there recursively). `herdsman-defs-check` checks body `@` refs (13 defs, 128 paths). Herdsman parser + headless replay pass
  (sol → `gpt-6.1-sol`, arbiter → `claude-fable-5-1`). Skill `pr-principal-review` is user-invoked. **Untested live** (Herdr run,
  `@` expansion at real launch, retired-reviewer path). Open: arbiter shares fable with `reviewer` (not model-neutral); `sota` flag dropped.
- **Phase 7 done (`9b0edf5`)** except ADR 0005 (waits for go). Findings: Manager scope = one git repo → cross-repo gap (**KUB-174**);
  managed Leads launch from bundled `managed-lead`, no overlay (**KUB-173**, blocks `/manager` test). CONTEXT.md: Lead, Agent,
  Agent definition, Manager (clash with punk's *manager mode* accepted).
