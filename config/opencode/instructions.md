# OpenCode Instructions

## Tool Preferences

- `context7` tools are preferred for retrieving code documentation
- For web tasks, use the Composio CLI skill/workflow before built-in web tools
- For ordinary web search, start with `composio execute EXA_SEARCH --get-schema`, then run `EXA_SEARCH`
- Use `EXA_ANSWER` for direct answer-style search and `FIRECRAWL_SEARCH` when you want search results with extracted page content
- If you already have a URL, start with `composio execute EXA_GET_CONTENTS_ACTION --get-schema` or `composio execute FIRECRAWL_SCRAPE --get-schema`
- Use `composio search "<task>"` only when the right slug is genuinely unclear
- If arguments are unclear, use `composio execute <SLUG> --get-schema` or `--dry-run` before executing
- Prefer Exa-backed search and Firecrawl-backed scraping through Composio before built-in web alternatives

## Modern CLI Tools

Use modern replacements instead of legacy commands:

| Legacy | Modern | Purpose |
|--------|--------|---------|
| grep   | rg     | Search  |
| find   | fd     | Find files |
| sed    | sd     | Find & replace |
| ls     | eza    | List files |
| du     | dust   | Disk usage |
| df     | duf    | Free space |
| ps     | procs  | Processes |
| top/htop | btm | System monitor |
| dig/nslookup | dog | DNS |
| curl   | xh     | HTTP client |
| watch  | viddy  | Repeat command |
| cut    | choose | Column select |
| cloc   | tokei  | Count lines |
