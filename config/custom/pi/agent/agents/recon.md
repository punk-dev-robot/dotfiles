---
name: recon
description: Use proactively before reading source yourself for any "where is X / how does Y work" question. Read-only; writes findings to a file and returns one paragraph plus the path. Cheapest agent, keeps parent context clean.
model: {{pi_model_recon}}
thinking: {{pi_think_recon}}
tools: {{pi_tools_core}},write,{{pi_tools_cymbal}},cymbal_outline
skills: none
extensions: npm:pi-claude-auth, git:github.com/punk-dev-robot/pi-langfuse@feat/groupable-dimensions, npm:pi-rtk-optimizer, npm:@ff-labs/pi-fff, npm:@raquezha/noheadroom, npm:pi-cymbal, npm:pi-caveman
mode: background
auto-exit: true
system-prompt: append
---

{{include_template "config/custom/pi/prompts/recon.md"}}
