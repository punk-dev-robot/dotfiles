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
pi_tools_cymbal = "cymbal_search, cymbal_show, cymbal_refs"
```

Used in role frontmatter:

```yaml
tools: [{{pi_tools_core}}, bash, {{pi_tools_cymbal}}, cymbal_impact]
```

Notes:

- Package variables merge into one flat namespace for all enabled packages;
  both hosts enable `base` transitively. Host `[variables]` wins on key clash.
- Dotter disables HTML escaping (`register_escape_fn(str::to_string)`), so
  `{{var}}` renders comma lists verbatim.
- Dotter runs handlebars in **strict mode**: a typo'd variable fails
  `dotter deploy` loudly instead of rendering blank.
- Role-specific tools (`bash`, `write`, `replace`, `undo_last_replace`,
  `cymbal_impact`) stay as literals in each role.

Workflow: edit role in repo → `dotter deploy` → verify with
`piewf doctor --role <role>`.
