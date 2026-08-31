# piewf role configuration

How agent roles for pi-extensible-workflows (piewf) are configured in this repo.

## Where roles live

Roles are single self-contained files in
`config/custom/pi/agent/pi-extensible-workflows/roles/<name>.md`:
YAML frontmatter (model, tools/skills/extensions selectors) + the prompt as body.
Seven roles: `recon`, `researcher`, `dev`, `impl`, `reviewer`, `tests`, `comms` —
consumed by both piewf workflows (`agent(...)`) and standalone `subagents_run`.

Deployed as **symlinks** through the whole-dir dotter mapping
(`config/custom/pi/agent` → `~/.config/pi/agent`). Edit the repo file directly;
changes are live in new sessions, no `dotter deploy` needed.

> History: an earlier design used dotter handlebars variables
> (`pi_tools_*`, `pi_model_*`) with template-copy deployment and shared prompt
> bodies under `config/custom/pi/prompts/`. Replaced 2026-08 by plain
> self-contained files + symlinks. The old `pi-subagents` extension
> (`agents/<name>.md`) was removed 2026-08; `lead` retired pending a piewf
> workflow-script port.

## Frontmatter conventions

- `model: provider/model:thinking` — one literal string; a separate
  `thinking:` key is rejected.
- `tools:` starts with `"!*"` (wipe) then lists literals. Since the
  repowise migration (KUB-17): navigation = `readSeek_*`, call-graph =
  `cymbal_impact` / `cymbal_changed` (only cymbal tools still active),
  codebase intelligence = repowise via the `mcp` gateway.
- `skills:` negations after the `"!*"` wipe (exact names — a selector matching
  nothing silently disables everything): `dev` = `cock-tdd`,
  `cock-codebase-design`; `tests` = `cock-tdd`; `recon` = `logfire-query`,
  `mcp-scripting`; `researcher` = `cock-research`; `comms`, `impl`, and
  `reviewer` = none (`["!*"]`) — composio/notion/linear skills dropped with
  the move to direct remote MCP (KUB-22).
- `extensions:` refinements (layered after global settings, last-match-wins):
  caveman terse mode ON for dev/impl/tests, re-disabled
  (`"!**/pi-caveman/**"`) for reviewer/recon/researcher/comms whose prose is
  the product; ponytail off globally for agents, dev opts back in
  (`["**/ponytail/**"]` — positive re-enable); researcher re-enables
  pi-web-access per-role (`"**/pi-web-access/**"`); other roles get web tools
  per call only.

## Global tool activation (/tools)

`@firstpick/pi-extension-tools` owns the `/tools` TUI command and is the single
place tools are enabled/disabled. Scope precedence: session (session entries) >
exact model profile > global default > runtime. Global + model scopes persist
to `~/.pi/webui/settings.json` (`resourceDefaults.tools.enabledTools`
allowlist) — dotter-managed as `config/custom/pi/webui/settings.json`; `pi-rw`
points `PI_WEBUI_SETTINGS_FILE` at the worktree copy.

Dynamic tools (`ctx_*`, `workflow_*`, `subagents_*`, lazy `mcp__*` proxies)
register after startup; they are pinned in the allowlist anyway so scope
recomputes (model switch, session-tree navigation) cannot clamp them — the
extension preserves saved-but-unavailable names. Caveat: brand-new *static*
tools from future extensions start disabled until added via `/tools`.

Write-source: the extension saves via tmp-file + rename, which would replace a
dotter *symlink* with a regular file. Solved by `PI_WEBUI_SETTINGS_FILE` (set in
`.zshenv`) pointing straight at the repo file — `/tools` saves land in the
working tree as a normal git diff; commit when happy.
The old `config/custom/pi/agent/tools.json` snapshot and its enforcement shim
were removed (KUB-17). pi-cymbal's injected system-prompt guidance and nudges
are disabled in `extensions/pi-cymbal.json` (they recommended deactivated tools).

## Verification

```bash
npx -y @piewf/cli doctor --role <role>   # aliased to `piewf` in zsh
```

Read-only. Reports resolved model, tools, effective/excluded skills and
extensions, and prepared prompt. Run after any role or settings change.

Known false positive: context-mode registers `ctx_*` tools lazily on a
session's first agent turn, so `piewf doctor` (fresh process, no turn) flags
them ROLE_TOOL_INACTIVE. Real dispatch works — verified end-to-end. Ignore
doctor errors for `ctx_*` only.

## Per-call role overrides

Workflows can grant extra capability for a single `agent()` call — `role`
accepts an object (`applyRoleOverride`). `disabledAgentResources` is gone;
both frontmatter and `settings.json` reject it with `INVALID_METADATA`.
Check `piewf doctor --role <role>` and upstream piewf docs for the current
call-level override syntax before writing one.

A role tool only works if its providing extension is enabled for agents via
`extensions:` selectors in workflow `settings.json`. Web tools need
`!**/pi-web-access/**`, advisor tools need `!**/pi-advisor-flow/**`. Tools
from disabled extensions (herdr_*, agent_browser, recall, plannotator,
ask_user_question, workflow_*) do not exist in role sessions. Tool→provider
map: `.scratch/pi-tool-provider-map.md` (regenerate via recon if stale).
