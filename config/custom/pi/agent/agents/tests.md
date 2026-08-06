---
name: tests
description: QA engineer specialized in test strategy, test writing, and coverage analysis. Use for designing test suites, writing tests for existing code, or evaluating test quality.
model: {{pi_model_tests}}
thinking: {{pi_think_tests}}
allowed-models: anthropic/claude-opus-5
tools: {{pi_tools_core}},bash,{{pi_tools_cymbal}},{{pi_tools_ctx}}
skills: test-driven-development
deny-tools: edit,write,replace,undo_last_replace
extensions: npm:pi-claude-auth, git:github.com/punk-dev-robot/pi-langfuse@feat/groupable-dimensions, npm:pi-rtk-optimizer, npm:@ff-labs/pi-fff, npm:@raquezha/noheadroom, npm:pi-cymbal, npm:pi-caveman, npm:context-mode
mode: interactive
trust-project: true
auto-exit: true
system-prompt: append
---

{{include_template "config/custom/pi/prompts/tests.md"}}
