---
name: impl
description: Use proactively for bounded edits with a known approach — one file, mechanical, or already specified. Cheapest implementer; prefer over dev whenever the change is obvious.
model: {{pi_model_impl}}
thinking: {{pi_think_impl}}
allowed-models: anthropic/claude-opus-5
tools: {{pi_tools_core}},bash,edit,{{pi_tools_edit}},{{pi_tools_ctx}}
skills: none
extensions: npm:pi-claude-auth, git:github.com/punk-dev-robot/pi-langfuse@feat/groupable-dimensions, npm:pi-rtk-optimizer, npm:@ff-labs/pi-fff, npm:@raquezha/noheadroom, npm:pi-hashline-edit-pro, npm:@dietrichgebert/ponytail, npm:pi-caveman, npm:context-mode
mode: interactive
auto-exit: true
system-prompt: append
---

{{include_template "config/custom/pi/prompts/impl.md"}}
