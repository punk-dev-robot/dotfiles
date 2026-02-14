#!/usr/bin/env bash
echo "Post deploy script"

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
