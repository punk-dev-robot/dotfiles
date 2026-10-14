# Current pi setup inventory: subagents, delegation, context, steering, Herdr

Read-only inventory, 2026-10-14, Linux host (omarchy). The goal is to scope a migration from
**pi-extensible-workflows (piewf) to pi-herdsman**.
`~` = `/home/kuba`. Dotfiles SSOT = `~/dotfiles/config/custom/pi/agent/` (`~/.config/pi/agent/`
is mostly per-file symlinks into it: dotter recursive map `"config/custom/pi/agent" = "~/.config/pi/agent"`,
`.dotter/global.toml:29`). `PI_CODING_AGENT_DIR=$XDG_CONFIG_HOME/pi/agent` (`config/custom/zsh/.zshenv:25`).

---

## 0. Read this first: live breakages found during the inventory

1. **piewf roles are probably not being applied right now.** Installed `pi-extensible-workflows`
   and `@piewf/herdr` are **6.2.1** (installed 2026-10-14 09:51). The 6.1.0 CHANGELOG makes one
   explicit-only change: *"Roles are now interpreted only by the explicitly enabled optional
   `@piewf/pi-ext-roles` extension … Without the plugin, unknown agent options are opaque JSON and
   ignored."* `@piewf/pi-ext-roles` is **not** in `settings.json` `packages` and **not** installed:
   `~/.config/pi/agent/npm/node_modules/@piewf/` contains only `herdr/`.
   - Evidence: the 5 subagent runs from 2026-10-14 (`~/.config/pi/agent/subagents/<uuid>/request.json`)
     carry no `role` key. Their `configuration.json` shows the main model (`anthropic/claude-opus-5-5`, `high`),
     the full main toolset including `herdr_*` and `plannotator_submit_plan`, every skill, and `settings: {}`.
     The role/shared settings in `pi-ext-roles/settings.json` (extension allowlist, aliases) are therefore not
     being applied. Last run with a role: 2026-10-02.
   - Not verified: whether `subagents_run({role})` fails or silently drops the role, and whether
     `pr-principal-review.js` (model aliases `strong`/`sota`/`review-openai`) still resolves. The global CLI
     `~/.local/share/pnpm/bin/piewf` crashes on import (`pi-codemode/declarations` export
     `MCP_TYPESCRIPT_PREAMBLE` missing), so `piewf doctor` could not run.
2. **Logfire role attribution is broken by 6.2.1.** The CHANGELOG says: *"`agent(...)` and `handle.send(...)` now
   deliver the supplied text as the whole user message … The repeated Workflow/Agent/Phase/Parent header … are
   gone."* Attribution depends on that literal prefix (§7), and so does punk-steering's `isSubagent()` fallback (§3).
3. **Role skill selectors match nothing on this host.**
   - Roles select `cock-tdd`, `cock-codebase-design`, `cock-research`, `cock-grilling`, and `cock-domain-modeling`.
     Linux tessl skills are currently un-prefixed (`~/.agents/skills/tessl__tdd/SKILL.md` has `name: tdd`).
     `tessl-cock-prefix` was reverted by a tessl update.
   - `logfire-query` exists nowhere on this host.
   - `punk-sdlc`, `swap-linear`, `swap-project`, and `multi-repo-ticket` were moved to
     `config/custom/agents/skills.disabled/` today (commit `e52af39`, 2026-10-14). Steering rules
     `multi-repo.md` and `linear-conventions.md`, plus the `planner` role, still reference them.
   - Only `mcp-scripting` resolves, from `pi-mcp-adapter/skills/`.
4. **Docs are stale on role location.**
   - `~/dotfiles/AGENTS.md:16,36` and `docs/reference/piewf-role-config.md` still say
     `config/custom/pi/agent/pi-extensible-workflows/roles/`. The roles moved to `pi-ext-roles/roles/`
     in `fbc3c29` (2026-10-07).
   - The docs list 7 roles; there are now 8 (`planner` added in `6b01b49`).
   - The docs reference `piewf doctor --role`, which was removed in 6.1 (now `--agent-options <json>`).

---

## 1. Packages in `settings.json`

File: `~/dotfiles/config/custom/pi/agent/settings.json` (symlinked to `~/.config/pi/agent/settings.json`).
Versions are the installed ones in `~/.config/pi/agent/npm/node_modules`.
Also set: `"extensions": ["-builtin:mcp"]`.

