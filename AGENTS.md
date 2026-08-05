# Dotfiles Configuration

## Summary

- [project] dotfiles - Personal configuration files for Arch Linux with Hyprland #main
- [type] Configuration Management #architecture
- [stack] Dotter, ZSH, Neovim, Hyprland, Modern CLI tools #tech

## Development Workflow

- [workflow] **Always** use `dotter` tool for linking config from this repo! `dotter` manages these dotfiles project and we should be dog-fooding it as much as possible #tooling
- [workflow] You can check and confirm changes before deployment with `dotter -v -d` or even with `-vv` for more verbosity #tooling

## Pi agents / workflow roles sync

- [sync] Subagent definitions (`config/custom/pi/agent/agents/`) and piewf workflow roles (`config/custom/pi/agent/pi-extensible-workflows/roles/`) share prompt bodies for paired workers: `dev↔developer`, `code-reviewer↔reviewer`, `recon↔scout`, `test-engineer↔tests-expert`. When editing one side's prompt body, copy it to the other. Frontmatter stays format-specific (subagent: mode/extensions/deny-tools; role: aliases/overrideSystemPrompt/disabledAgentResources) #workflow

## Documentation

@docs/README.md


# Agent Rules <!-- tessl-managed -->

@.tessl/RULES.md follow the [instructions](.tessl/RULES.md)
