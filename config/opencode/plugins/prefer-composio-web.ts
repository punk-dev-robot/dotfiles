const SEARCH_TOOLS = new Set(["WebSearch", "websearch"])
const FETCH_TOOLS = new Set(["WebFetch", "webfetch"])

function buildMessage(tool: string): string {
  if (SEARCH_TOOLS.has(tool)) {
    return [
      "Use the Composio CLI skill/workflow before built-in web search.",
      "For ordinary web search, start with `composio execute EXA_SEARCH --get-schema` and then run `EXA_SEARCH`.",
      "Use `EXA_ANSWER` for a direct answer with citations, or `FIRECRAWL_SEARCH` when you specifically want search results with page-content extraction.",
      "Use `composio search \"<task>\"` only if the right slug is genuinely unclear.",
      "If Composio fails or you run out of third-party credits, retry the built-in tool as fallback.",
    ].join(" ")
  }

  return [
    "Use the Composio CLI skill/workflow before built-in web fetch.",
    "If you already have a URL, skip broad discovery and start with `composio execute EXA_GET_CONTENTS_ACTION --get-schema` or `composio execute FIRECRAWL_SCRAPE --get-schema`.",
    "Use `EXA_GET_CONTENTS_ACTION` for fetching page text/highlights from a known URL and `FIRECRAWL_SCRAPE` for scrape-focused page retrieval.",
    "Use `composio search \"<task>\"` only if the right slug is genuinely unclear.",
    "If Composio fails or you run out of third-party credits, retry the built-in tool as fallback.",
  ].join(" ")
}

export const PreferComposioWeb = async () => {
  const seen = new Map<string, number>()
  const TTL_MS = 120000

  return {
    "tool.execute.before": async (
      input: { tool: string; sessionID?: string; sessionId?: string },
    ) => {
      const tool = input.tool
      if (!SEARCH_TOOLS.has(tool) && !FETCH_TOOLS.has(tool)) return

      const sessionID = input.sessionID ?? input.sessionId ?? "default"
      const key = `${sessionID}:${tool}`
      const now = Date.now()
      const lastSeen = seen.get(key)

      if (lastSeen && now - lastSeen < TTL_MS) {
        seen.delete(key)
        return
      }

      seen.set(key, now)
      throw new Error(buildMessage(tool))
    },
  }
}

export default PreferComposioWeb
