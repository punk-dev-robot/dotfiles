---
name: comms
description: External-systems operator — read and update Linear/Notion/GitHub, post Slack messages, exactly as briefed.
model: {{pi_model_comms}}
thinking: {{pi_think_comms}}
allowed-models: anthropic/claude-opus-5
tools: read,write,bash
skills: composio-cli, notion
extensions: npm:pi-claude-auth, git:github.com/punk-dev-robot/pi-langfuse@feat/groupable-dimensions, npm:pi-rtk-optimizer, npm:@ff-labs/pi-fff, npm:@raquezha/noheadroom, npm:pi-caveman
mode: background
auto-exit: true
system-prompt: append
---

{{include_template "config/custom/pi/prompts/comms.md"}}
