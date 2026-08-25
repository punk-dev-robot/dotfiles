# piewf Role Config: Shared Tools & Resource Merging

How pi-extensible-workflows (piewf) roles combine with global settings, and how
this repo shares tool lists across roles. Roles are the **only** agent surface
in this repo — consumed by both piewf workflows (`agent(...)`) and piewf's
standalone `subagents_run`/`_inspect`/`_steer`/`_stop`/`_retry` tools; the
`pi-subagents` extension was removed during the 2026-08 migration. Verified
against piewf 5.8.0 source and `piewf doctor` output (2026-08, updated during
the pi-subagents removal migration).

## Merge vs override semantics

| Field | Behavior |
|---|---|
| `tools:`, `skills:`, `extensions:` (role frontmatter) | Ordered minimatch selector lists — same mechanism for all three. Candidates start **enabled**; selectors layer in precedence order **global settings → trusted-project settings → role frontmatter → call-level**, each layer's patterns evaluated last-match-wins. `["!*", "read", "grep"]` disables everything then re-enables the named items; `["*"]` re-enables everything after a restriction. `disabledAgentResources:` and `thinking:` no longer exist — role frontmatter and `settings.json` both reject them with `INVALID_METADATA` ("use skills, extensions, and tools selectors" / "put it on model as provider/model:thinking"). |
| `modelAliases` | Defined in `settings.json`, referenced by name in roles. |

Practical consequences of the selector layering:

- A role declaring only `skills:` leaves the global **extensions** baseline
  fully in effect.
- A role can *re-enable* a globally disabled resource by appending a negation:
  `extensions: ["!**/foo/**"]`.
- `skills: ["**", "!tdd"]` = disable everything, then re-enable `tdd`
  (last match wins). Pattern names must match the **discovered skill name** —
  a negation that matches nothing silently disables everything (this bit us:
  `!test-driven-development` vs actual name `tdd`).

## Inspecting effective config

```bash
npx -y @piewf/cli doctor --role <role>   # aliased to `piewf` in zsh
```

Read-only. Reports resolved model, tools, effective/excluded skills and
extensions, and prepared prompt. Use it after any role or settings change.

## Shared tool groups via dotter

