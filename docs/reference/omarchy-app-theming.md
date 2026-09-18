# Omarchy theming for apps omarchy doesn't cover (Zen, Vicinae, Spotify)

Pattern (KUB-118, KUB-123): omarchy's own template engine + a `theme-set.d` hook per app. No third-party dep.

## How it works

`omarchy theme set X` → `omarchy-theme-set-templates` renders every `~/.config/omarchy/themed/*.tpl`
(`{{ background }}`, `{{ accent_strip }}`, `{{ mix bg fg 8% }}`, … — full key list: `omarchy-theme-color --file
~/.local/state/omarchy/current/theme/colors.toml --all`) into `~/.local/state/omarchy/current/theme/<name>` →
`omarchy-hook theme-set X` runs every file in `~/.config/omarchy/hooks/theme-set.d/` (files only, `.sample` skipped,
stdout discarded → use `omarchy-notification-send`).

Both dirs are dotter-managed via `config/omarchy/omarchy → ~/.config/omarchy`:

| app | template(s) | hook | takes effect |
|---|---|---|---|
| Zen | `themed/zen.css.tpl`, `zen-user.js.tpl` | `hooks/theme-set.d/zen` (symlinks into profile) | Zen restart |
| FirefoxPWA | `themed/firefoxpwa.css.tpl` | `hooks/theme-set.d/firefoxpwa` (symlinks into every `~/.local/share/firefoxpwa/profiles/*/chrome/`) | app restart — see `firefoxpwa-web-apps.md` |
| Vicinae | `themed/vicinae.toml.tpl` | `hooks/theme-set.d/vicinae` (cp → `~/.local/share/vicinae/themes/omarchy.toml`, `vicinae theme set omarchy`) | live |
| Spotify | `themed/spicetify-color.ini.tpl`, `spicetify-user.css.tpl` | `hooks/theme-set.d/spotify` (cp → `~/.config/spicetify/Themes/omarchy/`, `spicetify -q -n apply`) | Spotify restart |

Hooks exit 0 silently when the app or rendered file is missing (themes without `colors.toml` render nothing).

## Apps omarchy *does* cover natively (Ghostty, Neovim) — KUB-133

No hook, no template of ours: both read the generated files under
`~/.local/state/omarchy/current/theme/` directly. Our configs used to pin Catppuccin Mocha and never
read them, so `omarchy theme set` had no effect on either.

| app | wiring | takes effect |
|---|---|---|
| Ghostty | `config/custom/ghostty/config` → `config-file = ?"~/.local/state/omarchy/current/theme/ghostty.conf"` (same line as stock `/usr/share/omarchy/config/ghostty/config`) | live (omarchy reloads Ghostty on theme set) |
| Neovim | `config/custom/nvim/lua/plugins/colorscheme.lua` `dofile`s `<XDG_STATE_HOME>/omarchy/current/theme/neovim.lua` (a lazy.nvim spec) | **next nvim start** — running instances keep their colors |

Both are **mutually exclusive branches**, never layered: the Catppuccin Mocha theme +
the `catppuccin/nvim` spec (Neovim) only render when omarchy is absent - macOS, plain
Arch. Ghostty's branch is the dotter var `is_omarchy` (set in `.dotter/omarchy.toml`;
*not* `is_linux` - plain Arch has no omarchy state dir); Neovim's is a runtime
`pcall(dofile, …)`, so the same file works on every host. Personal non-color settings
(font, opacity, keybinds, transparent.nvim) sit outside the branch; the fallback also
adds a disabled `folke/tokyonight.nvim` fragment (only in the catppuccin branch, so it
never fights a native theme like tokyo-night that ships its own enabled spec for the
same plugin). Ghostty's palette 16-23 block (see below) is likewise shared by both
branches, not fallback-only.

Fallback semantics differ: nvim's is a runtime `pcall`, Ghostty's is render-time. On an omarchy box
that has never run `omarchy theme set` the state file doesn't exist, so the `?` include silently
yields Ghostty's built-in colors (not Catppuccin) until the first theme set. Neovim distinguishes the
two failure modes: a missing `neovim.lua` falls back to Catppuccin silently (expected pre-first-theme-set
state), but a *present* file that isn't a valid lazy.nvim spec logs a `vim.notify` WARN before falling back,
so a broken omarchy template doesn't fail silently.

Two consequences:

- **Each theme brings its own nvim colorscheme plugin**, theme-dependent (retro-82 →
  `OldJobobo/retro-82.nvim`, tokyo-night → `folke/tokyonight.nvim`, most others →
  `bjarneo/aether.nvim`). The first nvim start after a theme switch installs it and rewrites
  `lazy-lock.json` (a tracked file). `:Lazy clean` will remove the previous theme's plugin.
- **Palette 16-23 stays fixed Catppuccin Mocha tints on every host**, native omarchy or not: the block
  sits outside the `is_omarchy`/`else` split in `config/custom/ghostty/config`, so pi's `terminal-tinted`
  theme keeps its Pi UI colors regardless of the active Omarchy theme. Only palette 0-15 (the terminal's
  main colors) actually follows Omarchy, since omarchy's generated `ghostty.conf` only defines those slots.

Check: `test-omarchy-nvim-theme.sh` (in `local/bin`) asserts the omarchy-present (retro-82 and
tokyo-night) and omarchy-absent nvim branches without touching lazy.nvim or the lockfile.

## Spotify / Spicetify

`spicetify-cli` (AUR) patches the Spotify install. Ours is `spotify-launcher` → user-writable
`~/.local/share/spotify-launcher/install/usr/share/spotify`, prefs `~/.config/spotify/prefs` (set once via
`spicetify config spotify_path … prefs_path …`; lives in `~/.config/spicetify/config-xpui.ini`, not dotter-managed).

**Every Spotify update undoes the patch** (accepted). Re-apply:

```
spicetify restore backup apply
```

If the hook's `apply` fails it sends a critical notification with that command. New machine: install spicetify-cli,
set the two paths, `spicetify backup apply`, then any `omarchy theme set`.

## Why not imbypass/omarchy-theme-hook

Broken on Omarchy 4 (upstream issue #55, unfixed on `main` since 2026-05): reads colors from the pre-4 path
(`~/.config/omarchy/current/theme`) so every colour is empty, and `omarchy-hook` runs its hooklettes twice
(second run without helpers → `command not found` flood). A fix exists only in a fork (Redzselek PR #1). Its
Vicinae/Spotify colour mappings were ported into the templates above.