| # | Package (ver) | Purpose | Tags |
|---|---|---|---|
| 1 | `pi-terminal-theme` 0.2.0 | ANSI-0..15 terminal theme | [ui] |
| 2 | `pi-vim` 0.14.2 | Vim modal editing in the TUI editor | [ui] |
| 3 | `@pi-kaush/pi-double-paste@0.1.0` | Paste twice to expand paste markers | [ui] |
| 4 | `pi-tool-display` 0.5.0 | Compact tool rendering/truncation; overrides `ls`,`bash` only (`extensions/pi-tool-display/config.json`) | [ui] [context-mgmt] |
| 5 | `pi-fancy-footer` 3.1.0 | Footer (config `fancy-footer.json`) | [ui] |
| 6 | `pi-image-tools` 1.4.0 | Image attach/render | [ui] |
| 7 | `pi-rtk-optimizer` 0.9.0 | RTK bash rewrite + output compaction (mode `rewrite`, truncate 12k, `extensions/pi-rtk-optimizer/config.json`); source of `rtk recall` hidden-output ids | [context-mgmt] |
| 8 | `pine-of-glass` 0.15.3 | contextimate (context breakdown), traceline, cachemire (cache warnings; `pi-cachemire.json`), meantime | [obs] [context-mgmt] [ui] |
| 9 | `pi-observational-memory` 3.1.4 | Observations/reflections + calibrated compaction trigger (180K), `recall` tool; model sonnet-5-5 low | [memory] [context-mgmt] |
| 10 | `@ff-labs/pi-fff` 0.11.0 | FFF fuzzy `find`/`grep` (PI_FFF_MODE=override) | [context-mgmt] [other] |
| 11 | `@dietrichgebert/ponytail` 5.2.0 | Lazy-senior-dev mode; only `ponytail-review` skill enabled | [review] [other] |
| 12 | `pi-caveman` 1.0.8 | Terse output mode | [context-mgmt] [ui] |
| 13 | `pi-mcp-adapter@2.32.1` | MCP gateway (`mcp`, `mcpScript`, direct tools), outputGuard; ships `mcp-scripting` skill | [other] [context-mgmt] |
| 14 | `pi-advisor-flow` 0.13.2 | `ask_advisor` executor/advisor gates (advisor fable-5-1 xhigh, 5 calls/session; `advisorHerdrIntegration: true` in `advisor.json`) | [review] [herdr] |
| 15 | `@ogulcancelik/pi-herdr` 0.4.1 | `herdr_layout`/`herdr_pane`/`herdr_agent` tools | [herdr] [delegation] |
| 16 | `pi-web-access` 0.40.0 | `web_search`, `fetch_content`, `get_search_content` | [other] |
| 17 | `context-mode` 1.0.169 (skill `context-mode` only) | `ctx_*` sandbox exec + FTS5 KB | [context-mgmt] [memory] |
| 18 | `@plannotator/pi-extension` 0.28.19 | `plannotator_submit_plan` plan review | [review] [ui] |
| 19 | `@firstpick/pi-extension-tools` 0.2.6 | `/tools` allowlist manager (`config/custom/pi/webui/settings.json` via `PI_WEBUI_SETTINGS_FILE`) | [ui] [other] |
| 20 | `pi-cc-header` 1.1.1 | Startup header | [ui] |
| 21 | `pi-skills-manager` 0.2.0 | Skill enable/disable UI | [ui] |
| 22 | `@d3ara1n/pi-context-include` 3.0.0 | `@path` includes in AGENTS.md | [context-mgmt] |
| 23 | `@henryqw/pi-task-models` 8.1.3 | Shared task-model profiles (`config/pi-task-models/config.json`: `fast` = sonnet low → sol low) for henryqw extensions | [other] |
| 24 | `@henryqw/pi-herdr-rename` 5.0.6 | Auto-title + rename Herdr location | [herdr] [ui] |
| 25 | `pi-otel` 0.3.0 (user's fork `punk-dev-robot/pi-otel`, `~/dev/oss/pi-otel`) | OTel traces/logs to Logfire EU; `pi-otel:log` event channel; TRACEPARENT shell propagation | [obs] |
| 26 | `pi-extensible-workflows` 6.2.1 | **piewf**: `workflow*` tools, `subagents_*`, `/workflow`, `/subagents`, starter commands (`/scout`, `/oracle`, `/review`, `/parallel-review`, `/review-loop`, `/deep-research`), Trajectory UI | [delegation] |
| 27 | `@piewf/herdr` 6.2.1 | piewf↔Herdr transport: `/workflow` "open live session in Herdr pane", optional fully-inspectable mode (`enableFullyInspectableMode: false`) | [delegation] [herdr] |
| 28 | `pi-ask-user` 0.16.0 | `ask_user` tool | [ui] [other] |
| 29 | `@henryqw/pi-herdr-btw` 4.0.5 | Tool-enabled side threads in Herdr panes (open/merge) | [herdr] [delegation] |
| 30 | `pi-multi-account` 1.24.0 | Account failover/rotation + context guard backstop | [other] |
| 31 | `@gotgenes/pi-anthropic-auth` 3.4.2 | Anthropic OAuth | [other] |

Other settings that matter for migration:

- Compaction: `compaction {reserveTokens 64000, keepRecentTokens 40000}` and `observational-memory.compactAfterTokens 180000 calibrated`.
- `otel` block: `captureContent: full`, `spanNaming: genai`, traces+logs, metrics off.
- `skills` +/- list: `+tessl__wayfinder` and `+logfire-instrumentation`; the latter is not present on Linux.

**Not installed:** `@piewf/pi-ext-roles` (see §0).

**Tool allowlist:** `~/dotfiles/config/custom/pi/webui/settings.json` `resourceDefaults.tools.enabledTools` (58 entries) pins:

- piewf: `subagents_{run,inspect,steer,stop,retry}`, `workflow`, `workflow_{catalog,respond,resume,retry,status,stop}`
- Herdr: `herdr_agent`, `herdr_layout`, `herdr_pane`, plus stale `herdr_start_worktree` (its package was removed 2026-08-05)
- Other: `ask_user_question` (stale; rpiv package removed), `ask_advisor`, `plannotator_submit_plan`

A migration must swap these pins: *"Dynamic tools … are pinned in the allowlist anyway"* (`piewf-role-config.md`).

---

## 2. piewf roles

**Location:**

- SSOT: `~/dotfiles/config/custom/pi/agent/pi-ext-roles/roles/<name>.md` and `.../pi-ext-roles/settings.json`.
- Deployed: per-file symlinks at `~/.config/pi/agent/pi-ext-roles/{settings.json,roles/*.md}` (created 2026-10-14 10:35).
- History: renamed from `pi-extensible-workflows/roles/` in `fbc3c29` (2026-10-07), following piewf 6.0's move to
  `~/.pi/agent/pi-ext-roles/`.
- The old dir `~/.config/pi/agent/pi-extensible-workflows/` now holds only `changelog-state.json` (`lastNotifiedVersion 6.2.1`).
- No project `.pi/pi-ext-roles/` was found.

### Shared settings (`pi-ext-roles/settings.json`)

```json
{
  "concurrency": 8,
  "modelAliases": {
    "workhorse": "anthropic/claude-sonnet-5-5:medium",
    "strong": "anthropic/claude-opus-5-5:high",
    "sota": "anthropic/claude-fable-5-1:high",
    "sota-openai": "openai-codex/gpt-6-astra:high",
    "review-openai": "openai-codex/gpt-6.1-sol:high",
    "cheap-model": "workhorse"
  },
  "skills": ["!herdr", "!logfire-ui", "!plannotator-*", "!ctx-insight", "!ponytail-help"],
  "extensions": [
    "!*", "**/pi-claude-auth/**", "**/pi-otel/**", "**/pi-rtk-optimizer/**", "**/@ff-labs/pi-fff/**",
    "**/pi-caveman/**", "**/context-mode/**", "**/pi-advisor-flow/**", "**/pi-mcp-adapter/**",
    "**/pi-context-include/**", "**/punk-steering/**"
  ],
  "extensionSettings": { "herdr": { "enableFullyInspectableMode": false } }
}
```

What the settings imply for agents:

- No `herdr_*`, plannotator, web, or btw tools. Web is re-enabled per role.
- No pi-observational-memory, pine-of-glass, or local `context-nudge`/`context-events`/`repowise-augment`/`bash-output-guard`/`pi-lsp` extensions.
- punk-steering **is** loaded in children.

### Role table

Every `tools` list starts with `"!*"`.

| Role | model | tools | skills | extensions | overrideSystemPrompt / contextFiles | Purpose |
|---|---|---|---|---|---|---|
| `recon` | `workhorse:low` | read, grep, find, ls, write, ask_advisor, record_advisor_outcome, mcp, mcpScript, `repowise_*`, ctx_search, ctx_execute_file (no bash/edit/web) | `!*`, logfire-query, mcp-scripting | `!**/pi-caveman/**` | true / [] | Repo-read-only scout; writes `.scratch/recon-<topic>.md`, returns paragraph + path; `BLOCKED:` if it needs bash/web |
| `researcher` | `strong` | read, write, bash, mcp, mcpScript, web_search, fetch_content, get_search_content, ask_advisor, record_advisor_outcome, `ctx_*` | `!*`, cock-research, mcp-scripting | `**/pi-web-access/**`, `!**/pi-caveman/**` | true / [] | External research with cited brief at `.scratch/research-<topic>.md`; no repo changes |
| `dev` | `strong` | read, grep, find, ls, bash, write, edit, mcp, mcpScript, `repowise_*`, ask_advisor, record_advisor_outcome, `ctx_*` | `!*`, cock-tdd, cock-codebase-design, mcp-scripting | `**/ponytail/**` | (default) / ["project","cwd"] | Judgement implementer in worktree; never signs off own work |
| `impl` | `workhorse` | read, grep, find, ls, bash, write, edit, ask_advisor, record_advisor_outcome, `ctx_*` | `!*` | — | true / [] | Bounded smallest-diff edits; stops if bigger than brief |
| `tests` | `workhorse` | read, grep, find, ls, bash, write, edit, mcp, mcpScript, `repowise_*`, ask_advisor, record_advisor_outcome, `ctx_*` | `!*`, cock-tdd, mcp-scripting | — | (default) / ["project","cwd"] | QA/test engineer: strategy, tests, coverage |
| `reviewer` | `sota` | read, grep, find, ls, bash, mcp, mcpScript, `repowise_*`, ask_advisor, record_advisor_outcome, `ctx_*` (no edit/write) | `!*`, mcp-scripting | `!**/pi-caveman/**` | true / [] | Staff-engineer review on 5 axes (correctness/readability/architecture/security/perf) |
| `comms` | `workhorse` | read, write, bash, mcp, mcpScript, ask_advisor, record_advisor_outcome, `ctx_*` | `!*`, mcp-scripting | `!**/pi-caveman/**` | true / [] | Linear/Notion/Slack/gh ops exactly as briefed; reports every mutation id/URL |
| `planner` | `strong` | read, grep, find, ls, write, mcp, mcpScript, `repowise_*`, web_search, fetch_content, ask_advisor, record_advisor_outcome, `ctx_*` (no bash/edit) | `!*`, punk-sdlc, swap-linear, swap-project, cock-research, cock-domain-modeling, cock-grilling, cock-codebase-design, mcp-scripting | `**/pi-web-access/**`, `!**/pi-caveman/**` | true / [] | Writes one SDLC stage artifact only under `~/dev/swapc/specs/<KEY>/`; persona "Kuba Gaj"; ADR 0004 |

Notes:

- Role bodies repeat the "Navigate with read/grep/find/ls…" tool-economy paragraph (dev, impl, recon) and the
  "you inherit AGENTS.md/CLAUDE.md" contract (dev, impl, recon).
- The completion contract assumes piewf's `workflow_result` tool, which 5.8+ makes children call.
- Retired roles, in git history only: `lead` (pi-subagents era, cannot nest under piewf). Pre-piewf
  `agents/*.md` (removed 2026-08-25): `intel`, `code-reviewer`, `security-auditor`, `test-engineer`,
  `web-performance-auditor`, `planner`.

---

## 3. Steering

**Extension:**

- `~/dotfiles/config/custom/pi/agent/extensions/punk-steering/{index.ts (228 lines), resolver.ts (452), test/resolver.test.ts}`.
- Deployed as per-file symlinks in `~/.config/pi/agent/extensions/punk-steering/`.
- Level: `punk-steering.json` = `{ "level": "advise" }`.
- Specs: `~/dotfiles/specs/punk-steering-v1.md` (KUB-164, replaced the 7.6KB `APPEND_SYSTEM.md`) and `specs/punk-steering-v2.md` (guards).

**Rule discovery and format:**

- Rules come from `<agentDir>/steering/*.md` (global) plus `<cwd>/.pi/steering/*.md` (project, trusted only). The project rule wins on a name collision.
- Frontmatter: `kind: briefing | precondition | reminder(reserved) | guard`, `when.tools: [globs]`, per-rule `level`.
  The effective level is min(rule, global). Levels: `off < observe < advise < rewrite`.

**Mechanism:**

- `before_agent_start`:
  1. Resolves rules against `event.systemPromptOptions.selectedTools` (or `pi.getActiveTools()`). Gating is
     **by tool presence in the session**, not by tool activity.
  2. Appends matching **briefings** to the system prompt.
  3. Runs **precondition** `probe` shell commands once per session (`pi.exec("sh",["-c",probe],{cwd})`).
     `on_fail` can be `notify`, `ask` (confirm, then run `fix`), `run` (run `fix`), or `stop` (abort `agent_start`).
     Failures are injected as a `customType: "punk-steering"` message.
- `tool_call` (guard rules):
  - Splits a `field` (e.g. bash `command`) into shell segments. `allow` regexes are checked first
    (`override: # allow:` passes and is logged), then `deny`.
  - Each violating call is one strike, per session, shared across guards.
  - `observe` logs only. `advise` and `rewrite` reject the call with reason `"steering/<rule> — strike n of 3 … <rule body>"`.
  - On strike 3 in a **main** session: `pi.setActiveTools(["read","write","herdr_layout","herdr_agent","herdr_pane"])`
    and the reason tells the model to invoke the **punk-handoff** skill and stop.
- Subagents are rejected on every violation but never handed off. `isSubagent(ctx)` checks two signals:
  - Active tools lack both `herdr_layout` and `herdr_agent`. This is **coupled to the piewf extension allowlist excluding pi-herdr**.
  - Otherwise, the first user message starts with `"Workflow: "`. This is **coupled to the piewf prompt header, removed in 6.2.1**.
- Telemetry goes out on `pi.events.emit("pi-otel:log", …)`: `pi.steering.applied`, `.violation`, `.override`, `.block`,
  with attributes `pi.steering.rule/tool/segment/pattern/strike/enforced/subagent`.
- The `/steering` command lists rule gate results, probe status, strikes, and the last 5 verdicts.

**Rule files:** `~/dotfiles/config/custom/pi/agent/steering/`, symlinked to `~/.config/pi/agent/steering/`.

| File | kind / gate | Content & references |
|---|---|---|
| `delegation.md` | briefing, `when.tools: [subagents_run]` | **Heavily piewf-coupled**: `subagents_run({ role, label, prompt })`, background default, `mode: "foreground"`; role routing recon/impl/dev/tests/researcher/comms/reviewer; "3rd tool call = tripwire"; completion = steer msg → `subagents_inspect({id})`; `subagents_steer`/`subagents_stop`/`subagents_retry` (no resume); concurrency 8, no queue (`AGENT_FAILED`); children have a clean context |
| `guard-bash.md` | guard, level `observe`, tool bash/field command, strikes 3 | deny `grep/rg/cat/head/tail/ls/find/wc/tree`, `sed -n`, `sed -i`/`perl -pi`, `python -c/node -e`, `python x.py`, `cd $PWD`; allow `^git\b`, `override: # allow:`; body: "Source outside this repo … → dispatch `recon`" |
| `guard-read-outside-repo.md` | guard, observe, tool read/field path | deny `node_modules`, `site-packages`, `.local/share`, `/tmp`; body "→ `recon`" |
| `web-research.md` | briefing, `[web_search, fetch_content]` | Routing; "Bulk or exploratory research → `researcher` subagent" |
| `external-services.md` | briefing, `[mcp, mcpScript]` | MCP-first (notion/linear/logfire/exa/firecrawl); load `logfire-query` skill |
| `linear-conventions.md` | briefing, `[mcp, mcpScript]` | KUB states, labels, PR lifecycle; `swap-linear` skill (now disabled); mentions "manager, comms, workflows" |
| `multi-repo.md` | briefing, `["repowise_*"]` | Workspace root means coordinator; load `multi-repo-ticket` (now disabled) |
| `repowise-routing.md` | briefing, `["repowise_*"]` | repowise-first routing; cymbal refs (cymbal removed, `e673faa`) |
| `repowise-index-absent.md` | precondition, `repowise_*`, `on_fail: notify` | probe `repowise status` |
| `repowise-index-stale.md` | precondition, `on_fail: run`, `fix: repowise update`, timeout 20 | |
| `tool-economy.md` | briefing, no gate (always) | read/grep/find/ls vs bash |

Delegation guidance appears only where `subagents_run` exists. With piewf's agent allowlist, children never see
`delegation.md` (they have no `subagents_*`).

---

## 4. Local extensions (`~/dotfiles/config/custom/pi/agent/extensions/`, symlinked into `~/.config/pi/agent/extensions/`)

| File | Purpose | Coupling |
|---|---|---|
| `punk-steering/` | Steering rules engine (§3) | **piewf** (`isSubagent` via `"Workflow: "` prefix; comment "Subagents (piewf roles)…"); **herdr** (handoff toolset, herdr-tool presence as the subagent signal); punk-handoff |
| `herdr-agent-state.ts` | Herdr-installed integration (`HERDR_INTEGRATION_ID=pi`, v8, "managed by herdr; reinstalling overwrites"). Reports pane state (working/idle/blocked) over `HERDR_SOCKET_PATH`; listens to `herdr:blocked` events; TUI-mode root sessions only | **herdr** (also a symlink into dotfiles, so a herdr reinstall writes through into the repo) |
| `herdr-blocked-bridge.ts.disabled` | Mapped `rpiv:ask-user:blocked` and `plannotator_submit_plan` execution to `herdr:blocked` events. Disabled 2026-10-14 | herdr |
| `context-nudge.ts` | Once per session at ≥150K tokens: suggest `/punk-handoff`; emits `pi.context.nudge` (KUB-149) | context-mgmt, handoff (herdr indirectly) |
| `context-events.ts` | Emits compaction / OM (`om.*`) / handoff lifecycle as `pi.context.*` OTel logs | obs, context-mgmt |
| `bash-output-guard.ts` | Port of context-mode's PreToolUse bash nudge; on `tool_result`, appends advice when output is actually large | context-mgmt |
| `repowise-augment.ts` | Pipes `tool_result` and `before_agent_start` to the `repowise-augment` binary (Claude hook envelope); emits `pi.augment.fired` | context/other |
| `learning-opportunities-auto.ts` | After `git commit`, nudges a learning exercise (max 2 per session) | other |
| `preserve-scrollback.ts.disabled` | Strips ESC[3J so Herdr pane scrollback survives startup | herdr (disabled) |
| `pi-lsp/` → `~/dotfiles/config/custom/pi-lsp` (vendored 0.1.7 + `0001-notify-instead-of-empty-steer.patch`) | LSP diagnostics. The patch exists because upstream's empty steer message *"derails multi-step briefs (subagents, -p mode)"* | subagent-motivated patch |
| `pi-rtk-optimizer/config.json`, `pi-tool-display/config.json` | Configs for packages | — |

piewf children load only `punk-steering` from this list (piewf extension allowlist). `pi-lsp`,
`context-*`, `repowise-augment`, and `bash-output-guard` are main-session-only. The "pi-cymbal" config was
deleted in `e52af39`.

---

## 5. Skills coupled to piewf or Herdr

**Locations:**

- Own skills: `~/dotfiles/config/custom/agents/skills/` → `~/.agents/skills/` (dotter, `.dotter/global.toml:48`).
  Active: `punk-handoff/`, `punk-resume/`.
- Disabled since 2026-10-14: `config/custom/agents/skills.disabled/{multi-repo-ticket,punk-sdlc,swap-linear,swap-project}`.
- Tessl skills: `~/.agents/skills/tessl__*` → `~/.tessl/plugins/...`.
- `~/.agents/skills/herdr/SKILL.md` is a regular file (13.5K) installed by Herdr.

| Skill | Coupling (quoted) |
|---|---|
| `punk-handoff` (`config/custom/agents/skills/punk-handoff/SKILL.md`) | **Herdr.** *"If `HERDR_ENV=1`, Herdr tools (`herdr_layout`, `herdr_agent`) are available … 1. Get the current pane ID via `herdr_layout` action `current`. 2. Split a sibling pane (`pane_split` with `focus: true` …) and start a new pi agent in it (`herdr_agent` action `start`). Project-level manager … Pass `agentArgs: ["--model", "anthropic/claude-fable-5-1"]` … close it with `herdr_pane`."* Saves to `${XDG_STATE_HOME:-~/.local/state}/punk/handoffs/<slug>/<ts>--<branch>.md`. Invoked by punk-steering strike 3 and by context-nudge. |
| `punk-resume` + `manager-mode.md` | **Delegation/Herdr (conceptual).** *"If you were launched with a role and a brief (subagent, workflow agent, herdr child) you are NEVER the manager"*; manager *"plans, delegates to subagents, works tickets"*; *"Acceptance: manager closes tickets after self-check (reviewer subagent for code changes)"*; tracker conventions via steering rule `linear-conventions`. |
| `punk-sdlc` (disabled) | **piewf.** *"Each stage is one `planner`-role dispatch (`subagents_run`, or `agent("planner", …)` in a workflow) … Publishing is a separate explicit step through the `comms` role"*; plannotator gate; ADR 0004. |
| `multi-repo-ticket` (disabled) | **Herdr, not piewf.** *"Executors — load the `herdr` skill … `herdr_layout pane_split` with `cwd` = the worktree, `herdr_agent start` (kind `pi`), then `prompt` … `read` the pane and confirm the text was submitted … Monitor — `herdr_agent wait`. On `done`: review the diff … On `blocked`: inspect … close the executor panes FIRST … then `wt-ticket remove`."* Executors are full SOTA sub-orchestrators that use their own subagents. |
| `herdr` (Herdr-installed) | Pane/agent control reference. Excluded from piewf children (`"!herdr"`). |
| `tessl__plannotator-tui` (plannotator/herdr-annotate) | Opens plan review in a Herdr pane. |
| `terminal-browser` | Splits the human's terminal pane. |

Other non-skill coupling:

- Root `~/dotfiles/AGENTS.md:34-36` ("When editing agent roles for `subagents_run` or workflow `agent(...)`").
- `CONTEXT.md` (Stage/Flow/Verifier vocabulary: *"Run in the `verify` stage by the tests/reviewer roles"*).

---

## 6. Saved workflows and punkfl0w

**`~/dotfiles/config/custom/pi/agent/workflows/pr-principal-review.js`** (116 lines; symlinked to `~/.config/pi/agent/workflows/`)
is the only saved workflow.

- Args: `{pr | base, rounds=1, repo, sota}`.
- Runs two `reviewer`-role agents in `parallel("review", …)` with pinned model aliases:
  opus `strong` vs sol `review-openai`, or with `sota` fable `sota` vs astra `sota-openai`.
- Brief: a principal-level high-priority-only review that ends with `FINDINGS: <n>`.
- Then up to `rounds` of `parallel("debate", …)`: each side marks AGREE/CONTEST/MAINTAIN/WITHDRAW, and the
  loop exits early when both say `CONSENSUS: yes`.
- Then a `fable-arbiter` agent (`model: "sota"`) writes `reviews/PR-<n>-review-<A>-vs-<B>.md` and returns verdict + top 3.
- Uses piewf script primitives: `agent()`, `parallel()`, `prompt()`, `log()`, `args`. Notes the
  *"operation name must be a static string literal (preflight AST check)"* rule.
- Depends on the role `reviewer` and on aliases defined in `pi-ext-roles/settings.json`, so it is at risk under §0.

**piewf built-ins in use or available:** `/scout`, `/oracle`, `/review`, `/parallel-review`, `/review-loop`, `/deep-research`, plus the
`reviewLoop` starter (6.2.1 uses persistent developer handles). The 10-02 run configs show built-in
`agentDefinitions` `developer`/`oracle` with alias `developer-model`.

**`~/dev/oss/punkfl0w`** is **unrelated to piewf**:

- A Spec Kit (`.specify/`) extension, preset, and workflow porting "Intent Integrity Kit": `speckit.punk.*` commands
  (init/constitution/specify/plan/checklist/testify/tasks/analyze/implement/taskstoissues/bugfix/clarify).
- Contents: `extensions/punk/`, `presets/punk/`, `workflows/`, `migration-log/`, `upstream_docs/`, and OpenCode
  command copies in `.opencode/commands/`.
- Last commit 2026-05-27. Uses OpenCode's `Task` tool for parallel `[P]` tasks.
- Referenced only historically: in `docs/plans/2026-07-27-pi-multi-agent-orchestration-design.md` §9 ("opt-in, per-phase")
  and in `agent-epic-runbook.md`.
- Nothing to migrate for piewf.

**Other repos in `~/dev/oss`:** `pi-extensible-workflows` (upstream `vekexasia/…`, the user contributes),
`pi-herdsman` (`boadij/pi-herdsman`, v0.26.0), `pi-otel` (own fork), `herdr-plannotator`, `repowise`.

---

## 7. Observability: pi-otel + Logfire role attribution

Doc: `~/dotfiles/docs/reference/logfire-pi-role-attribution.md`. Origin: `.scratch/recon-otel-role-attribution.md`.
Used by experiment E11 in `docs/otel_retro/2026-09-16-experiments-ledger.md`.

**Mechanism.** Attribution is query-time only, with no instrumentation change.

- pi-otel emits one `invoke_agent pi` span per session (at session end) carrying `pi.user_prompt`.
- piewf used to prefix the child's first prompt with `Workflow: <name>\nAgent: <role>`.
- The CTE takes the earliest `invoke_agent pi` per `attributes->>'pi.session.id'`, then
  `regexp_match(prompt,'^Workflow: [^\n]+\nAgent: ([^\n]+)')[1]`, falling back to `'main'`.
- The CTE is joined to `chat %` spans (cost = `pi.cost.usd`, not `gen_ai.usage.*`) and `execute_tool %` spans on `pi.session.id`.
- Metrics carry no session id, so they are role-blind.
- E11 uses a variant on the `pi.user_prompt` span / `pi.prompt.text`.

**Caveat, written in the doc and now realised.** The doc says: *"Coupling to piewf prompt format … change that prefix and attribution silently degrades to `main`."*
piewf 6.2.1 removed the header. Every child session will now read as `main`, unless the label or role
reaches telemetry some other way. pi-otel 0.3.0 has no piewf awareness. It only propagates `TRACEPARENT` into
shell-tool env (`dist/shell-propagation.js`), so children do not appear as child spans of the parent.

**Other `pi-otel:log` producers:**

- punk-steering: `pi.steering.*`
- context-events: `pi.context.*`
- context-nudge: `pi.context.nudge`
- repowise-augment: `pi.augment.fired`

**Logfire access:** `logfire` and `logfire-swap` MCP via the agentgateway at `localhost:3000`.

**Measured delegation volume:**

- E3 baseline: `subagents_run` 20 per 14d.
- 2026-09-19 review: delegated calls 12 → 26.
- Local run store `~/.config/pi/agent/subagents/` (241 runs) by role: recon 51, dev 49, researcher 37, reviewer 30,
  impl 28, comms 24, tests 11, planner 3, none 5, plus 1 each of the ad-hoc `implementer` and `docs`.

---

## 8. History and decisions

| Date | What | Source |
|---|---|---|
| 2026-07-27 | Orchestration design: horizontal delegation via **`@minhduydev/pi-subagents`** (Herdr panes/worktrees), vertical via `pi-advisor-flow`, opt-in fan-out via **`@quintinshaw/pi-dynamic-workflows`**, Herdr topology (tab 1 = manager, tab per work item), `@ogulcancelik/pi-herdr` control tools, cross-family critic loop (Fable plans, Sol reviews, Fable arbitrates) | `docs/plans/2026-07-27-pi-multi-agent-orchestration-design.md` (§2, §7, §8, §10); commit `b752f91` |
| 2026-07-27 | Epic runbook: manager `pim` + `task` tool profiles (recon, ai-eng, be-eng, fe-eng, devops, observability, reviewer); zsh launchers `pim/pip/pid/piqa/pir/pif`; *"`task` children inherit the parent's model — no per-profile tiering. Cheap recon = launch a Herdr pane with `pir`"* | `docs/reference/agent-epic-runbook.md` (historical; references `config/custom/zsh/rc.d/092-pi-aliases.zsh`, which no longer exists) |
| 2026-08-05 | Swapped `pi-dynamic-workflows`, `addyosmani/agent-skills`, and `pi-telemetry` for **piewf + `@piewf/cli` + `@piewf/herdr`**, plus `pi-btw` and `rpiv-ask-user-question`; removed `pi-ask-herdr`, `@yassimba/pi-herdr-worktree`, `pi-recap`, and others; new `intel` agent | commit `58f76bc` |
| 2026-08 | Roles moved from dotter handlebars templates (`pi_tools_*`, `pi_model_*`, shared bodies in `config/custom/pi/prompts/`) to self-contained symlinked files | `piewf-role-config.md` "History"; `plans/piewf-shared-role-config.md` (proved `disabledAgentResources` merges and `tools` replaces) |
| 2026-08-25 | **Replaced pi-subagents (edxeth/pi-subagents v2.7.4, `agents/*.md`) with piewf standalone `subagents_*`** (piewf 5.8.0). Reasons: one config surface; *"focus on piewf (user contributes to it)"*; kill pi-subagents' *"parent shows idle while child runs" batch-barrier bug machinery*. **Accepted losses:** visible-terminal-first interactive agents, `subagent_resume` follow-ups, `lead` (nesting impossible: `subagents_*`/`workflow*` excluded in children), per-child env (`PI_SUBAGENT_HERDR_PLACEMENT=tab`), children surviving parent exit, automatic roster. Completion = steer + `subagents_inspect`; children must call `workflow_result` | `~/dotfiles/plans/piewf-subagents-migration.md`; commit `afb0231` |
| 2026-08/09 | Role audits: repowise_* and ctx_*, mcpScript pairing, drop `source_check` (KUB-17, KUB-22 composio removal, KUB-26 tools allowlist) | `7e38b08`, `e332d3b`, `832ac20` |
| 2026-09-16 | Published piewf packages instead of a local checkout (`1dd8679`); static model aliases (`d352624`); **punk-steering v1** replaces APPEND_SYSTEM.md (`651424b`, KUB-164); v2 guards; manager-mode added (`56d75ff`) | ledger E3/E5; `specs/punk-steering-v*.md`; `docs/reference/agent-context-files.md` (footprint: main ~7.4KB steering, recon child ~1.8KB) |
| 2026-09-16 | E3 (advice-only steering) scored **refuted** 09-19 → E5 hard guards | ledger |
| 2026-09 | ADR 0004 artifact-per-stage SDLC: `planner` role drafts stage artifacts into `~/dev/swapc/specs/<KEY>/`; plannotator gates; `comms` publishes. Rejected: Notion-first, Linear docs as SoT, generic skill first | `docs/adr/0004-artifact-per-stage-sdlc.md`; `6b01b49`; ledger E11 (one dogfood dispatch, unscored) |
| 2026-10-07 | Roles moved to `pi-ext-roles/` (piewf 6.0 roles split) | `fbc3c29` |
| 2026-10-14 | piewf 6.2.1 installed **without** `@piewf/pi-ext-roles` (6.1 made it explicit-only); punk-sdlc, multi-repo-ticket, and swap-* skills disabled; herdr-blocked-bridge disabled | `e52af39`; §0 |

**No ADR covers piewf, subagents, or Herdr orchestration.** ADRs 0001-0003 are WM/docker; 0004 is SDLC.
The rationale lives in the `plans/` and `docs/plans/` files above.

---

## 9. Migration surface checklist (piewf → pi-herdsman)

Everything that names piewf constructs and needs a replacement or rewrite:

- **Packages:** `npm:pi-extensible-workflows`, `npm:@piewf/herdr` in `settings.json`. Also decide on
  `@henryqw/pi-herdr-btw` and `@ogulcancelik/pi-herdr` overlap with herdsman.
- **Roles:** 8 files plus `pi-ext-roles/settings.json`. Their selector syntax (`tools`/`skills`/`extensions`
  with `!*`, `model` alias, `overrideSystemPrompt`, `contextFiles`) is piewf-specific. Aliases are piewf-only:
  `advisor.json`, `pi-task-models`, and web-search use literal ids.
- **Steering:** `delegation.md` (entire body: `subagents_*` API, gate `when.tools: [subagents_run]`);
  role names in `guard-bash.md`, `guard-read-outside-repo.md`, and `web-research.md`.
- **punk-steering `isSubagent()`:** herdr-tool-absence plus `"Workflow: "` heuristics. Needs a herdsman-child signal.
  Herdsman children running in Herdr panes may **have** herdr tools, which would flip them to "main"
  and expose them to strike-3 handoff.
- **Workflow script:** `workflows/pr-principal-review.js` (piewf `agent/parallel/prompt/log` API).
- **Telemetry:** the Logfire attribution CTE (already broken). Ledger E11 query. A herdsman-native role marker would be needed.
- **Tool allowlist:** `config/custom/pi/webui/settings.json` (subagents_*, workflow* pins; stale herdr_start_worktree and ask_user_question).
- **Docs/context:** `~/dotfiles/AGENTS.md:16,34-36`, `docs/reference/piewf-role-config.md`,
  `docs/reference/logfire-pi-role-attribution.md`, `CONTEXT.md` (role nouns), ADR 0004 (`planner`/`comms`).
- **Skills:** `punk-sdlc` (disabled; `subagents_run`/`agent("planner")`), `manager-mode.md` ("reviewer subagent").
  `punk-handoff` and `multi-repo-ticket` are Herdr-native already.
- **Run store:** `~/.config/pi/agent/subagents/` (241 runs) and `pi-extensible-workflows/changelog-state.json`.
  These are piewf state, not config.
- **Herdr integration already in place, independent of piewf:**
  - `herdr-agent-state.ts` (Herdr-managed pane state, `herdr:blocked` events)
  - `@ogulcancelik/pi-herdr` tools
  - `pi-herdr-rename`
  - `pi-herdr-btw`
  - `advisorHerdrIntegration`
  - `hm()` mac-server wrapper (`config/custom/zsh/rc.d/064-herdr.zsh`; `docs/reference/mac-herdr-server.md`:
    *"Sockets are per machine. Local `herdr …` and the `herdr_*` MCP tools only see the Linux server"*,
    so cross-machine delegation goes through `ssh mac herdr …`).
