---
kind: briefing
when:
  tools: [delegate_agent]
---
## RPI skill (`/skill:rpi`) on this setup

RPI names Claude Code subagents that don't exist here. Route them, passing the RPI
subagent file as `<instructions>` (its own fallback); the definition's return contract
(findings file + paragraph) still applies:

- `codebase-locator`, `codebase-analyzer`, `codebase-pattern-finder`, "Explore agent" → `recon`
- `web-search-researcher` → `researcher`
- `outline-implementer-agent` → `dev`; `impl` only for a tight, mechanical outline phase

Max 4 parallel investigations, not RPI's 2-6. `recon` has no bash: checks get run by the
main session, recorded as "checks run". HTML visuals open with `xdg-open` on Linux
(`open` on macOS).

Override RPI's final-answer templates: never offer VS Code, Cursor or "your editor". Offer
review via the `plannotator-tui` skill instead ("Want to review it in plannotator?").
Delete helper scratch files (e.g. `.findings-*.md`) from the task dir once synthesized.
