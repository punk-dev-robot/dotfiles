---
kind: briefing
when:
  tools: [mcp, mcpScript]
---
## External services

1. Always use MCP servers first: `notion`, `linear`, `logfire`, `exa`, `firecrawl`.
2. Before the first logfire query of a session, call the server's `query_schema_reference`
   tool (e.g. `logfire-swap_query_schema_reference`) — table schemas and gotchas like the
   default 30-min lookback.
3. Gmail/Calendar: no route yet — pending Google OAuth client (KUB-19).
4. Use `exa` and `firecrawl` MCP servers instead of built-in `WebSearch`/`WebFetch`.
5. Plannotator Inbox with no `plannotator_inbox` tool or `plannotator-inbox` MCP server loaded:
   tell the owner once ("inbox tool not loaded, reload the session") and ask in chat meanwhile.
