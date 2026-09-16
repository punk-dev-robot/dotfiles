---
kind: precondition
when:
  tools: ["repowise_*"]
# fail only inside a git repo that has no .repowise/ anywhere up to its root
probe: root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0; d=$PWD; while :; do [ -d "$d/.repowise" ] && exit 0; [ "$d" = "$root" ] && { echo "$root"; exit 1; }; d=$(dirname "$d"); done
on_fail: ask
fix: repowise init
message: "repowise index missing in {stdout} — run `repowise init`?"
---
