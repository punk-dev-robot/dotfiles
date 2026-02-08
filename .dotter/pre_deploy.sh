#!/usr/bin/env bash
echo "Pre deploy script"

# Fix keyd config permissions (dotter creates root-owned files with 600)
sudo chmod -f 644 /etc/keyd/*.conf 2>/dev/null || true
