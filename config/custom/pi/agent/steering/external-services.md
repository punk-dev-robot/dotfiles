---
kind: briefing
when:
  tools: [mcp, mcpScript]
---
## External services

1. Always use MCP servers first: `notion`, `linear`, `logfire`, `exa`, `firecrawl`.
2. `logfire` skills are usage guidance for the logfire MCP tools — load the `logfire-query`
   skill BEFORE the first logfire tool call of a session (gotchas like the default 30-min lookback).
3. Gmail/Calendar: no route yet — pending Google OAuth client (KUB-19).
4. Use `exa` and `firecrawl` MCP servers instead of built-in `WebSearch`/`WebFetch`.
