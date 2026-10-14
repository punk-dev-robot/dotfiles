---
# dotter template (KUB-173): edit in ~/dotfiles, then `dotter deploy`. Vars: .dotter/global.toml [base.variables].
# Overlay of Herdsman's reserved `managed-lead` (Leads started by Manager `delegate_project`). Reserved rules:
# no `enabled` / `agents` / `permission`, `systemPromptMode` must stay `append`; Herdsman always injects the Lead
# coordination tools (delegate_agent & co, message_supervisor, list_peers, message_peer) on top of `tools:`.
# Body: none here, so the bundled body is kept. No pi-herdr: Herdsman owns the pane, and without herdr_* tools
# punk-steering's isSubagent() never sends this Lead into punk-handoff.
name: managed-lead
model: {{model_strong}}
thinking: high
systemPromptMode: append
inheritProjectContext: true
inheritGlobalContext: true
tools: [read, grep, find, ls, bash, write, edit, mcp, mcpScript, "repowise_*", ask_advisor, record_advisor_outcome, "ctx_*", codemode]
noSkills: true
skills:
  - "{{home_dir}}/.agents/skills/tdd/SKILL.md"
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
