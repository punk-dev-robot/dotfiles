# Implementation Plan: tmux

**Branch**: `migrated-tmux` | **Date**: 2026-04-15 | **Spec**: `specs/tmux/spec.md`
**Input**: Reverse-engineered from the existing tmux config, helper scripts, Dotter mappings, and tmux reference docs

## Summary

The `tmux` feature combines a templated tmux configuration with a small set of tmux lifecycle scripts and a documented Linux systemd integration model. The core feature delivers a customized tmux environment, plugin-backed navigation and session workflows, platform-conditional persistence behavior, and supporting docs that explain restore/save orchestration and race-condition debugging.

## Technical Context

**Project Type**: Dotter-managed configuration monorepo  
**Primary Technologies**: tmux config, shell scripts, Dotter templates, Markdown docs  
**Deployment Layer**: Dotter via `.dotter/global.toml`  
**Validation**: `dotter -v -d` for deployment-level validation; runtime validation through tmux behavior, helper scripts, and `test-tmux-alacritty.sh`  
**Platform Scope**: `common` plus Linux/macOS conditional behavior  
**Risk Level**: medium, because tmux is central to daily terminal workflows and interacts with desktop/session lifecycle behavior

## Constitution Check

*GATE: Must pass before implementation and again before completion.*

- The feature spans the correct boundaries: `config/`, `local/`, `.dotter/`, and `docs/`.
- Dotter ownership is explicit at `.dotter/global.toml:117-121` and the helper script mappings under `bin-common`.
- Validation is targeted: tmux runtime behavior, helper scripts, and the integration test script rather than generic app commands.
- The feature does not rely on `.specify/`.
- Documentation already exists and is part of the real feature boundary.

## Project Structure

### Feature Documentation

```text
specs/tmux/
├── spec.md
├── plan.md
└── tasks.md
```

### Repository Boundaries

```text
.dotter/   package selection, target mappings, template variables
config/    user-level application configs
local/     helper scripts and runtime wrappers
docs/      curated reference and troubleshooting material
```

### Structure Decision

The migrated feature is centered on `config/tmux/tmux.conf`, but the actual implementation boundary includes helper scripts and documentation:

```text
config/tmux/
└── tmux.conf

local/bin/
├── tmux-sync-env.sh
├── tmux-save-wrapper.sh
├── tmux-restore-wrapper.sh
├── tmux-cleanup-sessions.sh
└── test-tmux-alacritty.sh

docs/reference/tmux/
├── index.md
├── systemd-integration.md
└── race-condition-troubleshooting.md
```

This is the right feature boundary because the helper scripts and docs are not incidental; they are part of how tmux persistence and orchestration actually work in this repo.

## Reverse-Engineered Implementation Phases

### Phase 0: Deploy The Base tmux Config

- Add `config/tmux/tmux.conf` and deploy it through the Dotter `tmux` package.
- Use Dotter templating to vary Linux/macOS behavior and plugin manager paths.

### Phase 1: Define Interactive tmux Behavior

- Configure terminal options, numbering, rename behavior, clipboard, status line, and keybindings.
- Add plugin declarations and plugin-specific settings for theming, session helpers, floating panes, URL handling, and Neovim coordination.

### Phase 2: Add Session Lifecycle Tooling

- Add helper scripts for syncing environment values into tmux.
- Add wrappers for tmux-resurrect save and restore flows.
- Add cleanup logic for old resurrect save files.
- Add an integration-style script for the Linux tmux/alacritty/systemd startup path.

### Phase 3: Document And Stabilize Platform Workflows

- Document Linux systemd orchestration and persistence flow in `docs/reference/tmux/systemd-integration.md`.
- Preserve troubleshooting history for startup race conditions in `docs/reference/tmux/race-condition-troubleshooting.md`.
- Keep macOS persistence behavior distinct from Linux systemd orchestration.

## Complexity Tracking

| Complexity | Why Needed | Simpler Alternative Rejected Because |
|------------|------------|--------------------------------------|
| Cross-boundary feature | tmux behavior depends on config, helper scripts, Dotter templating, and docs | Treating `tmux.conf` alone as the whole feature would miss persistence/orchestration behavior |
| Platform-specific persistence | Linux and macOS use different persistence approaches | A single shared persistence model would not match the actual implementation |

## Gaps And Risks

- There is no single uniform automated test suite for the whole feature; validation is distributed between runtime behavior, scripts, and one integration-style test script.
- The feature has a documented dependency on surrounding systemd/alacritty/session behavior on Linux, so some behavior is broader than tmux alone.
- Neovim integration is real, but ownership is shared across features and should stay documented rather than collapsed into one config file.
