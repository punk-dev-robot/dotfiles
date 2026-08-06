# Dotfiles Configuration

## Summary

- [project] dotfiles - Personal configuration files for Arch Linux with Hyprland #main
- [type] Configuration Management #architecture
- [stack] Dotter, ZSH, Neovim, Hyprland, Modern CLI tools #tech

## Development Workflow

- [workflow] **Always** use `dotter` tool for linking config from this repo! `dotter` manages these dotfiles project and we should be dog-fooding it as much as possible #tooling
- [workflow] You can check and confirm changes before deployment with `dotter -v -d` or even with `-vv` for more verbosity #tooling

## Pi agents / workflow roles sync

- [sync] Prompt bodies live once, in `config/custom/pi/prompts/<name>.md`. Both the subagent (`config/custom/pi/agent/agents/<name>.md`) and the piewf role (`config/custom/pi/agent/pi-extensible-workflows/roles/<name>.md`) are dotter templates whose body is a single `{{include_template "config/custom/pi/prompts/<name>.md"}}`; model/thinking come from `pi_model_<name>` / `pi_think_<name>` in `.dotter/global.toml`. Names match 1:1 across both surfaces (`recon`, `researcher`, `dev`, `impl`, `reviewer`, `tests`, `comms`); `lead` is subagent-only. Edit the prompt source, then `dotter deploy` — never the deployed copies under `~/.config/pi/agent`. Frontmatter stays format-specific (subagent: mode/extensions/deny-tools; role: overrideSystemPrompt/disabledAgentResources) #workflow

## Documentation

@docs/README.md

## Agent skills

### Issue tracker

Issues tracked in GitHub Issues (punk-dev-robot/dotfiles) via `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at repo root. See `docs/agents/domain.md`.


# Agent Rules <!-- tessl-managed -->

@.tessl/RULES.md follow the [instructions](.tessl/RULES.md)
