# Herdr auto-naming: tabs, agents, panes

## Context

Workspaces prompt for a name on create (`prompt_new_workspace_name = true`) — fine. Tabs, panes, agents show defaults/nothing. Goal: meaningful names everywhere, harness-agnostic (herdr-side, not agent-side).

## Findings

### Existing marketplace plugins (evaluated)

| Plugin | Covers | Mechanism | Stack | Verdict |
|--------|--------|-----------|-------|---------|
| [qu8n/herdr-automatic-rename](https://github.com/qu8n/herdr-automatic-rename) | Tabs (foreground process, tmux-style; agent tabs show **task**, e.g. "Squash merge command"), `[N]` jump prefixes for workspaces/tabs/agents | Herdr events + optional shell hook for instant rename | **bash + jq** | **Chosen.** Manual renames win; `reset`/`clear` actions; config knobs (icons, label length, program lists) |
| [iurysza/herdr-tab-smart-rename](https://github.com/iurysza/herdr-tab-smart-rename) | Tabs only | Deterministic + **LLM** (OpenAI-compatible) for ambiguous work | Bun worker, API key | Not now — heavier, conflicts with qu8n on tabs; swap later if derived names insufficient |
| [sh1ma/herdr-auto-title](https://github.com/sh1ma/herdr-auto-title) | Tabs only | **Agent-side hooks** (Claude Code/Codex `UserPromptSubmit`) | python3 | Rejected: harness-specific |

### Coverage notes

- **Agents**: qu8n numbers them; agent *task titles* already flow via herdr integrations (`terminal_title_stripped` token already in your sidebar config).
- **Panes**: skipped (decided) — agent labels on pane borders (`show_agent_labels_on_pane_borders = true`) + tab names cover it; revisit if missed.

### Desired tab naming scheme (user-confirmed)

| Pane state | Tab label | qu8n support |
|------------|-----------|--------------|
| Agent running | agent's task title | ✓ built-in (`AGENT_TITLES=1`, default) |
| Other process | process name (e.g. `nvim`) | ✓ built-in, instant via zsh hook |
| Bare shell prompt | **cwd basename** | ✗ — hardcodes shell name; "minus the directory-based naming" is deliberate. No config knob, no override point |

---

## Part 1 — install & try the plugin (do now)

### Files to modify

- zsh config in dotfiles — source the plugin's `shell/hook.zsh` (instant rename on command start)
- `config/shared/herdr/config.toml` — `prompt_new_tab_name = false` already set ✓; optionally `window_title = "{hostname}: {workspace} · {tab}"`; optional keybinding for `herdr-automatic-rename.reset`
- Optional later: `~/.config/herdr-automatic-rename/config.sh` (from `config.example.sh`) for tuning — if used, keep in dotfiles + dotter

### Steps

- [ ] `herdr plugin install qu8n/herdr-automatic-rename --yes`
- [ ] Add zsh hook source line to dotfiles zsh config, `dotter deploy`
- [ ] Optionally extend `window_title` with `· {tab}`, `herdr server reload-config`
- [ ] Hand off to user: live with it, tweak `config.sh` knobs (icons, `MAX_NAME_LEN`, `HIDE_SHELL`, program lists)

### Verification (Part 1)

- New tab → `zsh`; run a command → process name instantly (hook); agent tab → task text
- Sidebar/tab bar rows get `[N]` matching `prefix+1..9` / `prefix+alt+1..9` jumps
- Manual rename sticks; `reset` re-adopts
- Workspace name prompt still works, typed names left alone

---

## Part 2 — basedir at bare prompt (ready, run only if missed after Part 1)

Everything routes through `ar_format` in the plugin's `naming.sh` (herdr events and the zsh `precmd` hook both), so this needs a code change, not config:

- [ ] Fork `qu8n/herdr-automatic-rename` → clone to `~/dev/oss/herdr-automatic-rename`
- [ ] Patch (~20 lines): new knob e.g. `SHELL_SHOWS_DIR=1` — when label would be a shell (`is_shell=1`), use pane-dir basename instead. Pane dir already available in the engine (used for title cleaning); zsh hook can pass `$PWD` on `precmd`. Run plugin's own tests
- [ ] Swap install: `herdr plugin uninstall herdr-automatic-rename`, then `herdr plugin link ~/dev/oss/herdr-automatic-rename`
- [ ] `SHELL_SHOWS_DIR=1` in `config.sh` (dotfiles + dotter)
- [ ] Open upstream PR (author responsive: all 8 issues closed, 3/5 PRs merged). Open PR #11 redesigns the label model — mention compatibility. If merged upstream, drop fork, reinstall from github

### Verification (Part 2)

- New tab at prompt → cwd basename; `cd` elsewhere → label follows on next prompt; back from a command → basedir again
