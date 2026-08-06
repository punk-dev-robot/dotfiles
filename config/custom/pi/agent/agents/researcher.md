---
name: researcher
description: External research — docs, APIs, versions, release notes; writes a cited brief to a file, no repo changes.
model: {{pi_model_researcher}}
thinking: {{pi_think_researcher}}
tools: read,write,bash,web_search,fetch_content,get_search_content,source_check
skills: composio-cli, research, notion
extensions: npm:pi-claude-auth, git:github.com/punk-dev-robot/pi-langfuse@feat/groupable-dimensions, npm:pi-rtk-optimizer, npm:@ff-labs/pi-fff, npm:@raquezha/noheadroom, npm:pi-caveman, npm:pi-web-access
mode: interactive
auto-exit: true
system-prompt: append
---

{{include_template "config/custom/pi/prompts/researcher.md"}}
