# AeroSpace scripts & config audit (modernize to 0.21.3-Beta)

## Context

The AeroSpace setup (config + 11 helper scripts in `local/bin/`) was written around v0.18–0.19. Installed version is **0.21.3-Beta**. Research (script inventory: `docs/.scratch/aerospace-script-inventory.md`; changelog brief: `docs/.scratch/aerospace-changelog-brief.md`) shows what's now native vs. still missing upstream.

**User decisions:** retire what's obsolete · replace AutoRaise with native FFM · disable daily restart (report back if drift returns) · add workspace-cycling binds.

## Key findings

**Now native (adopt):**
- `focus-follows-mouse.enabled = true` — shipped v0.21.0 (#12). Focuses **and raises** on hover, drag-safe. No delay/ignore-list/warp knobs — deliberately minimal. Replaces AutoRaise for plain hover-focus.
- Shell operators (`&& || ; |`) + `test`/`eval`/`echo` in bindings (v0.21.0, #278).
- `aerospace subscribe` (JSON event stream), `run-callback`, `auto-reload-config`, `reload-config --warnings-as-errors`, `layout --root/--workspace`, `on-mode-changed` (v0.20.0).

**Still missing (scripts stay justified — verified against 0.21.3):**
- No window position/geometry in `list-windows` format vars (verified locally) → `aerospace-scratchpad-frame`, `aerospace-roll-stack` osascript ordering, `aerospace-float-cmd` osascript branch all stay.
- No master-stack layout (#260 open), no pixel/percent resize → `aerospace-master-layout` weight math stays.
- No dynamic-gaps CLI (#1515 open) → `aerospace-widescreen` sed+reload hack stays.
- No native scratchpad (#272/#510 open; `summon-workspace` is unrelated Xmonad-style) → `aerospace-toggle` + third-party `aerospace-scratchpad` stay. ✅ Installed v0.6.0 (2026-07-15) postdates the 0.21.0 socket-protocol break (#1513) and is the latest release — no action.

**Breaking-change exposure (checked):**
- `after-login-command` — not used ✓. `config-version = 2` is current max ✓. `on-window-detected` entries all have `if` clauses ✓. Old `if.*` syntax soft-deprecated but "supported probably forever" — leave as-is, no churn.
- To sweep during implementation: grep scripts for deprecated `--app-id` flag (→ `--app-bundle-id`) and any `layout <single-arg>` exit-code reliance (now exits 0 on noop; use `--fail-if-noop` if a script branched on it).

## Files to modify

- `config/mac/aerospace/aerospace.toml` — FFM, cycling binds
- `Brewfile` — remove AutoRaise tap + cask (lines 9, 173)
- `local/bin/aerospace-restart` — delete
- `config/custom/launchagents/com.user.aerospace-restart.plist` — delete
- `.dotter/global.toml` — remove the aerospace-restart plist entry (line 83)
- `docs/reference/aerospace-deferred.md` — status refresh
- `docs/reference/aerospace-master-workflow.md` — remove aerospace-restart mention if present

## Steps

### 1. Native focus-follows-mouse, drop AutoRaise
- [ ] `aerospace.toml`: add `focus-follows-mouse.enabled = true` (near the callbacks section, with a comment noting it replaced AutoRaise and has no delay knob — revert path: re-add the cask).
- [ ] `Brewfile`: remove `tap "dimentium/autoraise"` and `cask "dimentium/autoraise/autoraiseapp"`.
- [ ] Runtime: quit AutoRaise, `brew uninstall autoraiseapp && brew untap dimentium/autoraise`; check for and remove any AutoRaise login item / `~/.AutoRaise` config leftovers.

### 2. Workspace cycling binds (deferred item)
- [ ] `aerospace.toml` main mode: `alt-leftSquareBracket = 'workspace --wrap-around prev'`, `alt-rightSquareBracket = 'workspace --wrap-around next'`, plus `alt-shift-leftSquareBracket/rightSquareBracket = 'move-node-to-workspace --wrap-around prev/next'`. Check for Karabiner/app conflicts on alt-[ / alt-].

### 3. Retire daily restart
- [ ] Delete `local/bin/aerospace-restart` + `config/custom/launchagents/com.user.aerospace-restart.plist`; drop the plist entry from `.dotter/global.toml`.
- [ ] Runtime: `launchctl bootout gui/$(id -u)/com.user.aerospace-restart`; `dotter deploy` cleans the symlink.
- [ ] Note in deferred doc: removed as experiment; re-add if CLI latency drift reappears (upstream perf issue).

### 4. Deprecation sweep in scripts
- [ ] `grep -rn -- '--app-id' local/bin/aerospace-*` → switch to `--app-bundle-id` if found.
- [ ] Confirm no script relies on non-zero exit from single-arg `layout` (add `--fail-if-noop` where needed).

### 5. Docs refresh (`docs/reference/aerospace-deferred.md`)
- [ ] Mark Workspace Cycling implemented; add FFM entry (native since 0.21.0, AutoRaise removed).
- [ ] Update upstream issue statuses: #278 shell scriptability **shipped 0.21.0**; #60 / #260 / #1515 / #272 still open (widescreen sed hack, master-layout weight math, scratchpad wrapper remain necessary).
- [ ] Note future simplification candidates (not this pass): `aerospace subscribe` could replace the post-startup polling loop; in-binding `||`/`&&` could absorb small wrapper scripts.

### Deliberately not doing
- Rewriting `on-window-detected` to new `if = 'test …'` syntax (old syntax supported indefinitely; pure churn).
- `auto-reload-config = true` — interacts unpredictably with `aerospace-widescreen`'s sed+explicit-reload cycle (would double-reload on every gap change); skip.
- Changing `alt-tab` to the docs-recommended `focus-back-and-forth || workspace-back-and-forth` — behavior change, not requested.

## Reuse

- All existing scripts except `aerospace-restart` stay untouched.
- Dotter deploy flow (`dotter -v -d` preview, then `dotter deploy`).

## Verification

- `dotter -v -d` dry-run, then deploy.
- `aerospace reload-config --warnings-as-errors` — must pass clean (also validates 0.21 binding-parser quoting).
- Hover across two windows → focus+raise follows mouse with AutoRaise uninstalled.
- `alt-[` / `alt-]` cycle workspaces; `alt-shift-[` / `alt-shift-]` move windows.
- `launchctl list | grep aerospace-restart` → empty; `ls ~/Library/LaunchAgents/com.user.aerospace-restart.plist` → gone.
- Smoke-test unchanged flows: `alt-enter` scratchpad toggle, `alt-;` master layout, `alt-,`/`alt-.` roll stack, `alt-shift-,` reset.
