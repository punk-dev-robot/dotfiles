# a-bar Notes

Current status of the macOS bar migration from Simple Bar / Übersicht to `a-bar`.

## Current State

- `a-bar` is the chosen bar going forward.
- `Übersicht` / Simple Bar is no longer part of the live setup.
- The active `a-bar` config is tracked in the repo at:
  - `config/a-bar/a-barrc`
- Dotter deploys it to:
  - `~/.a-barrc`
- `~/.a-barrc` is intended to be a symlink to the repo file so GUI saves write straight back into dotfiles.

## Migration Decisions

- Keep `config/a-bar/a-barrc` as the source of truth.
- Use the native `a-bar` GUI for tuning first, then sync or review changes in the repo.
- Avoid hand-authoring the first config structure where possible; prefer app-generated config.

## What Was Removed

The old bar stack was intentionally removed from the live runtime:

- AeroSpace no longer sends Übersicht refresh hooks.
- `Übersicht` was removed from login items.
- `simple-bar-server` was removed from `pm2`.

This keeps the bar setup simpler and avoids the old widget/server refresh chain.

## Confirmed Working

- `a-bar` launches and runs normally.
- AeroSpace-native widgets work better than the old Simple Bar equivalents.
- Wi-Fi widget shows the real network name in `a-bar` on this machine.
- Scratchpad workspace exclusion works in `a-bar` via native spaces exclusions.

### Current useful config choices

- `windowManager = "aerospace"`
- `aerospace-spaces` widget in use
- `aerospace-process` widget in use
- scratchpad spaces excluded with:
  - `widgets.spaces.exclusions = "^\\.scratchpad\\."`
  - `widgets.spaces.exclusionsAsRegex = true`

## Known Multi-Display Issue

### Symptom

`a-bar` shows a bar on the external Philips monitor, but not on the built-in Retina display.

### Findings

The issue is not caused by a bad config file anymore.

Verified facts:

- `~/.a-barrc` contains two display entries.
- `com.jeantinland.a-bar` UserDefaults also contains the same two display entries.
- Native macOS screen order seen from Swift is:
  - `0 = PHL 499P9`
  - `1 = Built-in Retina Display`
- The `a-bar` process is only creating one live bar window.

### Source-level findings

From the `a-bar` source:

- `DisplayConfiguration` stores:
  - `displayIndex`
  - user-facing `name`
- `MultiDisplayLayout.configuration(forDisplay:)` matches only by `displayIndex`.
- `AppDelegate.setupBarWindows()` loops over `NSScreen.screens.enumerated()` and creates windows using the enumerated display index.

This means `a-bar` currently keys displays by transient screen order, not by stable physical display identity.

### Why this is a real bug

Even when the current home setup is made to work, `displayIndex` is unstable across environments:

- laptop only
- home docked with ultrawide
- office with a different external monitor

Examples:

- At home, the external Philips can become index `0` and built-in index `1`.
- On another setup, built-in may become index `0` again.
- A different external monitor may inherit the wrong layout purely because it occupies the same index.

### Important clarification

The `name` field in `a-bar` config is only a user label.

It is **not** a stable hardware identifier, so it should not be used as the real fix for mapping displays.

### Likely correct upstream fix

`a-bar` should persist and match displays using a stable system identifier, such as:

- `CGDirectDisplayID`
- display UUID
- EDID-derived stable identifier
- another persistent native screen identity

Then:

- `displayIndex` can remain a runtime convenience
- `name` can remain user-facing only
- layout mapping becomes stable across different monitor setups

### Additional source suspicion

The settings UI contains assumptions like:

- `displayIndex == 0 ? laptopcomputer : display`

This suggests the app may be implicitly treating index `0` as the laptop/internal display, which is not valid on setups where an external display is primary or ordered first.

That may be part of the display mapping bug, but the deeper architectural problem is still the use of `displayIndex` as identity.

## Temporary Position

- The current home setup is usable enough for now.
- Do not attempt a name-based remapping hack using the user-facing display names.
- Revisit this as a proper local patch + upstream contribution later.

## Recommended Future Work

When returning to this problem:

1. Inspect how to obtain a stable display identifier in Swift/AppKit/CoreGraphics.
2. Extend `DisplayConfiguration` to store that stable identifier.
3. Update `MultiDisplayLayout.configuration(forDisplay:)` to match by stable identifier first.
4. Add migration fallback from old `displayIndex`-only configs.
5. Test across:
   - laptop only
   - home docked
   - office external monitor
6. Contribute the fix upstream if clean.

## Related Files

- `config/a-bar/a-barrc`
- `.dotter/global.toml`
- `config/aerospace/aerospace.toml`

## Reference Source Paths

Relevant `a-bar` source areas inspected during investigation:

- `a-bar/Models/WidgetTypes.swift`
- `a-bar/Models/Settings.swift`
- `a-bar/Models/Profile.swift`
- `a-bar/AppDelegate.swift`
- `a-bar/BarWindow.swift`
- `a-bar/Views/Settings/LayoutBuilderView.swift`
- `a-bar/Widgets/Aerospace/AerospaceSpacesWidget.swift`
