const MODERN_ALTERNATIVES: Record<string, string> = {
  grep: "rg",
  find: "fd",
  sed: "sd",
  ls: "eza",
  du: "dust",
  df: "duf",
  ps: "procs",
  top: "btm",
  htop: "btm",
  dig: "dog",
  nslookup: "dog",
  curl: "xh",
  watch: "viddy",
  cut: "choose",
  cloc: "tokei",
}

const LEGACY_PATTERN = new RegExp(
  "\\b(" + Object.keys(MODERN_ALTERNATIVES).join("|") + ")\\b",
)

export const ModernCLIWarn = async () => {
  return {
    "tool.execute.before": async (
      input: { tool: string },
      output: { args: { command?: string } },
    ) => {
      if (input.tool !== "bash") return
      const command = output.args.command ?? ""
      const matches = [...new Set(command.match(LEGACY_PATTERN) ?? [])]
      if (matches.length > 0) {
        const suggestions = matches
          .map((t) => `Use '${MODERN_ALTERNATIVES[t]}' instead of '${t}'`)
          .join(", ")
        throw new Error(`Modern CLI alternatives: ${suggestions}`)
      }
    },
  }
}
