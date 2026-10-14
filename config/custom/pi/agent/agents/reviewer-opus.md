---
# dotter template (KUB-171): edit in ~/dotfiles, then `dotter deploy`. Vars: .dotter/global.toml [base.variables].
# Reviewer variant (opus) (pr-principal-review skill). Same fields and body as reviewer.md;
# keep the two frontmatters in sync. Body shared via agent-bodies/reviewer.md.
name: reviewer-opus
description: Reviewer on the strong (opus) model. Use for an independent review opinion (pr-principal-review default side A)
model: {{model_strong}}
thinking: high
systemPromptMode: replace
inheritProjectContext: false
inheritGlobalContext: false
tools: [read, grep, find, ls, bash, mcp, mcpScript, "repowise_*", ask_advisor, record_advisor_outcome, "ctx_*", codemode]
agents: []
noSkills: true
skills:
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

@../agent-bodies/reviewer.md
