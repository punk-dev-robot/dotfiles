---
kind: precondition
when:
  tools: ["repowise_*"]
# fail only inside a git repo with no built index — a bare .repowise/ dir (the MCP
# server creates one) is not an index, so probe the synced commit, not the dir
probe: root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0; repowise status --format json "$root" 2>/dev/null | grep -q '"last_sync_commit": *"[0-9a-f]\{7,\}"' && exit 0; echo "$root"; exit 1
on_fail: ask
fix: repowise init
message: "repowise index missing in {stdout} — run `repowise init`?"
---
