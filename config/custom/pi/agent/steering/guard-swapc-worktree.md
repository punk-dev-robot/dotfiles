---
kind: guard
level: advise
when:
  tools: [delegate_project]
tool: delegate_project
field: branch
check: 'm=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0; m=${m%/.git}; case "$m" in "$HOME"/dev/swapc/*) ;; *) exit 0 ;; esac; [ -n "$1" ] || { echo "pass an explicit branch."; exit 1; }; git -C "$m" worktree list --porcelain | grep -qxF "branch refs/heads/$1" && exit 0; echo "no worktree for $1. Run: wt -C $m switch --create $1 --no-cd -y (add --base <parent> when stacking), then retry."; exit 1'
---
In swapc repos a Lead's worktree comes from `wt`: it sits beside the main checkout, gets the agentctx links, `GH_TOKEN` and the install/build hooks before the Lead starts.
