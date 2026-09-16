---
kind: precondition
when:
  tools: ["repowise_*"]
# fail when the index has a last_sync_commit that is not HEAD
probe: root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0; [ -d "$root/.repowise" ] || exit 0; last=$(repowise status --format json "$root" 2>/dev/null | sed -n 's/.*"last_sync_commit": *"\([0-9a-f]*\)".*/\1/p'); [ -z "$last" ] && exit 0; head=$(git rev-parse HEAD); [ "$last" = "$head" ] && exit 0; echo "index at ${last%${last#???????}}, HEAD ${head%${head#???????}}"; exit 1
on_fail: run
fix: repowise update
timeout: 20
message: "repowise index stale ({stdout}) — running `repowise update`"
---
