# Web apps as FirefoxPWA (PWAsForFirefox) scratchpads

All browser-based apps run through PWAsForFirefox (`firefoxpwa` CLI + Zen extension), one Firefox runtime
window per site, toggled as Hyprland scratchpads. Replaced Zen taskbar tabs, the `linear-desktop-bin` wrapper
and Todoist. Kept native: Notion (`notion-app-electron`, offline + `notion://`), Proton Mail (official Electron
client), Slack, Obsidian.

## Layout

| profile | id | sites | why |
|---|---|---|---|
| Work | `01M2TW5QTJCTQWA3YZCP436GEB` | Google Meet, Linear | one Swap Google login shared by all work sites |
| Personal | `01M2V2Q10Z6MSNXPKXKXWCBK54` | YouTube, X, WhatsApp, Reclaim | private logins |

Site IDs (= window class suffix `FFPWA-<id>`) are in `~/.local/share/firefoxpwa/config.json`; every binding in
`config/omarchy/hypr/bindings.lua` uses `pwa(key, name, site)` which wraps `scratch()` with
`firefoxpwa site launch <id>`. Site IDs are **not** profile IDs — don't mix them.

- `url-open` (`local/bin/`) routes `meet.google.com` / known `linear.app` paths to the PWA with `--url`.
  Meet additionally has the extension's native URL handler enabled (`enabled_url_handlers`), so no Tridactyl hook
  — adding one double-dispatches.
- The Default profile (`0000…`) is empty; the extension recreates it, leave it.

## Repo-managed files

- `config/omarchy/firefoxpwa/work/user.js` → `<Work profile>/user.js`; `personal/user.js` is a repo-internal
  symlink to it → `<Personal profile>/user.js` (dotter refuses one source mapped twice). `prefs.js` is runtime
  state, never managed.
- `config/omarchy/omarchy/themed/firefoxpwa.css.tpl` + `hooks/theme-set.d/firefoxpwa`: omarchy palette on the
  icon bar, same pattern as Zen (`omarchy-app-theming.md`). Hook loops all profiles, so new profiles are themed
  on the next `omarchy-theme-set`.

### user.js prefs and why

| pref | why |
|---|---|
| `firefoxpwa.launchType = 2` | reuse the open window/tab and navigate; `3` would focus and ignore the clicked URL |
| `browser.tabs.inTitlebar = 0`, `browser.tabs.drawInTitlebar = false` | no CSD title bar under Hyprland (PWA runtime defaults both on; use bool `false` not `0`) |
| `firefoxpwa.sitesSetThemeColor = false`, `firefoxpwa.dynamicThemeColor = false` | otherwise the icon bar is painted with the manifest/page `theme_color` (Meet: `#1a73e8` Google blue) via an injected `<style>` |
| `toolkit.legacyUserProfileCustomizations.stylesheets = true` | loads `chrome/userChrome.css` → `omarchy.css` |
| `firefoxpwa.enableHidingIconBar = true` | experimental; the promised menu entry never showed up on 2.19, harmless |

Prefs are read at **full app start**; hiding a scratchpad doesn't restart anything. Close with `Ctrl+Shift+Q`
inside the app, then relaunch.

### CSS gotcha

With `inTitlebar=0` the runtime's `browser.css` hides favicon + title
(`html:not([tabsintitlebar]):not([customtitlebar]) .site-info > * { display: none }`) assuming a native title
bar shows them. The tpl re-shows them with `display: flex !important` (user-sheet `!important` beats the runtime's
author sheet; `revert` did not work). Without it the icons also drift left when `.site-info` is empty.

## Adding a site

CLI works when the manifest is publicly fetchable:

```
firefoxpwa site install <manifest-url> --profile <profile-id> [--document-url <url>]
```

Otherwise (X: `crossorigin="use-credentials"`, Reclaim: manifest at `/manifest.webmanifest`) install from Zen:
PWAsForFirefox toolbar icon → Install → **profile dropdown = Work/Personal** (leaving "create new" makes a
stray profile — `firefoxpwa profile remove <id>`), and untick **Use manifest** if it fails to parse. Then read the
id from `config.json`, add a `pwa(...)` binding, `hyprctl reload`.

## Known non-issues

- Meet's "Click Allow" overlay for a few seconds after navigating to a meeting is Meet's own UI, permissions are
  granted permanently (`permissions.sqlite`). Same in Zen: zen-browser/desktop#6844.
- `hyprctl dispatch closewindow …` is wrong on Lua Hyprland; use
  `hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("meet"))'` etc.
