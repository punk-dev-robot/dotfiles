# Global agent definitions that are symlinks are silently ignored

**Version:** pi-herdsman 0.26.0, Pi 1.2.0, Linux.

## What happens
Definition discovery uses `readdirSync(root, { withFileTypes: true })` and keeps only
`entry.isFile() && entry.name.endsWith(".md")` (`extension/agent-definitions.ts:156-159`).
A symlink is a `Dirent` with `isSymbolicLink()`, not `isFile()`, so it is dropped with no warning.

Dotfile managers (dotter, stow, chezmoi in symlink mode, home-manager) deploy
`~/.pi/agent/agents/*.md` as symlinks by default. In our case three `enabled: false`
overlays (`scout`, `implementer`, `generalist`) were symlinked: `list_agents` still showed the
bundled definitions as enabled and `delegate_agent scout` was accepted. Nothing in
`/herdsman definitions` hinted that the files existed.

## Expected
Either follow symlinks to regular files (`statSync` on symlink entries), or report a
definition error such as "skipped symlink <path>", matching the fail-loud behaviour for
malformed files.

## Workaround
Deploy real files instead of symlinks.
