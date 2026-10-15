---
kind: briefing
when:
  tools: [delegate_project]
---
## swapc worktrees

In a `~/dev/swapc/<repo>` checkout, create each Lead's worktree before `delegate_project`:
`wt -C ~/dev/swapc/<repo> switch --create <branch> --no-cd -y` (`--base <parent>` when stacking), then
delegate that same branch. Herdsman opens the existing worktree; `steering/guard-swapc-worktree` blocks the call otherwise.
