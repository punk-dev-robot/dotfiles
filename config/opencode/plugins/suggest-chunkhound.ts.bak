const SEARCH_CMDS = new Set(["rg", "ugrep", "fd", "bfs"])
const CONCEPT_TOKENS = [
  "how",
  "where",
  "flow",
  "auth",
  "handler",
  "router",
  "middleware",
  "lifecycle",
  "pipeline",
  "dispatcher",
  "controller",
  "renderer",
  "subscriber",
  "publisher",
  "scheduler",
  "interceptor",
  "resolver",
]
const REGEX_METACHARS = /[\[\](){}|*+?^$\\]/
const TTL_MS = 300000

function firstCommandToken(command: string): string {
  const tokens = command.match(/(?:[^\s"']+|"[^"]*"|'[^']*')+/g) ?? []
  while (tokens[0]?.includes("=") && !tokens[0].startsWith("-")) tokens.shift()
  if (tokens.length === 0) return ""

  let head = tokens[0].split("/").at(-1) ?? ""
  if (["bash", "sh", "zsh"].includes(head) && ["-c", "-lc"].includes(tokens[1])) {
    const inner = (tokens[2] ?? "").replace(/^['"]|['"]$/g, "")
    head = inner.trim().split(/\s+/)[0]?.split("/").at(-1) ?? ""
  }
  return head
}

function extractPattern(command: string, head: string): string {
  const tokens = command.match(/(?:[^\s"']+|"[^"]*"|'[^']*')+/g) ?? []
  while (tokens.length > 0 && (tokens[0].split("/").at(-1) ?? "") !== head) {
    tokens.shift()
  }
  if (tokens.length > 0) tokens.shift()

  const flagsWithValue = new Set(["-e", "-g", "-t", "-T", "--type", "--glob", "--regexp", "--iglob"])
  while (tokens.length > 0) {
    const token = tokens[0]
    if (token.startsWith("--") && token.includes("=")) {
      tokens.shift()
      continue
    }
    if (flagsWithValue.has(token)) {
      tokens.shift()
      tokens.shift()
      continue
    }
    if (token.startsWith("-")) {
      tokens.shift()
      continue
    }
    return token.replace(/^['"]|['"]$/g, "")
  }
  return ""
}

function looksConceptual(pattern: string, command: string): boolean {
  if (!pattern) return false
  if (/(^|\s)(-F|--fixed-strings)\b/.test(command)) return false
  if (pattern.split(/\s+/).length >= 2) return true
  const lower = pattern.toLowerCase()
  if (CONCEPT_TOKENS.some((token) => lower.includes(token))) return true
  return REGEX_METACHARS.test(pattern) && pattern.length > 12
}

export const SuggestChunkHound = async () => {
  const seen = new Map<string, number>()

  return {
    "tool.execute.before": async (
      input: { tool: string; sessionID?: string; sessionId?: string },
      output: { args: { command?: string } },
    ) => {
      if (input.tool !== "bash") return

      const command = output.args.command ?? ""
      const head = firstCommandToken(command)
      if (!SEARCH_CMDS.has(head)) return

      const pattern = extractPattern(command, head)
      if (!looksConceptual(pattern, command)) return


      const sessionID = input.sessionID ?? input.sessionId ?? "default"
      const now = Date.now()
      const lastSeen = seen.get(sessionID) ?? 0
      if (now - lastSeen < TTL_MS) return
      seen.set(sessionID, now)

      throw new Error(
        `This ${head} query looks conceptual (pattern: ${JSON.stringify(pattern)}). Use ChunkHound MCP first: code_research for deep research, search_semantic for meaning-based discovery, search_regex for cross-file pattern matches. Retry the Bash search if you already decided text search is right.`,
      )
    },
  }
}

export default SuggestChunkHound
