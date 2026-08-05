# Shared context-management config for pi-extensible-workflows roles

## Context

Roles under `config/custom/pi/agent/pi-extensible-workflows/roles/` each repeat
tool lists and `disabledAgentResources` blocks. Goal: define a shared "core"
set once, roles add only their specifics.

**The premise is only half-true — proven, not assumed:**

- `disabledAgentResources` (skills/extensions) **already merges**, it does not
  override. Role patterns are appended after global `settings.json` patterns
  and evaluated gitignore-style, last-match-wins.
  - Source (piewf 5.1.1): `mergeAgentResourceExclusions(base, role)` at
    `src/agent-execution.ts:521` concatenates base-then-role (`src/utils.ts:140`);
    `disabledResources` at `src/utils.ts:130-138` sets
    `excluded = !pattern.startsWith("!")` on each match → last match wins.
  - Empirical: `piewf doctor --role tests-expert` — the role only declares
    `skills`, yet the **global** extension baseline still applies (effective
    extensions = exactly the 10 globally re-enabled ones: pi-claude-auth,
    noheadroom, pi-rtk-optimizer, pi-fff, pi-otel, ponytail, pi-caveman,
    pi-hashline-edit-pro, pi-cymbal, context-mode). Under override semantics
    the role would have wiped extension exclusions entirely.
- `tools` does **NOT** merge: a role's `tools:` list fully replaces the
  inherited toolset (`WorkflowAgentExecutor.resolve()`). This is the only
  place templating is needed — every role duplicates `read, grep, find, ls`
  + cymbal read-only tools.

**Bug found by the doctor run:** tests-expert's `"!test-driven-development"`
matches nothing — no skill by that name exists (doctor lists the actual skill
as `tdd`, and it lands in *excluded*). The role currently gets zero skills.

## Decisions (agreed)

1. **Template `tools` only.** Skills/extensions keep using piewf's native
   merge: global baseline in `settings.json`, roles append refinements.
2. **Two shared groups:** core-read (`read, grep, find, ls`) and
   cymbal-readonly (`cymbal_search, cymbal_show, cymbal_refs`). Roles add
   `bash`, `write`/`replace`/`undo_last_replace`, `cymbal_impact` individually.
3. Shared variables live in dotter `[base.variables]` in `.dotter/global.toml`.

## Approach

Roles are already deployed as dotter `type = "template"` copies
(`.dotter/global.toml:27`). Researched dotter facts
(`.scratch/dotter-templating-research.md`, dotter 0.13.5 installed):

- Package variables in global.toml (`[base.variables]`) merge into one flat
  namespace for all enabled packages; both hosts enable `base` transitively
  (`macos` and `arch` both `depends` on it). Host `[variables]` can still
  override on clash.
- Dotter disables HTML escaping (`register_escape_fn(str::to_string)`), so
  `{{pi_tools_core}}` renders `read, grep, find, ls` verbatim.
- Strict mode is on: a typo'd variable fails `dotter deploy` loudly instead of
  rendering blank. Good failure mode for YAML frontmatter.

Frontmatter shape after change (e.g. developer.md):

```yaml
tools: [{{pi_tools_core}}, bash, write, replace, undo_last_replace, {{pi_tools_cymbal}}, cymbal_impact]
```

## Files to modify

- `.dotter/global.toml` — add under `[base.variables]`:
  `pi_tools_core = "read, grep, find, ls"`,
  `pi_tools_cymbal = "cymbal_search, cymbal_show, cymbal_refs"`
- `config/custom/pi/agent/pi-extensible-workflows/roles/*.md` (5 files) —
  frontmatter `tools:` uses the two variables
- `roles/tests-expert.md` — fix `"!test-driven-development"` → `"!tdd"`
  (verify actual skill name via doctor after deploy)
- `docs/reference/piewf-role-config.md` (new, small) — record: merge +
  last-match-wins semantics, `piewf doctor --role <role>` as the inspection
  tool, and the dotter shared-variable convention

## Reuse

- piewf's built-in `disabledAgentResources` merge — no custom mechanism
- Existing dotter template deployment of roles dir (global.toml:27) and
  variable pattern (`{{gh_binary}}` in gitconfig)
- `piewf` alias (`npx -y @piewf/cli`) for verification
- Research brief: `.scratch/dotter-templating-research.md`

## Steps

- [ ] Add `pi_tools_core` / `pi_tools_cymbal` to `[base.variables]` in
      `.dotter/global.toml` (next to the existing package sections)
- [ ] Rewrite `tools:` frontmatter in the 5 role files to use the variables:
  - developer: `[{{pi_tools_core}}, bash, write, replace, undo_last_replace, {{pi_tools_cymbal}}, cymbal_impact]`
  - reviewer: `[{{pi_tools_core}}, bash, {{pi_tools_cymbal}}, cymbal_impact]`
  - scout: `[{{pi_tools_core}}, write, {{pi_tools_cymbal}}]` — `write` is
    intentional: scout.md's own contract reads "`write` is for your findings
    file only. Never modify existing files. You have no bash." (findings-file
    pattern, mirrors the recon subagent). Drop it only if scouts should return
    findings inline instead of writing a file.
  - tests-expert: `[{{pi_tools_core}}, bash, {{pi_tools_cymbal}}]`
  - summarizer: `[]` (unchanged)
- [ ] Fix tests-expert skill negation: `["**", "!tdd"]` (confirm the skill's
      discovered name from doctor's excluded-skills list first)
- [ ] `dotter deploy` and confirm rendered
      `~/.config/pi/agent/pi-extensible-workflows/roles/*.md` have valid YAML
      lists (no leftover `{{`)
- [ ] Write `docs/reference/piewf-role-config.md`

## Verification

- `dotter deploy` succeeds (strict mode would fail on any variable typo)
- `piewf doctor --role <role>` for all 5 roles:
  - Tools list matches pre-change lists exactly (pure refactor — byte-for-byte
    same effective tools)
  - tests-expert: `tdd` skill now appears under *Effective skills* instead of
    excluded
- Spot-check one role end-to-end via a trivial `workflow` run using the role
