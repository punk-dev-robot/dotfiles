# Implementation Plan: nvim

**Branch**: `migrated-nvim` | **Date**: 2026-04-15 | **Spec**: `specs/nvim/spec.md`
**Input**: Reverse-engineered from the existing Neovim configuration in `config/nvim/`

## Summary

The `nvim` feature is a Dotter-managed Neovim setup built on LazyVim and `lazy.nvim`, with a small baseline config layer in `lua/config/` and a larger behavior layer in `lua/plugins/`. The feature delivers a ready editor bootstrap, project-aware navigation and LSP tuning, tmux-aware workflows, and a mix of stable and experimental plugin integrations.

## Technical Context

**Project Type**: Dotter-managed configuration monorepo  
**Primary Technologies**: Lua, JSON, TOML, Vimscript, Tree-sitter queries  
**Deployment Layer**: Dotter via `.dotter/global.toml`  
**Validation**: `dotter -v -d` for deployment-level validation; runtime/editor validation inferred from startup and configured behaviors  
**Platform Scope**: `common`  
**Risk Level**: medium, because the feature is large and central to daily editing workflows but isolated under `config/nvim/`

## Constitution Check

*GATE: Must pass before implementation and again before completion.*

- The feature stays inside the expected boundaries: `config/nvim/` plus one `.dotter/` mapping.
- Dotter ownership is explicit at `.dotter/global.toml:96-97`.
- Validation is targeted to the area: editor startup and Dotter deployment behavior, not generic app build steps.
- No `.specify/` tooling is involved.
- No `docs/` updates were found for this feature, which is a notable documentation gap.

## Project Structure

### Feature Documentation

```text
specs/nvim/
├── spec.md
├── plan.md
└── tasks.md
```

### Repository Boundaries

```text
.dotter/   package selection, target mappings, template variables, deploy hooks
config/    user-level application configs
```

### Structure Decision

The migrated feature is centered on `config/nvim/` and deployed through the Dotter `nvim` package. The internal structure splits into:

```text
config/nvim/
├── init.lua
├── lazyvim.json
├── lazy-lock.json
├── .neoconf.json
├── lua/
│   ├── config/
│   │   ├── autocmds.lua
│   │   ├── keymaps.lua
│   │   ├── lazy.lua
│   │   └── options.lua
│   └── plugins/
│       ├── lsp.lua
│       ├── tmux.lua
│       ├── claude.lua
│       ├── fzf.lua
│       ├── treesitter.lua
│       └── many additional plugin overrides
└── after/
```

This is the right home because the feature is a user-level application config, not a system config, local script feature, or spec-tooling feature.

## Reverse-Engineered Implementation Phases

### Phase 0: Bootstrap The Editor Framework

- Add `config/nvim/` to the repo and map it through the Dotter `nvim` package.
- Bootstrap `lazy.nvim` in `lua/config/lazy.lua`.
- Layer LazyVim extras through `lazyvim.json` and maintain lock metadata in `lazy-lock.json`.

### Phase 1: Define Baseline Editor Behavior

- Keep the entrypoint minimal through `init.lua`.
- Set options, root detection, Python/LSP defaults, and preview tweaks in `lua/config/options.lua`.
- Add path-oriented helper keymaps in `lua/config/keymaps.lua`.
- Keep the local config layer small and readable while deferring most behavior to plugins.

### Phase 2: Add Workflow Plugins And Language Features

- Configure language/LSP behavior in `lua/plugins/lsp.lua`, including heavy VTSLS tuning and diagnostics behavior.
- Add workflow plugins for grep, diffing, goto-preview, tmux integration, AI integration, markdown handling, and other editor habits.
- Keep some integrations disabled or experimental through empty specs, `enabled = false`, or alternate files.

## Complexity Tracking

| Complexity | Why Needed | Simpler Alternative Rejected Because |
|------------|------------|--------------------------------------|
| Large plugin surface | The editor config supports many workflows and languages in one managed feature | A tiny baseline-only config would not match the actual implementation state |
| Conditional/disabled integrations | Some features are exploratory or environment-specific | Splitting every experiment into a separate repo feature was not how the config evolved |

## Gaps And Risks

- No dedicated automated tests exist for the Neovim feature.
- No focused documentation in `docs/` explains the intended Neovim architecture, key workflows, or validation steps.
- Several files indicate experimentation (`enabled = false`, `return {}`, `.bak` files), so some intent has to be inferred from the current code rather than confirmed by documentation.
