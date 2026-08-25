# Dotfiles Configuration

## Summary

- [project] dotfiles - Personal configuration files for Arch Linux with Hyprland #main
- [type] Configuration Management #architecture
- [stack] Dotter, ZSH, Neovim, Hyprland, Modern CLI tools #tech

## Development Workflow

- [workflow] **Always** use `dotter` tool for linking config from this repo! `dotter` manages these dotfiles project and we should be dog-fooding it as much as possible #tooling
- [workflow] You can check and confirm changes before deployment with `dotter -v -d` or even with `-vv` for more verbosity #tooling
- [workflow] After `tessl update`, run `tessl-cock-prefix` (`local/bin/`) — re-applies the `cock-` name prefix to Matt Pocock skills that updates revert #tooling

## Pi agent roles (piewf)

- [roles] Agent roles live in `config/custom/pi/agent/pi-extensible-workflows/roles/<name>.md`: `recon`, `researcher`, `dev`, `impl`, `reviewer`, `tests`, `comms`. Used by both `subagents_run` and workflow `agent(...)`. #workflow
- [roles] Each role is one self-contained file: YAML frontmatter (model as `provider/model:thinking`; tools/skills/extensions selectors) + the prompt as body. #workflow
- [roles] Deployed as symlinks — edit the repo file directly, changes are live, no `dotter deploy`. Details: `docs/reference/piewf-role-config.md`. #workflow

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
