# Tasks: nvim

**Input**: Reverse-engineered from `config/nvim/` and `.dotter/global.toml`
**Prerequisites**: Existing migrated feature state only

**Validation**: No dedicated automated test suite was found. Completed tasks below reflect shipped configuration and inferred validation points.

## Phase 1: Scope And Setup

- [x] T001 Confirm the Neovim feature lives primarily in `config/nvim/`
- [x] T002 Confirm the feature is deployed through `.dotter/global.toml`
- [x] T003 Record the feature as `common` package scope rather than Linux-only or macOS-only

---

## Phase 2: Bootstrap And Core Config

- [x] T004 Implement `config/nvim/init.lua` as the Neovim entrypoint
- [x] T005 Implement `config/nvim/lua/config/lazy.lua` to bootstrap `lazy.nvim` and import LazyVim plus local plugins
- [x] T006 Maintain `config/nvim/lazyvim.json` to declare LazyVim extras
- [x] T007 Maintain `config/nvim/lazy-lock.json` to capture plugin lock metadata
- [x] T008 Implement baseline editor options in `config/nvim/lua/config/options.lua`
- [x] T009 Implement baseline keymaps in `config/nvim/lua/config/keymaps.lua`
- [x] T010 Keep local autocmds in `config/nvim/lua/config/autocmds.lua`

---

## Phase 3: Language And Workflow Features

- [x] T011 Implement LSP and diagnostics customization in `config/nvim/lua/plugins/lsp.lua`
- [x] T012 Implement project search/navigation behavior in files such as `config/nvim/lua/plugins/fzf.lua`, `goto-preview.lua`, and `diffview.lua`
- [x] T013 Implement tmux-aware workflows in `config/nvim/lua/plugins/tmux.lua`
- [x] T014 Implement AI/editor integration in `config/nvim/lua/plugins/claude.lua`
- [x] T015 Implement syntax/tree-sitter behavior in `config/nvim/lua/plugins/treesitter.lua`
- [x] T016 Maintain additional plugin overrides in `config/nvim/lua/plugins/*.lua`

---

## Phase 4: Optional And Experimental Integrations

- [x] T017 Preserve disabled or optional integrations such as `codecompanion.lua`, `windows.lua`, `obsidian.lua`, `harpoon.lua`, and `structurizr.lua`
- [x] T018 Keep supporting files under `config/nvim/after/`, `syntax/`, and plugin helper subpaths aligned with the active configuration

---

## Final Phase: Validation And Gaps

- [x] T019 Ensure Dotter maps `config/nvim` to `~/.config/nvim`
- [x] T020 Keep the feature isolated to user-level config rather than `etc/` or `.specify/`
- [ ] T021 Add dedicated Neovim documentation under `docs/` explaining feature goals, key workflows, and validation steps
- [ ] T022 Add a repeatable validation strategy for editor startup and key integrations beyond manual runtime checks
- [ ] T023 Clarify which disabled or `.bak` artifacts are intentional long-term experiments versus removable leftovers

---

## Identified Gaps

- No dedicated automated tests found for the Neovim feature
- No focused Neovim documentation found under `docs/`
- Experimental/disabled plugin files and `.bak` artifacts make the stable surface less explicit than it could be
