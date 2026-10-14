---
# dotter template (KUB-171): edit in ~/dotfiles, then `dotter deploy`. Vars: .dotter/global.toml [base.variables].
# Second-opinion reviewer on the OpenAI model (pr-principal-review skill). Same fields and body as reviewer.md;
# keep the two frontmatters in sync. Body shared via agent-bodies/reviewer.md.
name: reviewer-sol
description: Reviewer on the OpenAI model. Use for a second, independent review opinion (pr-principal-review default side B, vs reviewer-opus)
model: {{model_review_openai}}
thinking: xhigh
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
