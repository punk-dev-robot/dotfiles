# Hyprland Startup Error Flash

## Problem
- [issue] Brief error flash visible on every Hyprland startup #hyprland
- [symptom] Errors scroll through notification area then disappear once plugins finish loading #startup
- [duration] Resolves within ~2 seconds of session start #timing

## Root Cause
- [cause] Race condition between config parsing and plugin loading #race-condition
- [mechanism] Hyprland parses full config (keybinds, layout settings) synchronously BEFORE plugins finish loading #architecture
- [trigger] `exec-once = hyprpm reload` triggers async plugin load, but config parsing has already completed #execs
- [sequence] ConfigManager parses config -> dispatchers/layout referenced -> errors emitted -> PluginSystem loads -> virtual-desktops plugin registers dispatchers -> everything works #timing

## Error Categories

### 1. Invalid Dispatcher Errors
- [error] `Invalid dispatcher: vdesk`, `prevdesk`, `nextdesk`, `movetodesk`, `movetodesksilent`, etc. #dispatchers
- [source] virtual-desktops plugin dispatchers referenced in `config/hypr/configs/keybinds-sys.conf` (lines 34-74) #keybinds
- [reason] Plugin not loaded yet when config parser encounters these binds #race-condition

### 2. Unknown Layout Error
- [error] `Unknown layout!` #layout
- [source] `layout = workspacelayout` in `config/hypr/configs/settings.conf` (line 13) references hyprWorkspaceLayouts plugin #settings
- [reason] Same race -- layout plugin not registered when general config section is parsed #race-condition

### 3. DRM Commit Errors
- [error] `drm: Cannot commit when a page-flip is awaiting` / `Couldn't commit output named eDP-1/DP-3` #drm
- [reason] DRM timing during multi-monitor display initialization, normal kernel behavior #display

## Also Benign (No Action Needed)
- [noise] xkbcomp warnings (keycode clipping, modifier redefinition) -- standard keyboard map compilation noise #xkb
- [noise] aquamarine wayland backend failure -- expected when running native DRM session, not nested wayland #aquamarine

## Fix
- [fix] Chained `exec-once` in `config/hypr/configs/execs.conf` clears errors after plugin load completes #implementation
- [command] `exec-once = hyprpm reload && hyprctl seterror disable && hyprctl reload config-only` #execs
- [step] `hyprpm reload` -- loads plugins (virtual-desktops, hyprWorkspaceLayouts) #plugins
- [step] `hyprctl seterror disable` -- clears the error bar from the initial parse race #cleanup
- [step] `hyprctl reload config-only` -- re-parses config with plugins now registered, no errors emitted #reload
- [behavior] Chain uses `&&` so error bar is only cleared if plugins loaded successfully #safety
- [signal] If errors still flash AFTER this fix, something is genuinely wrong and needs investigation #alert

## Key Files
- [file] `config/hypr/configs/execs.conf` -- chained exec-once with plugin load, error clear, config reload #config
- [file] `config/hypr/configs/keybinds-sys.conf` -- virtual-desktops dispatcher binds (lines 34-74) #config
- [file] `config/hypr/configs/settings.conf` -- workspacelayout reference (line 13) #config
