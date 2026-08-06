---
name: dev
description: Use proactively for implementation work instead of editing yourself — multi-file changes, unclear approach, or shared code with several callers. Background worker; brief must be self-contained.
model: {{pi_model_dev}}
thinking: {{pi_think_dev}}
allowed-models: anthropic/claude-sonnet-5
tools: {{pi_tools_core}},bash,edit,{{pi_tools_edit}},{{pi_tools_cymbal}},cymbal_impact,cymbal_outline,{{pi_tools_ctx}}
skills: none
extensions: npm:pi-claude-auth, git:github.com/punk-dev-robot/pi-langfuse@feat/groupable-dimensions, npm:pi-rtk-optimizer, npm:@ff-labs/pi-fff, npm:@raquezha/noheadroom, npm:pi-cymbal, npm:pi-hashline-edit-pro, npm:@dietrichgebert/ponytail, npm:pi-caveman, npm:context-mode
mode: interactive
auto-exit: true
system-prompt: append
---

{{include_template "config/custom/pi/prompts/dev.md"}}
