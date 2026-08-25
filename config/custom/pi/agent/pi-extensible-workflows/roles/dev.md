---
description: Developer focused agent
model: {{pi_model_dev}}:{{pi_think_dev}}
tools: ["!*", {{pi_tools_core}}, bash, {{pi_tools_edit}}, {{pi_tools_cymbal}}, cymbal_impact, cymbal_impls, cymbal_importers, {{pi_tools_advisor}}, ctx_*]
skills: ["!*", "cock-tdd", "cock-codebase-design"]
# opt back in to ponytail (lazy-dev minimal-code mode); off for agents globally
extensions: ["**/ponytail/**"]
---

{{include_template "config/custom/pi/prompts/dev.md"}}
