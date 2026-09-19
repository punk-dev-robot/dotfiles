#!/usr/bin/env bash
echo "Post deploy script"

# Merge the live pi-multi-account models.json (backed up by pre_deploy.sh, or
# absent on a first deploy) with our tracked context-window overrides, and
# write the result back as a regular, plugin-owned
# ~/.config/pi/agent/models.json. Ordered oldest -> newest -> wins: backup
# (pre-deploy snapshot), live target (may have been written concurrently
# since pre_deploy ran), then our tracked overrides (always win conflicts).
pi_models_target="$HOME/.config/pi/agent/models.json"
pi_models_backup="${pi_models_target}.pre-deploy.bak"

pi_models_fail() {
  echo "post_deploy: $1" >&2
  if [[ -f "$pi_models_backup" ]]; then
    cp "$pi_models_backup" "$pi_models_target" \
      || echo "post_deploy: also failed to restore backup to $pi_models_target" >&2
  fi
  exit 1
}

repo_root="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)" \
  || pi_models_fail "failed to resolve repo root via git"
pi_overrides="$repo_root/config/custom/pi/model-overrides.json"

mkdir -p "$(dirname "$pi_models_target")" || pi_models_fail "cannot create $(dirname "$pi_models_target")"

# Dangling symlink at target (crash/interrupted prior run): nothing live to
# merge, and mv would otherwise be replacing a broken link's identity only.
if [[ -L "$pi_models_target" && ! -e "$pi_models_target" ]]; then
  rm -f "$pi_models_target"
fi

pi_models_sources=()
if [[ -f "$pi_models_backup" ]]; then
  jq empty "$pi_models_backup" 2>/dev/null || pi_models_fail "$pi_models_backup is not valid JSON"
  pi_models_sources+=("$pi_models_backup")
fi
if [[ -e "$pi_models_target" ]]; then
  jq empty "$pi_models_target" 2>/dev/null || pi_models_fail "$pi_models_target is not valid JSON"
  pi_models_sources+=("$pi_models_target")
fi
jq empty "$pi_overrides" 2>/dev/null || pi_models_fail "$pi_overrides is not valid JSON"
pi_models_sources+=("$pi_overrides")

# mktemp in the same directory (atomic mv, same filesystem) and mode 600 by
# default; jq streams straight into it, so the merged JSON never sits in a
# shell variable and the final file keeps mktemp's 600 mode.
pi_models_tmp="$(mktemp "${pi_models_target}.XXXXXX")" || pi_models_fail "mktemp failed"
if ! jq -s 'reduce .[] as $item ({}; . * $item)' "${pi_models_sources[@]}" > "$pi_models_tmp"; then
  rm -f "$pi_models_tmp"
  pi_models_fail "jq merge failed"
fi
if ! mv -f "$pi_models_tmp" "$pi_models_target"; then
  rm -f "$pi_models_tmp"
  pi_models_fail "failed to install merged models.json"
fi

rm -f "$pi_models_backup"

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
