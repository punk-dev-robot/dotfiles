# pi-herdsman agent definitions

How the agents behind `delegate_agent` are configured in this repo. pi-herdsman
replaced piewf as the delegation layer on 2026-10-14 (KUB-171). Upstream schema:
`~/.config/pi/agent/npm/node_modules/pi-herdsman/docs/reference/agent-definition-schema.md`.

## Where definitions live

One file per definition in `config/custom/pi/agent/agents/<name>.md`: YAML
frontmatter (model, thinking, tools, skills, extensions, context) + the prompt as
body. Herdsman loads global definitions from `~/.config/pi/agent/agents/`
(precedence: bundled < project `<cwd>/.pi/agents/` < global).

Roster: `recon`, `researcher`, `dev`, `impl`, `tests`, `reviewer`, `comms`,
`planner`, plus `reviewer-sol`, `reviewer-opus`, `reviewer-astra` (second-model reviewers) and
`arbiter` / `arbiter-opus` (write the report; share `agent-bodies/arbiter.md`) for the `pr-principal-review` skill, plus the reserved
`managed-lead` overlay (below; not an Agent), plus the 11 `pstack-*` leaves for
poteto-mode playbooks (see [pstack roster](#pstack-roster-kub-176)). Only `dev` delegates (`agents: [recon, researcher, tests]`); every
other definition is a leaf. `scout.md`, `implementer.md`, `generalist.md` are
`enabled: false` overlays that switch off the bundled definitions our roster
replaces.

Shared bodies live in `config/custom/pi/agent/agent-bodies/` and are pulled in
with a body line `@../agent-bodies/<name>.md` (resolved relative to the
definition file, expanded at launch). All `reviewer*` definitions share
`agent-bodies/reviewer.md`, both arbiters `agent-bodies/arbiter.md`. Keep them **outside** `agents/`: Herdsman parses
every `*.md` under `agents/` recursively as a definition.

**Every definition is a dotter template.** Each file has its own
`type = "template"` entry in `.dotter/global.toml` `[base.files]`, so the
deployed copy is a real file:

1. Edit the repo file (or a variable in `[base.variables]`).
2. `dotter deploy`.
3. `herdsman-defs-check` (`local/bin/`): every rendered `extensions:` / `skills:`
   path and every body `@file` must exist, and no `{{` may survive. Package updates can move entry
   files, so rerun it after `pi update --extensions`.
4. `/herdsman definitions` lists the effective roster; a single invalid
   definition fails the whole roster.

Gotchas:

- **Templates, never symlinks.** Herdsman skips symlinked definition files
  silently (`readdir` + `isFile()`; boadij/pi-herdsman#390). A new definition
  needs its own `type = "template"` line even when it has no variables.
- **Change models through dotter variables**, not the `/herdsman definitions`
  model editor: the editor writes override files into the same directory that
  dotter renders into.

## Template variables (`.dotter/global.toml` `[base.variables]`)

Herdsman has no model-alias layer; these variables are ours.

- `model_workhorse` / `model_strong` / `model_sota` / `model_review_openai` —
  short `provider/family` ids (`anthropic/sonnet`, `anthropic/opus`,
  `anthropic/fable`, `openai-codex/sol`) that pi resolves to the newest model at
  launch. **The provider prefix is mandatory**: bare `sonnet` resolves to an
  `openai-codex` model. `thinking:` is a separate per-definition field. A new
  model release therefore changes agents silently; Logfire's model attribute
  shows it.
- `ext_base`, `ext_web`, `ext_ponytail`, `ext_bash_guard`,
  `ext_context_events` — lists of extension entry files relative to
  `~/.config/pi/agent/`, rendered per entry as
  `{{@root.home_dir}}/.config/pi/agent/{{this}}` inside `{{#each}}`
  (`home_dir` is per host). `ext_base` goes to every definition;
  `ext_web` to researcher and planner, `ext_ponytail` to dev,
  `ext_bash_guard` to bash-capable definitions, `ext_context_events` to all.
  No pi-rtk-optimizer and no pi-caveman in agents.

## Frontmatter conventions

- `noExtensions: true` + explicit `extensions:` paths. `pi --extension` takes a
  file path or `builtin:<name>`, never a glob or package name. `--no-extensions`
  also drops pi's built-in extensions.
- `tools:` is a closed allowlist (globs like `"repowise_*"` / `"ctx_*"` work).
  Herdsman passes it as `--tools`, which overrides `settings.json`
  `defaultTools`. Herdsman appends `ask_owner` (all agents) and the nine
  delegation tools (definitions with a non-empty `agents:`). The `agent` entry in
  dev's list is a policy sentinel, not a callable tool.
- **codemode needs both halves:** `codemode` in `tools:` **and**
  `- "builtin:codemode"` in `extensions:`. A child's codemode `ALL_TOOLS`
  equals its allowlist, so it cannot widen it.
- `skills:` takes SKILL.md paths (not names), with `noSkills: true`.
  `mcp-scripting` loads but stays hidden from the model
  (`disable-model-invocation: true` upstream); the `mcpScript` tool description
  carries the basics.
- `systemPromptMode: replace` + `inheritProjectContext: false` for recon,
  researcher, impl, reviewer, comms, planner; `append` +
  `inheritProjectContext: true` for dev and tests. `inheritGlobalContext: false`
  everywhere.
- Escalation in bodies is `ask_owner` (Herdsman contract), not a `BLOCKED:`
  return.

### Overlays of bundled definitions

`researcher` and `reviewer` share names with bundled Herdsman definitions, so
our files *overlay* them rather than replace them:

- Set `bodyMode: replace` and restate every field: an overlay inherits every
  field it leaves unset.
- `reviewer` sets `agents: []`: the bundled reviewer delegates to `scout`, and
  every `agents:` reference must resolve, so inheriting it from a disabled
  `scout` breaks the roster.
- Disabling a bundled definition is a file with just `name:` + `enabled: false`.

### `managed-lead` (Leads started by Manager `delegate_project`)

`managed-lead.md` overlays Herdsman's reserved launch definition for
Manager-assigned project Leads (KUB-173). It is not in the Agent roster and
cannot be delegated to. **Locked** (parser rejects): `enabled`, `agents`,
`permission`, and `systemPromptMode: replace`. Herdsman always adds the Lead
coordination tools (the nine delegation tools, `message_supervisor`,
`list_peers`, `message_peer`) to `tools:`; the supervisor/peer ones only go
live inside a real Herdr-managed Lead. **Overlaid:** model `{{model_strong}}`
/ `high` (same as the main session), our main-session working tools instead of
the bundled coordination-only `tools: []`, dev's skills, `ext_base` +
`ext_bash_guard` + `ext_context_events` (no pi-herdr, caveman, web, OM or
plannotator), `inheritProjectContext: true` + `inheritGlobalContext: false`
(the bundled default inherits global context). The body is not restated, so
the bundled body stays. Without pi-herdr it has no `herdr_*` tools, so
punk-steering's `isSubagent()` treats it as a child: no punk-handoff into a
pane Herdsman owns. Changes apply to the next Lead launch only
(`stop_lead` + `resume_project` to restart one).

## pstack roster (KUB-176)

pi-pstack-herdsman (our fork `punk-dev-robot/pi-pstack-herdsman`, branch
`kub-176-herdsman-026-compat`) adds poteto mode: the lead matches a task to a
playbook and delegates its steps to `pstack-*` leaves. The 11 names
(`pstack-advisor`, `-bug-fix`, `-hillclimb`, `-how-explorer`,
`-investigator`, `-perf-issue`, `-poteto-agent`, `-researcher`, `-reviewer`,
`-verifier`, `-verifier-sol`) are hard-coded in the package's playbook and
skill prose, so **our definitions keep the package's names**. Name,
description, thinking and body are verbatim from the package's
`definitions/`; we only swap models and tool kits. All are leaves
(`agents: []`), `systemPromptMode: append`, `inheritProjectContext: true`,
`skills: []`.

Model map (1:1 by upstream tier):

| Upstream model | Ours | Roles |
|---|---|---|
| `openai-codex/gpt-6.1-sol` | `{{model_strong}}` | advisor, bug-fix, poteto-agent, researcher, reviewer, verifier-sol |
| `openai-codex/gpt-6-astra` | `{{model_sota}}` | perf-issue, verifier |
| `openai-codex/gpt-6-luna` | `{{model_workhorse}}` | hillclimb, how-explorer, investigator |

Kit map (tools + extensions copied from our matching definition; upstream's
codex tools `exec_command`, `write_stdin`, `exec`, `wait`, `notebook`,
`new_context`, `history`, `notes` dropped; kit skills not copied; context
flags stay upstream's, so recon-kit leaves still get project context, unlike `recon`):

| Kit | Roles |
|---|---|
| `recon` | investigator, how-explorer, advisor, reviewer |
| `dev` (minus the `agent` sentinel and `agents:` list) | poteto-agent, bug-fix, perf-issue, hillclimb |
| `researcher` (+ upstream `grep`, `find`, `ls`) | researcher |
| `reviewer` | verifier, verifier-sol |

Routing: inside an active poteto-mode playbook use its `pstack-*` role table
for that task; otherwise the default routing (`steering/delegation-herdsman.md`).

The package auto-copies its own templates to
`~/.config/pi/agent/agents/pstack-<role>.md` on lead `session_start`, but
only for **missing** files (`wx`, never overwrites). With ours deployed, it
never fires; delete one and the package's codex-pinned copy comes back.

First deploy: the auto-copies already exist as unmanaged files and dotter
skips templates whose target exists, so `rm ~/.config/pi/agent/agents/pstack-*.md`
immediately before `dotter deploy` (no lead session in between). Don't use
`--force`: it clobbers every drifted template target.

## Tool activation (`/tools`)

`@firstpick/pi-extension-tools` owns the `/tools` TUI command and is the single
place tools are enabled/disabled. Global + model scopes persist to
`resourceDefaults.tools.enabledTools` in `config/custom/pi/webui/settings.json`
(`PI_WEBUI_SETTINGS_FILE` in `config/custom/zsh/.zshenv` points straight at the
repo file, so `/tools` saves land as a git diff; commit when happy).

The allowlist is deliberate (KUB-26): **a new static tool from a freshly
installed extension starts disabled.** Pin every new Herdsman or pi tool there
(the Herdsman agent, staff, peer and supervisor tools and `codemode` are pinned);
without the pin the main session gets Herdsman's prompt but no tools. Dynamic
tools (`ctx_*`, `repowise_*`, `mcp__<server>` proxies) are pinned too, so scope
recomputes cannot clamp them. Remove pins when a tool or MCP server is retired.
This allowlist governs the main session; agents get their tools from
`tools:` above.

## Observability and detection

Delegated agents start with `PI_HERDSMAN_AGENT_DEFINITION`, `PI_HERDSMAN_LABEL`,
`PI_HERDSMAN_OWNER_SESSION_ID`, `PI_SUBAGENT_CHILD=1` and
`PI_SUBAGENT_PARENT_SESSION` (among others). Two consumers:

- **pi-otel fork** (`punk-dev-robot/pi-otel@feat/KUB-171-herdsman-agent-attrs`,
  checkout `~/dev/oss/pi-otel`) maps them to `pi.agent.role`, `pi.agent.label`,
  `pi.parent.session.id`; queries in `docs/reference/logfire-pi-role-attribution.md`.
  pi installs git packages with `--omit=dev`, so the fork ships `dist/`. After
  any fork change: `npm run build`, commit `dist/` (`git add -f` for new files;
  `dist/` is gitignored), push, then `pi update --extensions`.
- **punk-steering** `isSubagent()` checks the env first.

**Managed Leads get no env** (`delegate_project` launches them without `--env`;
boadij/pi-herdsman#391). They read as `main` in Logfire; punk-steering still
treats them as children because our `managed-lead` loads no `herdr_*` tools.

## History

- 2026-08: dotter handlebars role templates (`pi_tools_*`, `pi_model_*`) replaced
  by symlinked piewf roles in `config/custom/pi/agent/pi-ext-roles/roles/`.
- 2026-10-14: piewf replaced by pi-herdsman; definitions back to dotter templates
  because extension entries must be concrete paths. `pi-ext-roles/`,
  `workflows/` and `steering/delegation.md` stay until the trial's go decision,
  for rollback.
