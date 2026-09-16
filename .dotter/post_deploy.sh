#!/usr/bin/env bash
echo "Post deploy script"

# pi's default config dir is ~/.pi, but this repo manages ~/.config/pi. 9 installed
# extensions still hardcode ~/.pi (docs/troubleshooting/pi-xdg-dir.md). Keep ~/.pi
# as a symlink to ~/.config/pi so pi
# always sees the dotter-managed config, extensions, and auth. Only (re)create the
# link when it's missing or wrong; never clobber a real dir that holds live data.
if [ ! -L "$HOME/.pi" ] && [ -d "$HOME/.pi" ]; then
    echo "  warning: ~/.pi is a real directory, not a symlink to ~/.config/pi (leaving it; move it aside manually)" >&2
elif [ "$(readlink "$HOME/.pi" 2>/dev/null)" != "$HOME/.config/pi" ]; then
    ln -sfn "$HOME/.config/pi" "$HOME/.pi"
    echo "  linked ~/.pi -> ~/.config/pi"
fi

if [[ "$(uname)" == "Linux" ]]; then
  # Fix keyd config permissions (dotter creates root-owned files with 600)
  sudo chmod -f 644 /etc/keyd/*.conf 2>/dev/null || true

  # Deploy polkit rules (directory is root:polkitd 750, inaccessible to dotter)
  POLKIT_SRC="system/polkit/49-nopasswd-limited.rules"
  POLKIT_DST="/etc/polkit-1/rules.d/49-nopasswd-limited.rules"
  if [ -f "$POLKIT_SRC" ]; then
      if ! sudo diff -q "$POLKIT_SRC" "$POLKIT_DST" >/dev/null 2>&1; then
          sudo cp "$POLKIT_SRC" "$POLKIT_DST"
          sudo chown root:polkitd "$POLKIT_DST"
          sudo chmod 644 "$POLKIT_DST"
          echo "  polkit rules updated"
      fi
  fi
fi

# herdr plugins: declared in config/shared/herdr/plugins.txt, installed by
# local/bin/herdr-sync-plugins (both dotter-deployed). Skipped when the herdr
# server is not running/reachable (plugin CLI needs it).
if command -v herdr >/dev/null 2>&1 && [ -x "$HOME/.local/bin/herdr-sync-plugins" ]; then
    "$HOME/.local/bin/herdr-sync-plugins" || echo "  warning: herdr plugin sync had failures" >&2
fi

# shell.{json,toml} are copies; omarchy-shell only re-reads them on request — otherwise its stale
# in-memory config gets persisted over the file on the next bar edit.
if command -v omarchy-shell >/dev/null 2>&1; then
    omarchy-shell shell reloadConfig >/dev/null 2>&1 || true
fi

# KUB-122: own user timers (config/omarchy/systemd). Only when a user systemd is reachable
# (Linux desktop session); no-op elsewhere.
if [[ "$(uname)" == "Linux" ]] && systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user enable --now btrfs-space-monitor.timer git-maintenance-sync.timer screenshot-cleanup.timer \
        || echo "  warning: enabling user timers failed" >&2
fi
