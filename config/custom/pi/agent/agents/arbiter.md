---
# dotter template (KUB-171): edit in ~/dotfiles, then `dotter deploy`. Vars: .dotter/global.toml [base.variables].
# Neutral arbiter for the pr-principal-review skill: reads both reviewers' final positions, writes the report.
# No bash: the Lead passes the diff as a file; `write` creates the report directory.
name: arbiter
description: Neutral arbiter. Use to rule between two reviewers' final positions and write the consensus review report
model: {{model_sota}}
thinking: high
systemPromptMode: replace
inheritProjectContext: false
inheritGlobalContext: false
tools: [read, grep, find, ls, write, mcp, mcpScript, "repowise_*", ask_advisor, record_advisor_outcome, "ctx_*", codemode]
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
{{#each ext_context_events}}
  - "{{@root.home_dir}}/.config/pi/agent/{{this}}"
{{/each}}
---

@../agent-bodies/arbiter.md
