const DANGEROUS_PATTERNS: Array<[RegExp, string]> = [
  [
    /sudo\s+dotter/,
    "Do not run dotter with sudo. Dotter handles privilege escalation internally. Running with sudo deploys to /root/ and corrupts the cache.",
  ],
  [
    /dotter\s+undeploy/,
    "dotter undeploy removes ALL symlinks. This would break the entire dotfiles deployment.",
  ],
  [
    /rm\s+-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*\s+[~/]|rm\s+-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*\s+[~/]/,
    "Recursive force-delete on home or root directory. Too destructive.",
  ],
  [
    /chmod\s+-R\s+777/,
    "Recursive 777 permissions would break security on the entire tree.",
  ],
  [
    /\bdd\s+if=/,
    "Raw disk write via dd. Too dangerous to run without explicit user confirmation outside OpenCode.",
  ],
  [
    /\bmkfs\b/,
    "Filesystem formatting. Too dangerous to run without explicit user confirmation outside OpenCode.",
  ],
  [
    /git\s+push\s+.*(-f\b|--force(?!-with-lease)\b)/,
    "Force push can overwrite remote history. Use --force-with-lease for safer force pushes, or get explicit user confirmation.",
  ],
  [
    /git\s+reset\s+--hard\b/,
    "git reset --hard discards all uncommitted changes. This is destructive and irreversible.",
  ],
  [
    /git\s+clean\s+.*-[a-zA-Z]*f/,
    "git clean -f removes untracked files permanently. This is destructive and irreversible.",
  ],
]

export const BlockDanger = async () => {
  return {
    "tool.execute.before": async (
      input: { tool: string },
      output: { args: { command?: string } },
    ) => {
      if (input.tool !== "bash") return

      const command = output.args.command ?? ""
      for (const [pattern, reason] of DANGEROUS_PATTERNS) {
        if (pattern.test(command)) throw new Error(reason)
      }
    },
  }
}

export default BlockDanger
