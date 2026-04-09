# macOS Ctrl↔Cmd Swap Architecture

## Overview

On macOS, Ctrl and Cmd are swapped per-app via Karabiner-Elements to match Linux muscle memory. Terminals are excluded from the swap so Ctrl works natively for terminal shortcuts.

## How It Works

```
┌─────────────────────────────────────────────────────┐
│ Physical Keypress                                   │
├──────────────┬──────────────────────────────────────┤
│ Karabiner    │ GUI apps: Ctrl→Cmd, Cmd→Ctrl         │
│ (HID level)  │ Terminals: no swap (excluded)         │
├──────────────┼──────────────────────────────────────┤
│ macOS sees   │ GUI: Cmd+D (from physical Ctrl+D)     │
│              │ Terminal: Ctrl+D (EOF, as expected)    │
├──────────────┼──────────────────────────────────────┤
│ App receives │ GUI: Cmd+D → copy/spotlight/etc       │
│              │ Terminal: Ctrl+D → sent to shell       │
└──────────────┴──────────────────────────────────────┘
```

## Components

- **Karabiner-Elements** (`config/karabiner/karabiner.json`): complex_modifications rule swaps left/right Ctrl↔Cmd with `frontmost_application_unless` condition excluding terminal bundle IDs
- **Ghostty** (`config/ghostty/config`): Cmd-based window/tab/split shortcuts set to `ignore` (using tmux instead). Copy/paste bound to Ctrl+Shift+C/V
- **Dotter**: Karabiner uses `recurse = false` for directory-level symlink (required by Karabiner's FSEvents change detection)
- **System Settings**: No system-wide modifier swap (Karabiner handles it)

## Excluded Terminal Bundle IDs

```
^com\.mitchellh\.ghostty$
^com\.apple\.Terminal$
^net\.kovidgoyal\.kitty$
^io\.alacritty$
```

## Known Limitation: System Shortcuts in Terminals

System-level shortcuts (Spotlight, etc.) that use Cmd+key work via physical Ctrl+key in GUI apps (Karabiner swaps). In terminals (excluded from swap), these require the **physical Cmd key** instead.

Example: Spotlight set to Cmd+D
- Browser: physical Ctrl+D → Karabiner → Cmd+D → Spotlight opens
- Ghostty: physical Ctrl+D → Ctrl+D → terminal EOF (no Spotlight)
- Ghostty: physical Cmd+D → Cmd+D → blocked by Ghostty menu item / `ignore` keybind

This is a fundamental trade-off: natural Ctrl in terminals vs consistent Cmd shortcuts everywhere.

### Potential Solutions to Explore

1. **Use a swap-safe Spotlight shortcut** — pick a shortcut that doesn't conflict with terminal usage. Candidates:
   - Double-tap Ctrl or Cmd — some launchers support this
   - A modifier combo unused in terminals (e.g., Ctrl+Shift+Space, Hyper+key)
   - Note: Ctrl+Space is tmux prefix, Cmd+Space would require physical Cmd in terminals

2. **Use Raycast/Alfred instead of Spotlight** — these support `global:` hotkeys registered via CGEventTap which intercept before any app sees the event. A global hotkey would work even in terminals

3. **Karabiner rule for Spotlight in terminals** — add a dedicated Karabiner mapping only for terminal apps that sends a Spotlight-triggering key combo from a unique physical combo (e.g., Ctrl+Shift+Space → Cmd+Space only in Ghostty)

4. **Ghostty global keybind** — Ghostty supports `global:` keybinds that work across apps. Could potentially map a key to trigger Spotlight via `osascript` or similar

## History

- Originally used system-wide Ctrl↔Cmd swap in System Settings + Ghostty `key-remap` swap-back
- macOS intercepted Cmd+H (Hide) and Cmd+M (Minimize) at AppKit level before Ghostty could swap back
- `defaults write NSUserKeyEquivalents` didn't work for Hide (hardcoded in NSApplication)
- Ghostty `ignore`/`unbind` keybind actions don't affect OS-level shortcuts
- Migrated to Karabiner per-app swap which avoids the interception problem entirely
