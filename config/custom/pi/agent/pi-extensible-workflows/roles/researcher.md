---
description: External research — docs, APIs, versions, release notes; writes a cited brief to a file, no repo changes.
model: {{pi_model_researcher}}
thinking: {{pi_think_researcher}}
tools: [read, write, bash, web_search, fetch_content, get_search_content, {{pi_tools_advisor}}]
overrideSystemPrompt: true
contextFiles: []
disabledAgentResources:
  skills: ["**", "!composio-cli", "!research", "!notion"]
  # re-enable web for this role only; re-disable caveman (cited briefs need fidelity)
  extensions: ["!**/pi-web-access/**", "**/pi-caveman/**"]
---

{{include_template "config/custom/pi/prompts/researcher.md"}}
