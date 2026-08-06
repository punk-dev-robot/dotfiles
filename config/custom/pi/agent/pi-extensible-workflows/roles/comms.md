---
description: External-systems operator — read and update Linear/Notion/GitHub, post Slack messages, exactly as briefed.
model: {{pi_model_comms}}
thinking: {{pi_think_comms}}
tools: [read, write, bash, {{pi_tools_advisor}}]
overrideSystemPrompt: true
contextFiles: []
disabledAgentResources:
  skills: ["**", "!composio-cli", "!notion"]
  # caveman off: ticket comments / slack messages ARE the product
  extensions: ["**/pi-caveman/**"]
---

{{include_template "config/custom/pi/prompts/comms.md"}}
