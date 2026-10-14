# pi-extensible-workflows ("piewf") — architecture & philosophy brief

Repo: `/home/kuba/dev/oss/pi-extensible-workflows` (upstream `github.com/vekexasia/pi-extensible-workflows`), HEAD `6a75c52` (2026-10-14), version **6.2.1**.
Purpose: comparison baseline vs pi-herdsman.

Evidence tiers used below: **[code]** verified in source/tests, **[docs]** stated in README/docs/CHANGELOG only, **[inferred]** my reading, **[observed]** seen on this machine on 2026-10-14.

---

## 0. TL;DR

- piewf is a **deterministic, journaled, resumable JavaScript workflow engine** for Pi, plus a simpler **durable standalone-subagent** tool family. Main agent *writes a script*; the host executes it in a sandbox and journals every effectful operation for replay.
- **All child agents run in-process** in the parent Pi process as Pi SDK sessions (`createAgentSession`), not separate `pi` processes — except when `@piewf/herdr` swaps the transport to launch a real `pi` CLI in a Herdr pane.
- Heavy on contracts/validation: strict settings, frozen prepared configurations, identity versions, ceilings, typed error codes. ~21k LOC core src, ~23k LOC tests, 54 tags, multiple releases/week, two "breaking" majors/minors in Oct 2026.
- Roles were **moved out of core** in 6.1.0 into the separate `@piewf/pi-ext-roles` Pi extension. On this machine that extension is **not enabled as a Pi package** (see §8) — likely a live config gap.

---

## 1. Core philosophy / design goals

- Tagline: "Deterministic, resumable multi-agent workflow orchestration for Pi." **[docs]** `README.md:3`
- **Script-as-plan**: the main model writes a JS workflow (`parallel`, `pipeline`, `agent`, `withWorktree`, `checkpoint`, `shell`, `tools.*`, `evidence`). Orchestration logic is code, not LLM turns. **[docs]** `packages/core/skills/pi-extensible-workflows/SKILL.md`
- **Determinism via identity + journal**: each `agent()` call gets a hidden call-site + occurrence identity; `parallel`/`pipeline` keys are structural identities. Completed agent/shell/function/checkpoint/tool ops are journaled (`journal.json`) and **replayed** on retry/resume instead of re-run. **[docs]** SKILL.md "Agent calls are unnamed…", **[code]** `packages/core/src/store.ts:75-92`
- **Durability first**: runs persisted with atomic writes (`io.ts`, `store.ts` `atomicJson`); session leases detect dead owners via `/proc/<pid>/stat` start time (`src/session-lease.ts`). Interrupted runs reconcile to `interrupted`/failure on next manager start. **[code]**
- **Honest about exactly-once**: "A host crash after an external effect and before journaling can repeat that effect." `shell()` should be for gates/verification, not mutations. **[docs]** `docs/llm.md` "Registered functions", developers guide §shell.
- **Trust/ceiling model**: workflow JS is sandboxed; functions/hooks/transports/extensions are trusted host code. Children can never exceed parent tool/skill/extension ceilings; project settings ignored when project untrusted. **[docs]** `AGENTS.md` "Boundaries", `docs/llm.md` "Resource selectors".
- **Context management**: workflow runs do **not** inherit the main agent's conversation ("Workflow run does not inherit any of the main agent context" — SKILL.md Rules). Results returned to the parent are size/context-window gated (inline vs descriptor, §4.6). User message to each agent is exactly the supplied prompt (6.2.1 removed wrapper headers). **[docs]** CHANGELOG 6.2.1.
- **Two tiers of delegation**: "Use ordinary tools for work one agent can finish; use `subagents_run` for one independent delegated task. Use `workflow` for orchestration." **[docs]** SKILL.md "Default path".
- Extensibility as a first-class goal: `registerWorkflowExtension()` with functions, dynamic model aliases, settings validators, preparation hooks, setup hooks, attempt actions. **[docs]** `docs/llm.md` "Create an extension".

---

## 2. Model-facing tools & primitives

### 2.1 Workflow tools (main session) — `packages/core/src/host.ts:62`
`INTERNAL_WORKFLOW_TOOLS = ["workflow","workflow_respond","workflow_stop","workflow_status","workflow_resume","workflow_retry","workflow_catalog"]` **[code]**

