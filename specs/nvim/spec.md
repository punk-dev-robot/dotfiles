# Feature Specification: nvim

**Feature Branch**: `migrated-nvim`  
**Created**: 2026-04-15  
**Status**: migrated  
**Input**: Reverse-engineered from `config/nvim/` and `.dotter/global.toml`

## Scope *(mandatory)*

### Affected Boundaries

- [x] `config/`
- [ ] `etc/`
- [ ] `local/`
- [x] `.dotter/`
- [ ] `docs/`

Optional, only if the feature explicitly targets SDD/tooling work:

- [ ] `.specify/`

### Affected Paths

- `config/nvim/`
- `.dotter/global.toml`

### Platform Scope

- [x] `common`
- [ ] `linux`
- [ ] `arch`
- [ ] `macos`
- [ ] Not package-scoped

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Start Into A Ready Editor (Priority: P1)

As the repo owner, I want Neovim to bootstrap into a usable editor with LazyVim defaults plus local overrides so the managed dotfiles immediately provide a consistent coding environment.

**Why this priority**: Without a working editor bootstrap, the rest of the Neovim feature is unreachable.

**Independent Test**: Deploy the config through Dotter, start Neovim, and confirm it loads `config.lazy`, installs `lazy.nvim` if needed, and applies the local config/plugin tree without startup failure.

**Acceptance Scenarios**:

1. **Given** `config/nvim/` is deployed to `~/.config/nvim`, **When** Neovim starts, **Then** `init.lua` loads `config.lazy` and the LazyVim-based setup completes.
2. **Given** `lazy.nvim` is not already present, **When** Neovim starts, **Then** the config clones and prepends it before loading plugin specs.

---

### User Story 2 - Work Across Polyglot Projects Efficiently (Priority: P2)

As the repo owner, I want the Neovim setup to support common project types with tuned root detection, diagnostics, language servers, and search/navigation behavior so the editor stays effective across mixed-language repositories.

**Why this priority**: The config is clearly optimized for real daily project work rather than only basic editing.

**Independent Test**: Open representative project files and confirm root detection, LSP behavior, grep/navigation mappings, and diagnostics settings are active.

**Acceptance Scenarios**:

1. **Given** a project with `package.json`, `Cargo.toml`, `pyproject.toml`, or similar roots, **When** files are opened, **Then** the configured root resolution prefers the closest project root before falling back to `.git` or cwd.
2. **Given** TypeScript, Python, JSON, and YAML files are edited, **When** LSP features are used, **Then** the corresponding editor behavior reflects the configured language-server and diagnostics overrides.

---

### User Story 3 - Use Integrated Editor Workflows (Priority: P3)

As the repo owner, I want the editor to include tailored workflows such as path yanking, tmux-aware movement, diff/history tools, AI terminal integration, and optional specialty plugins so the editor matches personal working habits.

**Why this priority**: These workflows are valuable, but they build on the baseline editor and language support already working.

**Independent Test**: Use the configured keymaps and conditional integrations in an active editing session and verify that they activate only in the intended contexts.

**Acceptance Scenarios**:

1. **Given** Neovim is running inside tmux, **When** movement and resize mappings are used, **Then** pane navigation and tmux status integration work through the tmux plugin layer.
2. **Given** AI integration is enabled, **When** the configured Claude commands are triggered, **Then** the terminal-backed Claude workflow opens and supports send/focus/diff actions.

---

### User Story 4 - Keep Experiments Isolated From The Stable Baseline (Priority: P4)

As the repo owner, I want optional, disabled, or exploratory plugin configurations to live alongside the main Neovim setup without silently redefining the stable baseline editor behavior.

**Why this priority**: The codebase contains disabled plugins and experimental files, but they should not break the main editor feature.

**Independent Test**: Review disabled plugin files and confirm the baseline setup still loads even when optional integrations remain commented out or return empty specs.

**Acceptance Scenarios**:

1. **Given** disabled plugin configs such as `codecompanion.lua`, `windows.lua`, or `structurizr.lua`, **When** Neovim loads the plugin tree, **Then** those files do not break the baseline configuration.

## Edge Cases *(mandatory)*

- What happens when Neovim starts on a machine without the external tools expected by certain plugins, such as `git`, `npm`, tmux, or language servers?
- What happens when the config is used outside tmux and tmux-only integrations should not load?
- What happens when project root detection encounters nested monorepo-style layouts?
- What happens when experimental or `.bak` files remain in the config tree?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The feature MUST deploy `config/nvim/` through the Dotter `nvim` package mapping in `.dotter/global.toml`.
- **FR-002**: The feature MUST bootstrap `lazy.nvim` and load LazyVim plus the local plugin tree from `lua/plugins/`.
- **FR-003**: The feature MUST provide repo-specific editor defaults through `lua/config/` for options, keymaps, and autocmds.
- **FR-004**: The feature MUST support project-aware root detection using explicit root markers before falling back to `.git` or cwd.
- **FR-005**: The feature MUST provide customized LSP and diagnostics behavior for common languages used by the repo owner.
- **FR-006**: The feature MUST expose editor workflows for search, preview, diff/history, and file-path copying through configured mappings.
- **FR-007**: The feature MUST provide tmux-aware behavior only when running inside tmux.
- **FR-008**: The feature MUST allow optional or disabled plugin experiments to coexist without redefining the baseline startup path.
- **FR-009**: The feature MUST keep plugin lock/version metadata alongside the config so the managed setup remains reproducible enough for maintenance.
- **FR-010**: The feature MUST preserve personal AI/editor integrations that are explicitly configured in the active plugin set.

### Boundary-Specific Requirements

#### `config/` Changes

- `config/nvim/init.lua` acts as the feature entrypoint.
- `config/nvim/lua/config/` contains baseline editor behavior.
- `config/nvim/lua/plugins/` contains the main implementation surface of the feature.

#### `.dotter/` Changes

- `.dotter/global.toml` MUST continue to map `config/nvim` to `~/.config/nvim` as the deployable target for this feature.

## Success Criteria *(mandatory)*

- **SC-001**: A deployed machine can start Neovim with the managed `config/nvim/` tree without immediate configuration failure.
- **SC-002**: The active config clearly separates baseline editor behavior (`lua/config/`) from plugin-specific behavior (`lua/plugins/`).
- **SC-003**: Root detection, keymaps, diagnostics, and plugin integrations reflect the repository’s actual configured behavior rather than generic editor defaults.
- **SC-004**: Optional or disabled integrations remain distinguishable from the stable baseline and do not prevent startup.

## Assumptions

- The feature is primarily maintained as a personal editor environment rather than a distributable plugin package.
- External tools required by some plugins are expected to be installed separately from this specific feature artifact.
- Automated tests were not authored for this feature, so successful behavior is inferred from configuration structure and runtime intent rather than a dedicated test suite.
