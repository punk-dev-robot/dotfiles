#!/usr/bin/env bash
echo "Post deploy script"

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

herdr_plugin_at_commit() {
    local plugin_id="$1"
    local commit="$2"

    herdr plugin list --plugin "$plugin_id" --json |
        jq -e --arg commit "$commit" \
            '.result.plugins | any(.source.resolved_commit == $commit)' >/dev/null 2>&1
}

install_herdr_plugin() {
    local plugin_id="$1"
    local repo="$2"
    local commit="$3"

    if herdr_plugin_at_commit "$plugin_id" "$commit"; then
        return
    fi

    if ! herdr plugin install "$repo" --ref "$commit" --yes; then
        echo "  error: failed to install $plugin_id" >&2
        return 1
    fi

    if ! herdr_plugin_at_commit "$plugin_id" "$commit"; then
        echo "  error: $plugin_id was not installed at $commit" >&2
        return 1
    fi
}

if command -v herdr >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    plugin_install_failed=0

    install_herdr_plugin \
        herdr-splits lmilojevicc/herdr-splits.nvim \
        107273e004e4f7ef07f13c83164d2cb2c51df65d ||
        plugin_install_failed=1

    if command -v wt >/dev/null 2>&1; then
        install_herdr_plugin \
            worktrunk devashish2203/herdr-worktrunk \
            e9131c0b576fd68635194c758c9691dbfb778b61 ||
            plugin_install_failed=1
    else
        echo "  error: worktrunk is required for the Herdr Worktrunk plugin" >&2
        plugin_install_failed=1
    fi

    install_herdr_plugin \
        termscope iurysza/termscope \
        cbc6da8103c263343b7082e27e804cc91312f944 ||
        plugin_install_failed=1
    install_herdr_plugin \
        herdr-file-viewer smarzban/herdr-file-viewer \
        96fcc0a2bdd2727ec88c38f8c8806f97b7ca0ea0 ||
        plugin_install_failed=1
    install_herdr_plugin \
        persiyanov.reviewr persiyanov/herdr-reviewr \
        160ad607a195ee35ac9450e887974b3b5ddc4479 ||
        plugin_install_failed=1

    if herdr_plugin_at_commit \
        herdr-splits 107273e004e4f7ef07f13c83164d2cb2c51df65d &&
        herdr plugin list --plugin vim-herdr-navigation --json |
            jq -e '.result.plugins | length > 0' >/dev/null 2>&1; then
        herdr plugin uninstall vim-herdr-navigation ||
            plugin_install_failed=1
    fi

    if (( plugin_install_failed )); then
        exit 1
    fi
fi
