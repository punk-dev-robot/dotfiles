# Omarchy diet — packages dropped from the default set

Omarchy 4.x pacstraps a fixed set of ~145 packages listed in
`/usr/share/omarchy/install/omarchy-base.packages`. This file records which of
them we removed and why, so a fresh install (or an `omarchy-reinstall-pkgs`,
which re-adds the whole default set) can be re-slimmed in one command.

Full audit and rationale: `plans/omarchy-diet.md` (local only — `plans/` is gitignored).

## Re-apply after a reinstall

```bash
omarchy-pkg-drop libreoffice-fresh clang llvm cliamp mariadb-libs tensaku swappy
```

`omarchy-pkg-drop` = `pacman -Rns` on whichever of the named packages are
installed, so it is safe to re-run.

## Dropped (2026-09-16, 42 packages, 1056 MiB)

| package | why |
|---|---|
| `libreoffice-fresh` | unused office suite; pulled 34 format libs with it |
| `clang` + `llvm` | nothing on the system depended on them; gcc/base-devel covers builds |
| `cliamp` | unused terminal music player (was bound to SUPER+SHIFT+ALT+M) |
| `mariadb-libs` | zero dependents; only needed to build a MySQL client driver |
| `tensaku` | screenshot annotator; trial ended, `satty` won (KUB-111) |
| `swappy` | older screenshot annotator, leftover from the pre-omarchy Arch box |

Side effects accepted:

- `SUPER+SHIFT+ALT+M` (Music TUI) is now a no-op keybinding.
- imv `Ctrl+E` was repointed from `tensaku-edit` to `satty-edit`
  (`config/omarchy/imv/config`, dotter-managed since this change).

## Deliberately kept

- **fcitx5** — `enabled`+`active`; omarchy uses it for `~/.XCompose` compose
  sequences (CapsLock compose), not only CJK input. Removing it kills compose.
- **tesseract** (+`tesseract-data-eng`) — hard dependency of `libmupdf` (zathura)
  and used by `omarchy capture text`.
- **nautilus / imv / mpv** — the registered handlers for `inode/directory`,
  `image/png`, `video/mp4` on this box (thunar is installed but not default).
- **evince** — dependency of `sushi`, the nautilus space-bar previewer.
- **omawrite / omacalc / omacut / tobi-try / ttfx** — under 2 MiB combined and
  wired to keybindings; hide via `~/.config/omarchy/launcher.hides` instead.
- **dotnet-runtime** — exists only for `pinta`; both stay or both go.

## Notes on persistence

- `omarchy update` does **not** reinstall the default list (it runs
  `paccache -rk2` → snapshot → `pacman -Syu` → migrations → `yay -Sua` →
  `mise up` → orphan review), so removals stick.
- Two re-add paths: a **migration** may `pacman -S` a named package (seen for
  `quickshell`, `mise-bin`), and **`omarchy-reinstall-pkgs`** re-adds the whole
  default set — manual only.

## Cache policy (same session)

- `paccache.timer` enabled: weekly `paccache -r` (default keep = 3, tunable via
  `PACCACHE_ARGS` in `/etc/conf.d/pacman-contrib`) on top of the `paccache -rk2`
  that `omarchy update` already runs.
- yay build sources pruned (`~/.cache/yay` 6.8 G → 3.0 G): built `*.pkg.tar.*`
  kept, extracted sources and upstream tarballs removed — `yaycache` only prunes
  the built packages, never the sources.
  ```bash
  find ~/.cache/yay -mindepth 2 ! -name '*.pkg.tar.*' -delete
  ```
- pacman cache left at 2 rollback versions per package by choice.
