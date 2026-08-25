---
description: Implementer for bounded, well-specified edits — known approach, smallest diff.
model: {{pi_model_impl}}:{{pi_think_impl}}
tools: ["!*", {{pi_tools_core}}, bash, {{pi_tools_edit}}, {{pi_tools_advisor}}, ctx_*]
overrideSystemPrompt: true
contextFiles: []
skills: ["!*"]
---

{{include_template "config/custom/pi/prompts/impl.md"}}
