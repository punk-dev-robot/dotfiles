# Agent Boundaries

## Purpose

This repository is primarily a dotfiles/configuration repository.

It also contains an auxiliary workspace under `.specify/` used to practice SDD and try plugins.

There are therefore two work modes:

- host dotfiles configuration work
- auxiliary spec-tooling work under `.specify/`

Agents should stay inside the owning boundary unless a feature explicitly spans both.

## Ownership

| Area | Owner | Responsibility |
|------|-------|----------------|
| `.dotter/` | Dotter Agent | Package selection, target mappings, host variables, deploy hooks |
| `config/` | Config Agent | User-level application configs such as Hyprland, Neovim, Zsh, tmux, Rio, Hammerspoon, Karabiner |
| `etc/` | System Config Agent | System-level templates and `/etc`-targeted configuration |
| `local/` | Script Agent | Local scripts, wrappers, desktop entries, support assets |
| `docs/` | Docs Agent | Curated reference, troubleshooting, plans, archive |
| `.specify/templates/` and `.specify/memory/` | Spec Bootstrap Agent | Auxiliary spec-kit bootstrap and template customization for SDD practice |
| `.specify/extensions/*` | Extension Agent | Optional plugin/extension experiments, tests, and extension-local conventions |

## Coordination Rules

- Changes that move deployable files or alter ownership must coordinate between the primary agent and the Dotter Agent.
- Changes in `config/`, `etc/`, or `local/` that affect user-facing behavior should coordinate with the Docs Agent.
- Changes under `.specify/templates/` or `.specify/memory/` should not casually modify `.specify/extensions/*`.
- Changes under `.specify/extensions/*` should preserve extension-local test conventions and should not redefine the main repo purpose away from dotfiles/configuration work.

## No-Overlap Guidance

- Treat `.specify/templates/` and `.specify/extensions/*` as separate ownership zones.
- Treat `etc/` as a higher-risk zone than `config/` and avoid bundling unrelated system changes with normal user-config work.
- When a feature spans multiple zones, document the dependency direction in the spec and plan before implementation starts.
