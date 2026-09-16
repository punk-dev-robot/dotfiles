---
kind: briefing
when:
  tools: [web_search, fetch_content]
---
## Web research routing

- Quick lookup needing a cited answer now → `web_search` (synthesized, ~4KB into
  session; cheapest per-question in the main session).
- Read one URL / PDF / YouTube / GitHub repo → `fetch_content` (stores full
  content; recall later with `get_search_content`).
- Bulk or exploratory research → `researcher` subagent (it should prefer exa MCP:
  fastest raw full-text search; raw bytes stay in its context, you get a brief).
- Scrape/crawl/map a site or structured extraction → firecrawl MCP (lazy).
- exa/firecrawl raw results in the main session arrive output-guarded (tempfile +
  summary); digest the tempfile with `ctx_execute_file`, don't read it raw.
- `source_check` is disabled by config (web-search.json) — verify claims via
  `web_search` + judgement.
