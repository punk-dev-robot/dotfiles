# piewf Role Config: Shared Tools & Resource Merging

How pi-extensible-workflows (piewf) roles combine with global settings, and how
this repo shares tool lists across roles. Verified against piewf 5.1.1 source
and `piewf doctor` output (2026-08).

## Merge vs override semantics

| Field | Behavior |
|---|---|
| `tools:` (role frontmatter) | **Full replacement.** The role's list replaces the inherited toolset entirely — no merge with anything (`WorkflowAgentExecutor.resolve()`). |
| `disabledAgentResources:` (skills/extensions) | **Merges.** Global `settings.json` patterns first, role patterns appended (`mergeAgentResourceExclusions`, agent-execution.ts:521), evaluated gitignore-style **last-match-wins** (utils.ts:130-138). |
| `modelAliases` | Defined in `settings.json`, referenced by name in roles. |

Practical consequences of the merge:

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

Since `tools:` doesn't merge, shared groups are dotter handlebars variables in
`.dotter/global.toml`:

```toml
[base.variables]
pi_tools_core = "read, grep, find, ls"
pi_tools_edit = "write, replace, undo_last_replace"
pi_tools_cymbal = "cymbal_search, cymbal_show, cymbal_refs"
pi_tools_cymbal_deep = "cymbal_investigate, cymbal_map, cymbal_outline, cymbal_structure, cymbal_context"
pi_tools_cymbal_review = "cymbal_diff, cymbal_changed, cymbal_impact"
pi_tools_advisor = "ask_advisor, record_advisor_outcome"
```

Used in role frontmatter:

```yaml
tools: [{{pi_tools_core}}, bash, {{pi_tools_cymbal}}, cymbal_impact, {{pi_tools_advisor}}]
```

Role assignment: developer = core+edit+bash+cymbal+impact/impls/importers;
reviewer = core+bash+cymbal+review; scout = core+write+cymbal+deep+mcp;
tests-expert = core+edit+bash+cymbal+impact; summarizer = none. All working
roles get advisor tools.

Skills (role negations after the `"**"` wipe): developer = `tdd`,
`codebase-design`; scout = `logfire-query`, `mcp-scripting` (completes the
`mcp` tool); tests-expert = `tdd`; reviewer/summarizer = none. Skills that
need bash (e.g. `composio-cli`) don't fit bash-less roles — deliberately
skipped; use a per-call override or a dedicated role if needed.

Per-role extension refinements (frontmatter `disabledAgentResources.extensions`,
appended after global so last-match-wins):

- caveman terse mode: ON for developer/tests-expert (code is the artifact),
  re-disabled (`"**/pi-caveman/**"`) for reviewer/scout/summarizer whose prose
  IS the product.
- ponytail: off for agents globally; developer opts back in
  (`"!**/ponytail/**"`).
- web access (pi-web-access): not enabled for any role — tool descriptions are
  heavy and rarely needed; grant per call (below) with
  `extensions: ["!**/pi-web-access/**"]` plus the web tools in `tools`.

## Per-call role overrides (one-off capabilities)

Workflows can grant extra capability for a single `agent()` call instead of
baking it into the role — `role` accepts an object (`applyRoleOverride`);
`tools` **replaces** the role list (copy the current one from
`piewf doctor --role <role>`), and the `disabledAgentResources` override can
even re-enable an extension just for that call:

```js
await agent(task, {
  label: "review-with-telemetry",
  role: {
    name: "reviewer",
    tools: [/* full list from doctor */ "mcp"],
    disabledAgentResources: {
      skills: ["**", "!logfire-query"],
      extensions: ["!**/pi-mcp-adapter/**"],
    },
  },
});
```

Notes:

- **A role tool only works if its providing extension is re-enabled for agents**
  in workflow `settings.json` `disabledAgentResources.extensions` (negation
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
