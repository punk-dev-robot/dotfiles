# Code Search Stack — ChunkHound, Serena, Bash(ugrep/bfs)

Three search subsystems coexist in this Claude Code setup. Use the right one for the question.

## The split

| Layer | Tool entry points | When to reach for it |
|---|---|---|
| **ChunkHound MCP** | `mcp__plugin_chunkhound-integration_ChunkHound__code_research`, `__search_semantic`, `__search_regex` | Conceptual discovery: "how does X work?", "trace the auth flow", cross-file patterns, onboarding |
| **Serena symbolic MCP** | `mcp__serena__find_symbol`, `__find_referencing_symbols`, `__get_symbols_overview`, `__replace_symbol_body`, `__insert_after_symbol`, `__rename_symbol` | LSP-grounded edits, refactors, "where is this called?", precise symbol surgery |
| **Native Bash** | `rg`, `ugrep`, `fd`, `bfs` invoked via `Bash` tool | Literal pattern, exact filename, fast-path everyday search |

## Why this layout

- Claude Code v2.1.117 removed the standalone `Glob`/`Grep` tools on native macOS/Linux builds (`anthropics/claude-code#51781`); searches route through Bash. We're on 2.1.126.
- `chunkhound-integration` plugin matched only on `Grep` — dormant on this build. Replaced by `~/.config/claude/hooks/suggest-chunkhound.py`, a `PreToolUse:Bash` hook that nudges toward ChunkHound when the pattern looks conceptual.
- Serena's overlap with ChunkHound (`search_for_pattern`, `list_dir`, `find_file`) is globally excluded in `~/.serena/serena_config.yml`. Symbolic tools remain — they cover LSP-grounded edits ChunkHound cannot.

## Configuration knobs

- **Global Serena exclusions:** `~/.serena/serena_config.yml` → `excluded_tools:`. Merges with per-project `.serena/project.yml` exclusions (see `serena/agent.py:140-200`).
- **Per-project Serena overrides:** drop a `.serena/project.yml` with its own `excluded_tools:` list. Defaults to `[]`.
- **ChunkHound nudge throttle:** 300s per session in `suggest-chunkhound.py`.
- **Serena `remind` PreToolUse hook:** hard-coded thresholds in `serena-hooks` (3 reads / 3 greps / 4 mixed). Ignores `excluded_tools`. Out of scope to tune.

## Anti-patterns

- Reaching for `rg` to map an unfamiliar architecture — use ChunkHound `code_research` instead.
- Renaming via `sd` / `rg --replace` — use Serena `rename_symbol` so references update.
- Editing a symbol body with `Edit` when you have not read it — `find_symbol --include_body` first.
