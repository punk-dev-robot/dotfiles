---
# dotter template (KUB-173): edit in ~/dotfiles, then `dotter deploy`. Vars: .dotter/global.toml [base.variables].
# Overlay of Herdsman's reserved `managed-lead` (Leads started by Manager `delegate_project`). Reserved rules:
# no `enabled` / `agents` / `permission`, `systemPromptMode` must stay `append`; Herdsman always injects the Lead
# coordination tools (delegate_agent & co, message_supervisor, list_peers, message_peer) on top of `tools:`.
# Body: appended to the bundled one (bodyMode: append). No pi-herdr: Herdsman owns the pane, and without herdr_* tools
# punk-steering's isSubagent() never sends this Lead into punk-handoff.
name: managed-lead
model: {{model_strong}}
thinking: high
systemPromptMode: append
bodyMode: append
inheritProjectContext: true
inheritGlobalContext: true
tools: [read, grep, find, ls, bash, write, edit, mcp, mcpScript, "repowise_*", ask_advisor, record_advisor_outcome, "ctx_*", codemode]
noSkills: true
skills:
  - "{{home_dir}}/.agents/skills/tessl__tdd/SKILL.md"
  - "{{home_dir}}/.agents/skills/tessl__codebase-design/SKILL.md"
  - "{{home_dir}}/.config/pi/agent/npm/node_modules/pi-mcp-adapter/skills/mcp-scripting/SKILL.md"
noExtensions: true
extensions:
  - "builtin:codemode"
{{#each ext_base}}
  - "{{@root.home_dir}}/.config/pi/agent/{{this}}"
{{/each}}
{{#each ext_bash_guard}}
  - "{{@root.home_dir}}/.config/pi/agent/{{this}}"
{{/each}}
{{#each ext_context_events}}
  - "{{@root.home_dir}}/.config/pi/agent/{{this}}"
{{/each}}
---

## Checkout setup, before the first edit

Herdr hooks finish after you start, so check your checkout against the main one (first line of `git worktree list`):

- The main checkout has `AGENTS.override.md` and yours has no readable one: read the main checkout's
  `AGENTS.override.md` and any `AGENTS.override.md` in its parent directory. They hold this repo's rules and
  were missing from your startup context.
- `node_modules` is missing while the main checkout has one: run `wt warm`.
