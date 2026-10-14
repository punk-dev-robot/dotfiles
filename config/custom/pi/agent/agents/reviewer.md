---
# dotter template (KUB-171): edit in ~/dotfiles, then `dotter deploy`. Vars: .dotter/global.toml [base.variables].
# same-name overlay of the bundled Herdsman definition; every bundled field restated.
# Body shared with reviewer-sol: agent-bodies/reviewer.md (outside agents/: Herdsman parses every *.md under agents/ as a definition).
name: reviewer
description: Reviewer. Use when we need to review decisions or code changes
bodyMode: replace
model: {{model_sota}}
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
