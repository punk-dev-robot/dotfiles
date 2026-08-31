# KUB-17: Repowise setup & migration — phase 1

## Recovered context

- Research (25 Aug, `~/dev/swapc/research/repowise-overview.md`): Repowise chosen.
  PyPI `repowise` v0.45.0, AGPL, Python ≥3.11. `repowise init` → `.repowise/`
  (SQLite + LanceDB). 40+ CLI cmds, dashboard, MCP server (stdio/streamable-HTTP,
  `mcp.tools: lean` ≈2.1k schema tokens). `--no-prose` = zero-LLM pilot.
  Worktrees first-class (linked worktree auto-seeds from base checkout).
  Telemetry on by default → opt out.
- Nothing repowise-related committed to dotfiles yet; branch `KUB-17-repowise` == main.
- User decisions this session: wire test pi instance **first**; tool replacements
  (context-mode / cymbal / readseek) tested + discussed one by one later.

## Env var

`PI_CODING_AGENT` is only a `true` marker. Correct var: **`PI_CODING_AGENT_DIR`**
(overrides config dir, default `~/.pi/agent`). Catch: that dir mixes dotter-managed
config with runtime state (auth.json, npm/, sessions/, caches, DBs) — can't point it
at the worktree directly.

## Phase 1 (this session)

### 1. `local/bin/pi-rw` wrapper (new file)

Bash script that:
- wipes + rebuilds `~/.config/pi-repowise` as a mirror of `~/.config/pi/agent`:
  - symlinks targeting `~/dotfiles/...` (dotter-managed) → re-pointed to
    `~/dotfiles.KUB-17-repowise/...`
  - dirs containing nested dotter links (`config/`, `extensions/`, `headroom/`,
    `pi-extensible-workflows/`, `workflows/`, …) → replicated recursively with the
    same rewrite
  - everything else (auth, npm, sessions, caches, state) → symlinked to the real
    entry, shared with the default instance
- `PI_CODING_AGENT_DIR=~/.config/pi-repowise exec pi "$@"`

Mirror regenerated on every launch — always fresh, no drift.

### 2. Verify

- Run mirror, spot-check: `settings.json` in sandbox resolves to worktree; `auth.json`
  resolves to real agent dir.
- `pi-rw -p "reply ok"` boots with all extensions, no errors.

### 3. Commit

`pi: add pi-rw test-instance wrapper for repowise worktree` on this branch.

## Later phases (ticket checklist)

1. ~~Install repowise, init, MCP wiring~~ **DONE (phase 2, 31 Aug)**: repowise 0.47.0
   via `uv tool install`, telemetry disabled, `init --no-prose` on `~/dotfiles`
   (worktree auto-seeds, verified) + shopai/shopmr (`--no-editor-setup`).
   MCP lean profile (6 tools, cwd-based `.`) in `config/custom/pi/agent/mcp.json`;
   tested end-to-end via `pi-rw`. Editor-wiring files deleted (user decision).
2. ~~Per-tool discussion~~ **DONE**: context-mode kept (orthogonal; codebase Qs
   reroute to repowise). Cymbal trimmed to `changed`+`impact` in `tools.json`
   (13 deactivated; refs→readSeek_refs, search/context/why→repowise, ~3.7k token save).
   Readseek kept whole (edit machinery, no overlap).
3. ~~Update agent roles~~ **DONE**: dev/recon/reviewer/tests re-tooled.
4. ~~AGENTS.md~~ **DONE**: "Codebase intelligence routing" section added.
5. Webhooks/extensions.
6. Other harnesses (needs human discussion).
7. Follow-up: embedder for semantic search (keyword-only today, `embedder: mock`;
   Ollama not installed — decide later). MCP arg shapes: `get_symbol` needs
   `symbol_id` = `path::Name`, `get_context` needs `targets` array.

Skipped: dotter profile for the sandbox (wrapper regeneration covers it); isolated
sessions dir (shared is fine, add `PI_CODING_AGENT_SESSION_DIR` only if test noise
becomes a problem).
