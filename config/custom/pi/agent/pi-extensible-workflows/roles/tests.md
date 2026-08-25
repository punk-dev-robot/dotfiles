---
description: Agent focused in writing/reading tests
model: {{pi_model_tests}}:{{pi_think_tests}}
tools: ["!*", {{pi_tools_core}}, bash, {{pi_tools_edit}}, {{pi_tools_cymbal}}, cymbal_impact, {{pi_tools_advisor}}, ctx_*]
skills: ["!*", "cock-tdd"]
---

{{include_template "config/custom/pi/prompts/tests.md"}}
