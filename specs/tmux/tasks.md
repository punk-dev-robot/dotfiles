# Tasks: tmux

**Input**: Reverse-engineered from `config/tmux/`, related `local/bin/tmux-*` scripts, `test-tmux-alacritty.sh`, `.dotter/global.toml`, and `docs/reference/tmux/`
**Prerequisites**: Existing migrated feature state only

**Validation**: Validation exists through runtime behavior, helper scripts, and `local/bin/test-tmux-alacritty.sh` rather than a single automated test suite.

## Phase 1: Scope And Setup

- [x] T001 Confirm the tmux feature spans `config/`, `local/`, `.dotter/`, and `docs/`
- [x] T002 Confirm `config/tmux/tmux.conf` is the main feature entrypoint
- [x] T003 Confirm the feature uses both shared and platform-conditional behavior

---

## Phase 2: Core tmux Configuration

- [x] T004 Implement the tmux Dotter mapping in `.dotter/global.toml`
- [x] T005 Implement the templated `config/tmux/tmux.conf` configuration
- [x] T006 Configure keybindings for prefix, windows, panes, copy mode, reload, and environment refresh
- [x] T007 Configure terminal, clipboard, numbering, status, and rename behavior
- [x] T008 Configure tmux plugin declarations and plugin-specific options

---

## Phase 3: Helper Scripts And Session Lifecycle

- [x] T009 Implement `local/bin/tmux-sync-env.sh` for environment synchronization
- [x] T010 Implement `local/bin/tmux-save-wrapper.sh` for validated save operations
- [x] T011 Implement `local/bin/tmux-restore-wrapper.sh` for restore operations with logging
- [x] T012 Implement `local/bin/tmux-cleanup-sessions.sh` for old resurrect save cleanup
- [x] T013 Implement `local/bin/test-tmux-alacritty.sh` as an integration-style validation script for the Linux workflow

---

## Phase 4: Documentation And Operational Context

- [x] T014 Document tmux architecture and lifecycle behavior in `docs/reference/tmux/index.md`
- [x] T015 Document Linux systemd integration in `docs/reference/tmux/systemd-integration.md`
- [x] T016 Document startup race-condition debugging in `docs/reference/tmux/race-condition-troubleshooting.md`

---

## Final Phase: Cross-Feature And Gap Tracking

- [x] T017 Preserve the tmux/Neovim navigation contract without making tmux own Neovim configuration directly
- [ ] T018 Add a clearer validation matrix for which parts of the feature are covered by runtime checks versus `test-tmux-alacritty.sh`
- [ ] T019 Document macOS tmux persistence expectations with the same level of detail as the Linux systemd workflow
- [ ] T020 Clarify whether all helper scripts belong strictly to the tmux feature or whether some should eventually be grouped under a broader terminal/session orchestration feature

---

## Identified Gaps

- Validation exists, but it is spread across runtime behavior, scripts, and docs rather than one consistent automated workflow
- Linux persistence/orchestration is better documented than macOS persistence behavior
- The feature has a real cross-feature dependency with Neovim navigation/status integration that remains intentionally split across two features