Roles live in `config/custom/pi/agent/pi-extensible-workflows/roles/` and are
deployed as **template copies** (not symlinks — piewf's role scanner can't see
per-file symlinks, upstream #193; see `.dotter/global.toml`).

Since each role spells out its own `tools:` selector list, shared groups are dotter handlebars variables in
`.dotter/global.toml`:

```toml
[base.variables]
pi_tools_core = "read,grep,find,ls"
pi_tools_edit = "write,replace,undo_last_replace"
pi_tools_cymbal = "cymbal_search,cymbal_show,cymbal_refs"
pi_tools_cymbal_deep = "cymbal_investigate,cymbal_map,cymbal_outline,cymbal_structure,cymbal_context"
pi_tools_cymbal_review = "cymbal_diff,cymbal_changed,cymbal_impact"
pi_tools_advisor = "ask_advisor,record_advisor_outcome"
pi_tools_ctx = "ctx_execute,ctx_batch_execute,ctx_search"
```

No space after the commas: subagent frontmatter consumes the same variables as a
bare `tools: a,b,c` list, which may not trim spaces. YAML flow lists tolerate
either form.

Used in role frontmatter:

```yaml
tools: [{{pi_tools_core}}, bash, {{pi_tools_cymbal}}, cymbal_impact, {{pi_tools_advisor}}]
```

Role assignment: `dev` = core+edit+bash+cymbal+impact/impls/importers+ctx;
`impl` = core+edit+bash+ctx (bounded edits, no cymbal — the approach is already
known); `reviewer` = core+bash+cymbal+review; `recon` = core+write+cymbal+deep+mcp;
`tests` = core+edit+bash+cymbal+impact+ctx; `researcher` = read/write/bash+web
(no repo tools — external evidence only); `comms` = read/write/bash (external
systems: Linear/Slack via composio, Notion via skill, GitHub via gh — the only
role allowed to MUTATE external systems; gate public posts behind a workflow
checkpoint). All roles get advisor tools.

context-mode registers ctx_* tools LAZILY — on a session's first agent turn
(before_agent_start bootstraps its MCP bridge). Consequences: `/tools` shows no
ctx_* before the first message, and `piewf doctor` (fresh process, no turn)
false-flags ctx tools as ROLE_TOOL_INACTIVE / outside the boundary. Real
dispatch works — verified end-to-end via a `tests` workflow child running
ctx_execute. Ignore doctor errors for ctx_* only. Subagents dev/impl/tests
carry the same trio (tools + npm:context-mode extension).

Skills (role negations after the `"**"` wipe): `dev` = `tdd`,
`codebase-design`; `recon` = `logfire-query`, `mcp-scripting` (completes the
`mcp` tool); `tests` = `tdd`; `researcher` = `composio-cli`, `research`,
`notion`; `comms` = `composio-cli`, `notion` (bash-driven skills live in
bash-having roles only); `impl` = all (`["**"]`); `reviewer` = none.

`researcher` re-enables pi-web-access per-role — the pattern for role-scoped
extension grants.

Per-role extension refinements (frontmatter `extensions:` selectors, layered
after global/trusted-project settings selectors, last-match-wins):

- caveman terse mode: ON for dev/impl/tests (code is the artifact),
  re-disabled (`"**/pi-caveman/**"`) for reviewer/recon/researcher/comms whose
  prose IS the product.
- ponytail: off for agents globally; dev opts back in
  (`"!**/ponytail/**"`).
- web access (pi-web-access): not enabled for any role — tool descriptions are
  heavy and rarely needed; grant per call (below) with
  `extensions: ["!**/pi-web-access/**"]` plus the web tools in `tools`.

## Single source of truth: shared prompt bodies

Seven roles — `recon`, `researcher`, `dev`, `impl`, `reviewer`, `tests`,
`comms` — live only as piewf roles (`.../pi-extensible-workflows/roles/<name>.md`),
consumed by both piewf workflows (`agent(...)`) and piewf's standalone
`subagents_run` tools. The old `pi-subagents` extension (`agents/<name>.md`,
separate `subagent`/`subagent_kill`/`subagent_resume` tools) was removed
2026-08; `lead` (which spawned other agents) had no roles equivalent and is
retired pending a piewf workflow-script port, since nested spawning isn't
possible for standalone `subagents_run` calls.

The role file is a dotter template whose entire body is one include of the
shared prompt:

```handlebars
{{include_template "config/custom/pi/prompts/dev.md"}}
```

`include_template` paths resolve from the repo root and render variables inside
the included file. The shared bodies live in `config/custom/pi/prompts/` —
deliberately *outside* `config/custom/pi/agent/`, which is mapped wholesale to
`~/.config/pi/agent`, so prompt sources never deploy as agent resources.

Model and thinking level come from per-role dotter variables
(`pi_model_<name>` / `pi_think_<name>` in `.dotter/global.toml`); role
frontmatter joins them as `model: provider/model:thinking` (role frontmatter
rejects a separate `thinking:` key). Roles no longer use `modelAliases`
indirection; only `cheap-model` survives for workflow scripts.

Edit the prompt source and `dotter deploy`. Never edit the deployed copies in
`~/.config/pi/agent` — they are generated and get overwritten.

## Per-call role overrides (one-off capabilities)

Workflows can grant extra capability for a single `agent()` call instead of
baking it into the role — `role` accepts an object (`applyRoleOverride`).
`disabledAgentResources` is gone — both frontmatter and `settings.json` reject
it with `INVALID_METADATA`. The current per-call override shape for
`skills:`/`extensions:`/`tools:` selectors isn't nailed down here; check
`npx piewf doctor --role <role>` for the resolved policy and the upstream
piewf roles docs for the current call-level override syntax before writing
one.

Notes:

- **A role tool only works if its providing extension is re-enabled for agents**
  via `extensions:` selectors in workflow `settings.json` (negation
  pattern). Web tools need `!**/pi-web-access/**`, advisor tools need
  `!**/pi-advisor-flow/**`; cymbal/fff/hashline already enabled. Tools from
  disabled extensions (subagent, herdr_*, mcp, agent_browser, recall,
  plannotator, ask_user_question, workflow_*) do not exist in role sessions.
  Tool→provider map: `.scratch/pi-tool-provider-map.md` (regenerate via recon
  if stale).
- Package variables merge into one flat namespace for all enabled packages;
  both hosts enable `base` transitively. Host `[variables]` wins on key clash.
- Dotter disables HTML escaping (`register_escape_fn(str::to_string)`), so
  `{{var}}` renders comma lists verbatim.
- Dotter runs handlebars in **strict mode**: a typo'd variable fails
  `dotter deploy` loudly instead of rendering blank.
- One-off tools (`bash`, `cymbal_impact`, `cymbal_impls`, ...) stay as literals
  in each role.

Workflow: edit role in repo → `dotter deploy` → verify with
`piewf doctor --role <role>`.
