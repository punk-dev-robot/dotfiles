---
description: Reviewer. Use when we need to review decisions or code changes
model: {{pi_model_reviewer}}
thinking: {{pi_think_reviewer}}
tools: [{{pi_tools_core}}, bash, {{pi_tools_cymbal}}, {{pi_tools_cymbal_review}}, {{pi_tools_advisor}}]
overrideSystemPrompt: true
contextFiles: []
disabledAgentResources:
  skills: ["**"]
  # re-disable caveman terse mode: review rationale needs full fidelity
  extensions: ["**/pi-caveman/**"]
---

{{include_template "config/custom/pi/prompts/reviewer.md"}}
