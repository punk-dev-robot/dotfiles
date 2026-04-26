# OpenCode Caveman Integration

## Scope

Caveman is enabled globally for the user through the dotfiles-managed OpenCode config at `config/opencode/opencode.jsonc`.

Dotter maps `config/opencode` to `~/.config/opencode`, so the plugin is user-scope, not repo-scope.

## Plugin

The OpenCode plugin lives at `config/opencode/plugins/caveman.ts` and is loaded before the other local plugins.

It mirrors the upstream Claude hook behavior from `JuliusBrussee/caveman`:

- injects Caveman instructions on `session.start`
- tracks `/caveman` mode requests through `command.execute.before`, `chat.message`, `message.part.updated`, and TUI command events
- reinforces Caveman rules during system prompt transform and compaction when those hooks are available
- reads the installed skill from `~/.agents/skills/caveman/SKILL.md` when present

## State

Runtime mode state is stored outside the dotfiles tree:

```text
~/.local/state/opencode/caveman-mode.json
```

This avoids dirtying `~/dotfiles` when mode changes during normal OpenCode use.

## Defaults

Default mode resolution:

1. `CAVEMAN_DEFAULT_MODE`
2. `~/.config/caveman/config.json` with `defaultMode`
3. `full`

Supported modes: `lite`, `full`, `ultra`, `wenyan-lite`, `wenyan-full`, `wenyan-ultra`. `wenyan` is treated as `wenyan-full`.

Use `stop caveman`, `normal mode`, or `caveman off` to disable until re-enabled.

The global `/caveman` command stub lives at `config/opencode/command/caveman.md`; it exists so OpenCode routes slash-command mode switches through the plugin.
