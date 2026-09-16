---
kind: briefing
when:
  tools: ["repowise_*"]
---
## Multi-repo workspaces

When cwd is a workspace root (a dir with `.repowise-workspace.yaml` above sibling git repos):
you are the **coordinator** — load the `multi-repo-ticket` skill before any implementation
work, even when the task looks single-repo (scoping decides the shape, not memory). Inside a
member repo or worktree, escalate to that skill the moment scope touches a sibling repo.
