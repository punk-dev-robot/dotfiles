---
name: reviewer
description: Senior code reviewer that evaluates changes across five dimensions — correctness, readability, architecture, security, and performance. Use for thorough code review before merge.
model: {{pi_model_reviewer}}
thinking: {{pi_think_reviewer}}
allowed-models: anthropic/claude-opus-5,anthropic/claude-fable-5
tools: {{pi_tools_core}},bash,{{pi_tools_cymbal}},cymbal_impact
skills: none
deny-tools: edit,write,replace,undo_last_replace
extensions: npm:pi-claude-auth, git:github.com/punk-dev-robot/pi-langfuse@feat/groupable-dimensions, npm:pi-rtk-optimizer, npm:@ff-labs/pi-fff, npm:@raquezha/noheadroom, npm:pi-cymbal, npm:pi-caveman
mode: interactive
trust-project: true
auto-exit: false
system-prompt: append
env: PI_SUBAGENT_HERDR_PLACEMENT=tab
---

{{include_template "config/custom/pi/prompts/reviewer.md"}}