| Tool | What it does |
|---|---|
| `workflow` | Launch run: `name` + exactly one of `script`/`scriptPath`, `args`, `foreground?` (default background), `budget?`, `parentRunId?` (borrows named worktrees only). Static preflight (`validation.ts`) checks models/tools/options before any effect. Prompt snippet `host.ts:119`. |
| `workflow_catalog` | Lists registered functions + model aliases; `{name}` for full detail. `readOnlyHint`. |
| `workflow_status` | Read-only compact summary for a runId across sessions in the project (state, delivery, budget/usage, agent shims, no transcripts). `readOnlyHint`. |
| `workflow_retry` | Replays a **failed** run into a linked child run; completed ops replay, incomplete re-execute. `expectedState` guard. |
| `workflow_resume` | Continue `budget_exhausted` (or paused) run with budget patch; relaxing budget → `awaiting_approval` proposal. |
| `workflow_respond` | Answer a checkpoint or budget proposal (`host.ts:851` delivers "Respond with workflow_respond"). |
| `workflow_stop` | Stop by exact runId; cancels descendants, persists `stopped`. |

Run states: `queued, running, pausing, paused, awaiting_input, budget_exhausted, completed, failed, stopped, interrupted`. **[docs]** developers guide.

### 2.2 Workflow script globals — `packages/core/src/execution.ts:368`
`agent, agent.create/handle.send, shell, withWorktree, prompt, checkpoint, parallel, pipeline, phase, log, tools, evidence, args` + registered catalog functions as globals. **[code]**
- `agent(prompt, opts)` → bare value; child must call `workflow_result` exactly once (one repair prompt built in). `outputSchema` for structured results.
- `agent.create({name})` → persistent handle; `send()` keeps transcript across turns.
- `tools.<name>(args)` → calls a parent-session tool directly via `ctx.executeTool()` (codemode semantics, journaled; not inside `withWorktree`). Added 5.19.0.
- `evidence(value)` → stores text/JSON under run `evidence/`, returns `{ref, sha256, path, bytes}` (PR #319 "workflow evidence offloading"; `store.ts:808-817`).
- `checkpoint()` → human approval pause (`awaiting_input`).
- `shell(cmd, {env})` → trusted host RPC, returns `{exitCode, stdout, stderr}`; journaled after exit.

### 2.3 Tools inside workflow children — `packages/core/src/agent-execution.ts`
`workflow_result` (`:1178`), plus nested-delegation tools `agent` ("Child Agent", `:1628`), `get_subagent_result` (`:1645`), `steer_subagent` (`:1651`). Children can spawn children (one-shot result collection, `:1539`); nested children keep parent's structural scope under own identity. Pi built-ins `codemode`, `tool-search`, `mcp` are loaded into children (5.18.0, `:361-363`). **[code]**

### 2.4 Standalone subagent tools — `packages/core/subagents/src/index.ts:75-128`
| Tool | Contract |
|---|---|
| `subagents_run` | `prompt` required; `mode` background (default, returns `{id,state:"running"}`) or foreground (terminal envelope). Options: `label, model, skills, extensions, tools, excludeTools, contextFiles, role, worktree, outputSchema, retries, timeoutMs` + arbitrary JSON plugin opts. |
| `subagents_inspect` | No id → current-session summaries (`scope:"all"` for all); with id → progress, activity, accounting, tools, worktree, output. `readOnlyHint`. |
| `subagents_steer` | Message to running id; up to 16 queued. |
| `subagents_stop` | Abort, persist `stopped`, clean worktree. |
| `subagents_retry` | Fresh run (new id, original mode) from failed/stopped; does **not** restore old conversation. |
States: `running, completed, failed, stopped`. **[docs]** `docs/subagents.html`.

### 2.5 Slash commands / prompts
- `/workflow` (`src/host-navigator.ts:909`) — TUI navigator/dashboard; actions, `/workflow trajectory`.
- `/subagents` (`subagents/src/navigator.ts:625`) — same dashboard layout for standalone runs.
- Starter prompt templates `packages/core/starter/prompts/`: `/scout, /parallel-scout, /oracle, /council, /review, /parallel-review, /review-loop, /deep-research` — thin prompts that call `subagents_run`/`workflow` with `role: "<name>"` (e.g. `scout.md`: `subagents_run` + `role:"scout"` + foreground). **[code]**
- Starter extension `packages/core/starter/index.ts`: registers `reviewLoop` function (persistent developer handle + fresh reviewer per iteration) and dynamic aliases `reviewer-model, developer-model, scout-model, oracle-model, researcher-model` (all resolve to root model by default). **[code]**

### 2.6 Codemode exposure
Setting `codemodeTools: "all"|"read-only"|"none"` controls which workflow/subagent tools Pi codemode scripts may call (`src/settings.ts:113-149`). Tools declare `outputSchema` → `structuredContent`. **[code]**

---

## 3. Role system

**Core does not implement roles (since 6.1.0, 2026-10-08).** **[docs+code]**
- `role` is forwarded as opaque JSON; without a preparation hook declaring it in `optionsSchema`, unknown options fail with `INVALID_METADATA` (6.1.0 Fixes: "Agent options that no such preparation hook declares… fail with INVALID_METADATA instead of being ignored"). Note `docs/roles.html` still says "role is opaque data and has no effect" — **docs drift / contradiction**; I did not verify which one runtime enforces for `subagents_run`. **[docs, conflicting]**
- `grep pi-ext-roles packages/core/src packages/cli/src` → no hits. **[code]**
- Roles owned by independent `@piewf/pi-ext-roles` (≥0.2.0), enabled as a Pi extension; it plugs in via generic `agentPreparationHooks` (`optionsSchema` + `prepare(configuration, context)`). **[docs]** `docs/llm.md` "Generic agent preparation", `docs/roles.html`.
- Role file locations (owned by roles pkg): `~/.pi/agent/pi-ext-roles/{settings.json,roles/}` (i.e. `<agentDir>/pi-ext-roles/…`) and trusted project `.pi/pi-ext-roles/{settings.json,roles/}`. Legacy `<agentDir>/pi-extensible-workflows/roles/` ignored. **[docs]** CHANGELOG 6.1.0 Migration.
- Frontmatter (owned by roles pkg; example from user's `impl.md`): `description, model (alias ok), tools (minimatch selector list), overrideSystemPrompt, contextFiles, skills`, body = prompt appended via Pi's structured append channel (replace only when `overrideSystemPrompt: true`). Extensions selector also supported. **[observed + docs]**
- Selection: explicit `role: "<name>"` per call; no auto-routing. Starter prompts encode routing ("task routing in starter prompts, persona/resource policy in role files" — `AGENTS.md`). **[docs]**
- Inheritance/precedence of resource policy: built-in defaults → global settings → trusted project settings → preparation hooks (roles) → call-level selectors → setup-hook narrowing (narrow-only). Last matching selector wins; `!*` clears. Children bounded by parent ceilings; extension options (incl. `role`) **not inherited** by child agents. **[docs]** `docs/llm.md`.
- `pi-role <role>` CLI (roles pkg) launches native Pi with role defaults, no workflow.
- `packages/core/starter/roles/*.md` (developer, oracle, researcher, reviewer, scout) still ship in core but are **not referenced by core source** (only legacy tests/evals reference old paths) — appears vestigial; CHANGELOG says "The five fallback roles belong to the independent package." **[inferred]**
- Frozen configuration: prepared config (model, plugin instructions, selectors, context scopes, settings) persisted per operation/handle identity before session creation; retry/resume reuse it without re-running role resolution; removed capabilities → `RESUME_INCOMPATIBLE`. Skill/AGENTS bytes and extension code are re-read, not frozen. **[docs]**

---

## 4. Child execution model

### 4.1 Where children run
- **Workflow script**: forked Node child (`execution.ts:524-526` writes `child.cjs`, `fork(...)`), script run in `vm.createContext` with `codeGeneration: {strings:false, wasm:false}` (`:371-373`). No imports/fs/net/timers; host RPC for `agent`, `shell`, etc. RPC size-limited (`RPC_LIMIT_BYTES`). **[code]**
- **Agents** (workflow + standalone): **in-process Pi SDK sessions** in the parent Pi process: `createAgentSession({cwd, agentDir, modelRuntime, model, settingsManager, thinkingLevel, tools, customTools, extensionFactories, resourceLoader, sessionManager})` (`agent-execution.ts:481`). No `pi` subprocess. **[code]**
- **Herdr transport** (optional, §5): replaces transport with a real `pi` CLI in a Herdr pane.
- Transport abstraction: session contract = state, sync stats, progress subscription, prompt/steer/abort, idempotent dispose; persisted attempts store transport-neutral session refs. **[docs]** developers guide.

### 4.2 What the child sees
- Fresh session; no parent conversation. Prompt = exactly the supplied text; control text (retry/soft-budget notes) queued as separate steered message (`agent-execution.ts:912`). **[code+docs]**
- System prompt: Pi native by default; preparation hooks/roles can append or override.
- Context files: `contextFiles?: ("global"|"project"|"cwd")[]` filters Pi's discovered AGENTS files (`agent-execution.ts:189,228,407`); default = Pi's normal discovery. **[code]**
- Skills/extensions/tools: discovered via Pi `DefaultResourceLoader`, filtered by minimatch selectors and trust (project-scoped resources dropped if untrusted, `:161-162, :424-430`). Pi built-ins codemode/tool-search/mcp included unless `-builtin:` disabled. **[code]**
- `excludeTools`: exact names removed after preparation (6.1.0). Tool ceiling = parent session tools (incl. MCP tools reachable via codemode/tool_search).

### 4.3 Result return path
- Workflow children submit via `workflow_result` tool; prose isn't parsed.
- Workflow completion → `pi.sendMessage({customType:"workflow"}, {deliverAs:"followUp", triggerTurn:true})` (`host.ts:173`). **[code]**
- Standalone subagent completion → `sendMessage({customType:"subagents"}, {deliverAs:"steer", triggerTurn:true})` (`subagents/src/index.ts:176`). Docs: "Do not poll; call `subagents_inspect({id})` only when needed." **[code+docs]**
- Delivery gating `host-delivery.ts:160-183`: inline only if serialized result ≤ Pi `DEFAULT_MAX_BYTES` (~50KB) **and** `currentTokens + resultTokens + model.maxTokens ≤ contextWindow`; otherwise a **descriptor** (paths to run artifacts) is sent. Diagnostic lines capped 4KB (`DELIVERY_LIMIT_BYTES`). **[code]**
- Background-run widget below editor + transcript "receipts" when settled (`background-widget.ts`, `backgroundWidget` setting).

### 4.4 Concurrency
- `concurrency` 1–16, default 8; workflow agents queue in call order. **[docs]** `docs/llm.md`.
- Standalone subagents: **no launch queue** — when limit full, `subagents_run`/`retry` fail with `AGENT_FAILED`. **[docs]** subagents.html.

### 4.5 Worktrees, budgets, retries, checkpoints
- `withWorktree(name, cb)`: deterministic owned branch/worktree from launch repo `HEAD`; **launch tree must be clean**; parallel branches need separate names; registered functions inherit scope. Subagent `worktree` option likewise (`subagents/src/worktree.ts`); cleanup on settle/stop; failed cleanup retained. **[docs+code]**
- Budget dims: `tokens, costUsd, durationMs, agentLaunches`, each `{soft?, hard?}` (`src/budget.ts`). Launch limits checked pre-dispatch; others between model turns (final overshooting response accepted). Exhaustion → `budget_exhausted`, resumable. **[code+docs]**
- Retries: per-agent `retries` (same run), `workflow_retry` (replay to child run), `subagents_retry` (fresh). `timeoutMs` per attempt.
- Checkpoints: `checkpoint()` → `awaiting_input` → `workflow_respond`.
- Pause/resume via `/workflow`, Trajectory; cold resume after restart via persisted snapshot.

### 4.6 Persistence locations — `packages/core/src/paths.ts:39-42`, `store.ts:44-92`
- Workflow runs: **`~/.pi/workflows/projects/<projectKey>/sessions/<sessionId>/runs/<runId>/`** — note hardcoded `homedir()/.pi/workflows`, *not* `PI_CODING_AGENT_DIR`. Files: `snapshot.json, journal.json, state.json, summary.json, ownership.json, worktrees.json, borrowed-worktrees.json, system-prompts.json`, `evidence/`. **[code]**
- Subagents: `<agentDir>/subagents/<id>/` (`subagents/src/index.ts:161`): normalized request, frozen prepared config, mode, status, result. **[code]**
- Workflow-agent Pi session JSONL with `pi-workflows:tool-timing` entries per tool. **[docs]**
- Retention: `retention.{olderThanDays,maxTerminalRuns}` best-effort at session start, terminal runs only (`src/retention.ts`).
- [observed] this machine: 32 project dirs under `~/.pi/workflows/projects`, 241 entries in `~/.config/pi/agent/subagents`.

### 4.7 Programmatic events
`pi.events`: `WORKFLOW_RUN_STARTED/RESUMED/STATE_CHANGED/COMPLETED/FAILED`, `AGENT_STATE_CHANGED`, `PHASE_CHANGED`, `CHECKPOINT_STATE_CHANGED`, `BUDGET`, `WORKTREE_CREATED` — in-process, best-effort, metadata only (no prompts/results). **[docs]** developers guide.

---

## 5. `@piewf/herdr` (`packages/extensions/herdr/index.ts`, 751 LOC, 0 tests in pkg dir; tests at `packages/extensions/herdr/test/`)

- Registers **no model-facing tools**. Registers `agentAttemptActions` (`openSession` "Open session in Herdr pane", `openLiveSession` "Open live session in Herdr pane") and `agentSetupHooks.fullyInspectable` (`index.ts:695-725`). **[code]**
- Inert unless Pi runs inside a Herdr-managed pane. **[docs]**
- **Live handoff**: pause local SDK session at turn boundary, open same session file in a Herdr pane (real `pi` CLI), bridge custom tools back over socket, generated bridge reports `agent_settled`; pane closes and local session resumes. **[docs]** `docs/herdr.html`.
- **Completed-session inspection**: open persisted completed/failed/cancelled attempt in pane, restricted tools, no ownership.
- **Fully inspectable mode** (`extensionSettings.herdr.enableFullyInspectableMode: true`): every workflow agent launches as `pi` CLI in a dedicated Herdr workspace per run (label `workflow <name>`, `index.ts:316-330`). Command built with `PI_CODING_AGENT_DIR`, `PI_EXTENSIBLE_WORKFLOWS_SETTINGS_FILE`, `PI_EXTENSIBLE_WORKFLOWS_HERDR_OWNER=1`, `--model`, `--no-extensions --extension …` allow-list, `--approve/--no-approve` trust flag, prompt via `@file` (`index.ts:300-305`). **[code]**
- Preserves executable/entrypoint, session file, model/thinking, tools, prompts, context files, skills, extensions, trust, worktree cwd. **[docs]**
- Limitations: Herdr screen detection can't tell aborted vs completed turn; Ctrl-C isn't handback; lifecycle reports advisory when Herdr's own Pi integration has authority. Applies to **workflow agents**; `docs/llm.md` frames it as workflow-agent integration (standalone subagents get actions only via `visibleStandalone/runStandalone` if the action opts in). **[docs]**
- [observed] user has `enableFullyInspectableMode: false`.

---

## 6. Observability

- **Trajectory** (`packages/core/trajectory/`, ~4.7k LOC incl. subagents src): local HTTP+WS server on `127.0.0.1:7432` (`trajectory/src/server.ts:605`), browser UI with run Gantt of model/tool events, transcripts, agent details (prompt/tools/skills/extensions/env/output), steer/stop/retry/pause/resume/checkpoint controls; standalone subagents shown in `SUBAGENTS` section. Auto-attaches (no browser open) after first launch; `/workflow trajectory` opens. Startup mutex/lock with `/health` (`trajectory/src/startup-mutex.ts`). Recent work (Unreleased) is all Trajectory perf fixes (WS frame copying, state re-encoding). **[code+docs]**
- Export: `piewf export`, sample run report `docs/run.html`; `PIEWF_SHARE_VIEWER_URL` env. **[code]**
- **No OpenTelemetry** in this repo (`grep -i otel|opentelemetry` → none). Children only get OTel if a Pi extension like `pi-otel` is selected into them (user's selector does include `**/pi-otel/**`). **[code+observed]**
- Evidence offloading: `evidence()` + descriptor-based completion delivery keep big outputs on disk (§2.2, §4.3).
- TUI: `/workflow` navigator (tree, cost, tokens, elapsed per phase/function, stall warnings), background widget.
- `piewf doctor [--json] [--agent-options <json> --prompt …]`: settings, trust, resources, aliases, prepared agent inspection without contacting a model. `piewf inspect`, `doctor cleanup`. (`packages/cli/src/cli.ts:646-704`) **[code]**

---

## 7. Maturity, size, complexity, sharp edges

### Size (wc, `*.ts` excl. node_modules/dist)
| Area | LOC |
|---|---|
| core `src/` | 14,741 |
| core total non-test (src+subagents+trajectory+starter+evals+bench) | ~21,100 |
| core tests | ~23,400 |
| cli src / tests | 2,523 / 2,179 |
| herdr | 751 |
| all TS | ~50.8k |
Biggest files: `agent-execution.ts` 1,774 lines (131KB), `host.ts` 1,619 (128KB), `subagents/src/manager.ts` 1,497, `background-widget.ts` 1,497.

### Cadence
- 54 tags; v5.6.0 (2026-08-18) → v6.2.1 (2026-10-13); ~973 commits total (git commit dates look rewritten — earliest commit date 2026-09-23 is later than many tag dates, so trust tag dates, not commit dates). Releases often 2–4/week, several same-day patch bursts (5.16.0–5.16.3 on 2026-09-23). **[observed via git]**
- Primary author Andrea Baccega (862/973 commits). Bus factor ≈1. **[observed]**
- Breaking changes frequent: 6.0.0 (10-07) and 6.1.0 (10-08, "breaking in a minor… explicit operator choice, not SemVer-compliant"); 5.18/5.19 breaking too. Runs persisted before 6.1.0 **cannot be resumed/retried**. **[docs]** CHANGELOG.
- Peer dep `@earendil-works/pi-coding-agent >=0.99.0`; tightly coupled to Pi SDK internals (session manager, resource loader, codemode).

### Sharp edges / limitations
1. **Determinism burden on the author model**: no imports/timers/fs in scripts; call-site identity rules (calls from one site must not race outside `parallel/pipeline`); handles can't `send` across scope boundaries; `workflow_result` must be called exactly once.
2. **In-process children**: a crash/OOM of the parent Pi process takes every running child with it; standalone subagents are not reconnected after restart (reconciled to interruption failure; retry starts fresh). **[docs]**
3. **Not exactly-once**: shell/function/tool effects can repeat if crash before journal.
4. **Worktrees require clean launch tree** (`WORKTREE_FAILED`); concurrent agents in one worktree share mutable files.
5. **Subagent concurrency cap fails rather than queues** (`AGENT_FAILED`).
6. **Strict settings**: unknown keys/invalid JSON fail launch/resume; `extensions.herdr` legacy key rejected; project `extensionSettings` replaces global map wholesale.
7. **Frozen config + identity versions**: upgrades can invalidate resumability (`RESUME_INCOMPATIBLE`).
8. **Roles split**: extra package to install/enable; starter slash prompts use `role:` and depend on it. Docs contradict on whether unknown `role` is ignored or `INVALID_METADATA`.
9. **Persistence path split**: runs under hardcoded `~/.pi/workflows`, subagents under `<agentDir>/subagents`, settings under `<agentDir>/pi-extensible-workflows/` — `PI_CODING_AGENT_DIR` doesn't move run storage.
10. **Herdr**: aborted vs completed turn indistinguishable; advisory lifecycle; workflow-agent-focused.
11. Large surface/complexity for a model to learn: workflow DSL + 7 workflow tools + 5 subagent tools + nested `agent/get_subagent_result/steer_subagent` + slash commands; skill file is 168 lines of rules.

---

## 8. Config surface

### Settings files
- Global: `<agentDir>/pi-extensible-workflows/settings.json`; trusted project: `<cwd>/.pi/pi-extensible-workflows/settings.json`. **[docs+code]** `src/settings.ts:14`
- Allowed keys (`src/settings.ts:113`): `concurrency` (1–16, def 8), `modelAliases`, `skills`, `extensions`, `extensionSettings` (e.g. `herdr.enableFullyInspectableMode`, `trajectory.port`), `tools`, `retention` {`olderThanDays`,`maxTerminalRuns`}; global-only: `backgroundWidget` (def true), `codemodeTools` (`all|read-only|none`). Note `docs/llm.md` omits `codemodeTools` from its "exactly" list — doc drift.
- Global aliases also appear in `/model` as virtual `workflow/<alias>` models (5.18.0).
- Pi package filters to disable bundled parts: `-dist/starter/index.js`, `-dist/subagents/index.js`, `-dist/trajectory/index.js`.
- Roles pkg (separate): `<agentDir>/pi-ext-roles/{settings.json,roles/}`, `.pi/pi-ext-roles/…`.
- Changelog marker: `<agentDir>/pi-extensible-workflows/changelog-state.json`.

### Env vars (grep `process.env` across core/cli/herdr)
`PI_CODING_AGENT_DIR` (agent dir; Herdr reads settings there), `PI_CODING_AGENT_SESSION_DIR`, `PI_OFFLINE`, `PI_WORKFLOW_TRAJECTORY_PORT` (overrides trajectory port), `PIEWF_SHARE_VIEWER_URL`, `NO_COLOR`, `TERM`, `PATH`; Herdr launch sets `PI_EXTENSIBLE_WORKFLOWS_SETTINGS_FILE`, `PI_EXTENSIBLE_WORKFLOWS_HERDR_OWNER`. **[code]**

### Per-agent options
`label, model (provider/model:thinking or alias[:thinking]), contextFiles, skills, extensions, tools, excludeTools, outputSchema, retries, timeoutMs` + arbitrary JSON plugin options (`role`, `advisor`, …).

### Observed on this machine (2026-10-14) — likely config gap, verify
- `~/.config/pi/agent/settings.json` packages: `npm:pi-extensible-workflows` 6.2.1 and `npm:@piewf/herdr` 6.2.1 only. **`@piewf/pi-ext-roles` is not a Pi package** (it is installed globally via pnpm 0.2.0, providing `pi-role` CLI, and existed under `~/.config/pi/agent/npm/node_modules/@piewf/` in btrbk snapshots of 2026-10-08/09 but not now).
- `<agentDir>/pi-extensible-workflows/settings.json` **does not exist**; the user's aliases (`workhorse, strong, sota, sota-openai, review-openai, cheap-model`), skill/extension selectors and herdr setting live in `<agentDir>/pi-ext-roles/settings.json` (symlink → dotfiles). Roles (`comms, dev, impl, planner, recon, researcher, reviewer, tests`) in `<agentDir>/pi-ext-roles/roles/`.
- Implication [inferred, unverified]: in the current Pi session core sees default workflow settings only, and `role:` options are either ignored or rejected depending on which doc is right — roles/aliases/selectors likely **not applied**.
- `piewf doctor --json` (global pnpm `@piewf/cli` 6.2.0) **crashes**: `SyntaxError: The requested module '@earendil-works/pi-codemode/declarations' does not provide an export named 'MCP_TYPESCRIPT_PREAMBLE'` — CLI's bundled Pi deps mismatched, so I could not verify the effective config.

---

## 9. Key file index
- `README.md`, `AGENTS.md` (code map), `CHANGELOG.md`, `RELEASING.md`
- `docs/llm.md` (config/extension contract), `docs/{developers,subagents,herdr,roles,extensions}.html`
- `packages/core/skills/pi-extensible-workflows/SKILL.md` (model-facing workflow rules)
- `packages/core/src/host.ts` (tool registration, delivery), `execution.ts` (sandbox worker), `agent-execution.ts` (SDK sessions, nested tools), `store.ts`/`paths.ts` (persistence), `settings.ts`, `budget.ts`, `host-delivery.ts`, `session-lease.ts`, `herdr.ts`
- `packages/core/subagents/src/{index,manager,navigator,worktree}.ts`
- `packages/core/trajectory/src/{index,server,startup-mutex}.ts`
- `packages/core/starter/{index.ts,review-loop.ts,prompts/,roles/}`
- `packages/extensions/herdr/index.ts`, `packages/cli/src/cli.ts`
