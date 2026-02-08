---
name: block-sudo-dotter
enabled: true
event: bash
pattern: sudo\s+dotter
action: block
---

**Do not run dotter with sudo.**

Dotter handles privilege escalation internally when needed. Running with sudo causes:
- Incorrect file ownership (files owned by root instead of user)
- Broken symlinks
- Permission issues in user's home directory

Just run `dotter` directly - it will prompt for elevation only when required.
