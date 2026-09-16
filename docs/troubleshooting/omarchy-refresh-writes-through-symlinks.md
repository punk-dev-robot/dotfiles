# Omarchy refresh scripts write through dotter symlinks

## Symptom

After `omarchy-update`, `omarchy-refresh-*`, or `omarchy-reinstall-configs`, `git status`
in `~/dotfiles` shows modified (or emptied) files under `config/shared/` you never touched.

## Cause

`omarchy-refresh-config <path>` does `cp -f $OMARCHY_PATH/config/<path> ~/.config/<path>`;
`omarchy-reinstall-configs` does `cp -af /etc/skel/. ~/`. Neither passes
`--remove-destination`, so when the destination is a dotter symlink `cp` opens the link
target for writing — the omarchy default lands **in the repo file**, not on top of the link.

Worst case: omarchy's `lazygit/config.yml` is a 0-byte placeholder, so a reinstall
truncates `config/shared/lazygit/config.yml` to empty.

Callers: `omarchy-refresh-{herdr,tmux,shell}`, two migrations (`herdr/config.toml`
guarded by `[[ -f ]] ||`, `kitty/kitty.conf`), and `omarchy-reinstall-configs` (everything
in `/etc/skel`). Package upgrades alone never touch `$HOME`.

## Recovery

```sh
cd ~/dotfiles && git checkout -- config/shared && dotter
```

Check `git status` once more; any `.bak.<epoch>` files left in `~/.config` are omarchy's
backups of the (already-correct) repo content and can be deleted.

## Second failure mode: shell.json is a copy, not a symlink (bar lost all custom plugins)

omarchy-shell inotify-watches `~/.config/omarchy/shell.json` (`shell.qml` FileView, `watchChanges: true`)
and on every change re-parses it; empty / unparseable / missing → **in-memory config silently falls back to
built-in defaults** (3 widgets, `plugins: []`). Nothing is logged (`printErrors: false`). A non-atomic
writer — nvim saving the symlinked repo file (truncate + write), `cp -f` through the link — fires the
watcher mid-write. The bar keeps rendering the old widgets, so nothing looks wrong until the next drag in
the bar editor / `omarchy bar …` persists the *default* in-memory config over the file (atomic tmp+rename,
which also replaces a symlink with a real file). Symptom: "moved one widget, lost every plugin".

Hence `shell.{json,toml}` are dotter **copies** (`type = "template"` in `.dotter/global.toml`):

- edit `config/omarchy/omarchy/shell.json` in the repo → `dotter` (post_deploy runs
  `omarchy-shell shell reloadConfig`, so memory always ends on the final file);
- edit live (bar editor, `omarchy bar move <id> left`, `omarchy plugin enable`) → `omarchy-shell-pull`
  copies live → repo, commit.

Diagnose: `omarchy plugin list` asks the live shell — third-party widgets `disabled` while the file lists
them = stale memory. Recover: `omarchy-shell shell reloadConfig`.

(`omarchy display text size` additionally `sed -i`s `~/.config/ghostty/config` and sets GTK `text-scaling-factor`;
use `[font] base-size` in `shell.toml` instead — KUB-111.)

## Rule

**Never run `omarchy-reinstall-configs` on this box.** Run a single
`omarchy-refresh-config <path>` only for a file omarchy owns (not a dotter symlink), and
`git status` afterwards.
