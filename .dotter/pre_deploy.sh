#!/usr/bin/env bash
echo "Pre deploy script"

if [[ "$(uname)" == "Linux" ]]; then
  # Fix keyd config permissions (dotter creates root-owned files with 600)
  sudo chmod -f 644 /etc/keyd/*.conf 2>/dev/null || true
fi

# ~/.config/pi/agent/models.json is plugin-owned (pi-multi-account writes live
# providers/models/auth into it), not dotter-managed. Preserve it before dotter
# runs so a stale symlink/cache entry can't leave it half-clobbered; post_deploy
# merges it back in with our tracked overrides. Backup lives beside the target
# (persistent, private) rather than a shared tmp/XDG_RUNTIME_DIR path.
pi_models_target="$HOME/.config/pi/agent/models.json"
pi_models_backup="${pi_models_target}.pre-deploy.bak"

if [[ -L "$pi_models_target" && ! -e "$pi_models_target" ]]; then
  # Dangling symlink left over from a previous run/crash: nothing live to
  # preserve, and jq/install below would just fail on it. Clear it first.
  rm -f "$pi_models_target"
fi

if [[ -e "$pi_models_target" || -L "$pi_models_target" ]]; then
  if ! jq empty "$pi_models_target" 2>/dev/null; then
    echo "pre_deploy: $pi_models_target is not valid JSON, refusing to touch it" >&2
    exit 1
  fi
  # install (not cp) so the backup lands mode 600 in one step, atomically
  # replacing any stale backup from a prior run. Target is only removed once
  # the backup is confirmed on disk.
  if ! install -m 600 "$pi_models_target" "$pi_models_backup"; then
    echo "pre_deploy: failed to back up $pi_models_target to $pi_models_backup" >&2
    exit 1
  fi
  rm -f "$pi_models_target"
fi
