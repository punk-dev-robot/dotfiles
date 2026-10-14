---
kind: briefing
when:
  tools: ["repowise_*"]
---
## Multi-repo workspaces

When cwd is a workspace root (a dir with `.repowise-workspace.yaml` above sibling git repos):
you are the **coordinator** — scope the work before any implementation, even when the task
looks single-repo, and make member-repo edits through agents. Herdsman Manager mode
(`/manager` + `delegate_project`, one Lead per branch) is scoped to one git repo: run it from
that member repo's primary workspace. Cross-repo tickets have no settled flow yet (KUB-171
trial): ask the owner before starting one. Inside a member repo or worktree, tell the owner
the moment scope touches a sibling repo.
