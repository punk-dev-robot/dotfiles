# Feature Specification: tmux

**Feature Branch**: `migrated-tmux`  
**Created**: 2026-04-15  
**Status**: migrated  
**Input**: Reverse-engineered from `config/tmux/`, related `local/bin/tmux-*` scripts, and `.dotter/global.toml`

## Scope *(mandatory)*

### Affected Boundaries

- [x] `config/`
- [ ] `etc/`
- [x] `local/`
- [x] `.dotter/`
- [x] `docs/`

Optional, only if the feature explicitly targets SDD/tooling work:

- [ ] `.specify/`

### Affected Paths

- `config/tmux/tmux.conf`
- `local/bin/tmux-sync-env.sh`
- `local/bin/tmux-cleanup-sessions.sh`
- `local/bin/tmux-save-wrapper.sh`
- `local/bin/tmux-restore-wrapper.sh`
- `local/bin/test-tmux-alacritty.sh`
- `docs/reference/tmux/`
- `.dotter/global.toml`

### Platform Scope

- [x] `common`
- [x] `linux`
- [ ] `arch`
- [x] `macos`
- [ ] Not package-scoped

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Use A Personalized tmux Environment (Priority: P1)

As the repo owner, I want tmux to start with my preferred keybindings, pane/window behavior, terminal capabilities, and status-line theming so terminal work begins in a consistent environment.

**Why this priority**: The core tmux configuration is the entrypoint for the entire feature.

**Independent Test**: Deploy the config with Dotter, start tmux, and verify the custom prefix, split/navigation bindings, status behavior, and plugin-managed UI load without errors.

**Acceptance Scenarios**:

1. **Given** `config/tmux/tmux.conf` is deployed, **When** tmux starts, **Then** the customized prefix, numbering, mouse, clipboard, terminal, and status options are applied.
2. **Given** tmux is running, **When** window and pane management bindings are used, **Then** they operate with the configured current-path and numbering behavior.

---

### User Story 2 - Navigate And Search Efficiently Inside Sessions (Priority: P2)

As the repo owner, I want tmux plugin workflows for pane navigation, floating panes, session switching, URL picking, and copy-mode ergonomics so I can move quickly through terminal work.

**Why this priority**: The configuration clearly goes beyond defaults and depends on multiple tmux plugins for daily workflow.

**Independent Test**: Use the configured bindings and plugin commands inside tmux and verify the enabled workflows are available.

**Acceptance Scenarios**:

1. **Given** the tmux plugin manager path is valid, **When** tmux loads plugins, **Then** configured plugins such as catppuccin, tmux.nvim, floax, sessionx, thumbs, and fzf-url are active.
2. **Given** copy mode or navigation is in use, **When** the configured keys are pressed, **Then** the expected pane, session, or copy-mode action occurs.

---

### User Story 3 - Preserve Session State Across Restarts (Priority: P3)

As the repo owner, I want tmux session state to be saved, restored, and cleaned up through helper scripts and platform-specific persistence mechanisms so terminal state survives reboots and restarts with minimal manual recovery.

**Why this priority**: Session persistence and restore orchestration is a major part of the actual feature, especially on Linux.

**Independent Test**: Trigger the save/restore helpers and confirm session validation, restore behavior, and cleanup behavior follow the documented tmux-resurrect workflow.

**Acceptance Scenarios**:

1. **Given** a valid multi-session tmux environment, **When** `tmux-save-wrapper.sh` runs, **Then** it validates required sessions before allowing tmux-resurrect to save state.
2. **Given** previously saved session state exists, **When** `tmux-restore-wrapper.sh` runs, **Then** it restores sessions through tmux-resurrect and logs before/after state.

---

### User Story 4 - Keep tmux In Sync With The Desktop Session (Priority: P4)

As the repo owner, I want tmux to refresh environment variables and integrate with the surrounding terminal/session environment so long-running tmux sessions do not drift from the active desktop session.

**Why this priority**: This is valuable but depends on the core tmux environment already being active.

**Independent Test**: Run the environment sync path and confirm configured environment variables propagate from the systemd user environment into tmux.

**Acceptance Scenarios**:

1. **Given** Linux-specific `update-environment` variables are configured, **When** the tmux environment sync binding is used, **Then** tmux global environment values are updated or removed to match the systemd user environment.

## Edge Cases *(mandatory)*

- What happens when tmux plugins are not installed at the configured TPM path?
- What happens when tmux-resurrect save/restore scripts are missing or not executable?
- What happens when required sessions such as `dots`, `work`, or `dropterm` do not exist at save time?
- What happens when Linux-specific environment synchronization is invoked outside a compatible systemd user session?
- What happens when tmux is used without the surrounding systemd/alacritty workflow that some docs and scripts assume?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The feature MUST deploy `config/tmux/` through the Dotter `tmux` package mapping.
- **FR-002**: The feature MUST template `config/tmux/tmux.conf` so platform-conditional behavior can differ between Linux and macOS.
- **FR-003**: The feature MUST configure custom tmux keybindings for prefix handling, window creation, pane splitting, swapping, copy mode, and config reload.
- **FR-004**: The feature MUST configure terminal capability and status-line behavior for the terminals actively used in the repo.
- **FR-005**: The feature MUST load and configure the tmux plugin manager path through Dotter variables.
- **FR-006**: The feature MUST provide plugin-driven workflows for theming, pane/session navigation, floating panes, and link/selection helpers.
- **FR-007**: The feature MUST provide helper scripts for environment sync, restore, save validation, and save cleanup.
- **FR-008**: The feature MUST support session persistence behavior that differs by platform: Linux via surrounding systemd/session orchestration and macOS via tmux-resurrect/tmux-continuum plugin configuration.
- **FR-009**: The feature MUST document the Linux tmux/systemd integration and known race-condition behavior in repo docs.
- **FR-010**: The feature MUST preserve the existing Neovim/tmux navigation contract without requiring the tmux spec to own Neovim configuration itself.

### Boundary-Specific Requirements

#### `config/` Changes

- `config/tmux/tmux.conf` is the main feature entrypoint and behavior surface.

#### `local/` Script Changes

- `local/bin/tmux-sync-env.sh` manages environment synchronization.
- `local/bin/tmux-save-wrapper.sh`, `tmux-restore-wrapper.sh`, and `tmux-cleanup-sessions.sh` support persistence and lifecycle management.
- `local/bin/test-tmux-alacritty.sh` provides integration-style validation for the Linux/systemd terminal workflow.

#### `.dotter/` Changes

- `.dotter/global.toml` MUST continue to map `config/tmux` and the tmux helper scripts into their deployed locations.

#### `docs/` Changes

- `docs/reference/tmux/` documents the intended architecture and troubleshooting context for the feature.

## Success Criteria *(mandatory)*

- **SC-001**: A deployed machine can start tmux with the managed config and use the customized keybindings and status behavior.
- **SC-002**: tmux helper scripts cover environment synchronization, session save, restore, and cleanup workflows.
- **SC-003**: The feature’s Linux systemd/session workflow is documented well enough that the restore/save architecture can be understood from repo docs.
- **SC-004**: Platform-specific behavior remains explicit instead of hidden in undocumented assumptions.

## Assumptions

- External tmux plugins and tmux-resurrect scripts are installed separately from these repo artifacts.
- The Linux workflow assumes a systemd user session and terminal/session orchestration described in `docs/reference/tmux/`.
- The feature is maintained as personal terminal/session infrastructure rather than as a reusable upstream tmux distribution.
