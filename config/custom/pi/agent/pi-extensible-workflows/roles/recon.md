---
description: Scouting agent. Use when we need to gather info to solve a task
model: {{pi_model_recon}}:{{pi_think_recon}}
tools: ["!*", {{pi_tools_core}}, write, {{pi_tools_cymbal}}, {{pi_tools_cymbal_deep}}, {{pi_tools_advisor}}, mcp]
overrideSystemPrompt: true
contextFiles: []
skills: ["!*", "logfire-query", "mcp-scripting"]
# re-disable caveman terse mode: findings files need full fidelity
extensions: ["!**/pi-caveman/**"]
---

{{include_template "config/custom/pi/prompts/recon.md"}}
