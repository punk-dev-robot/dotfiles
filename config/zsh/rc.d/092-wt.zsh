#!/bin/zsh
##
# Worktrunk shell aliases
# Make `wt` the muscle-memory default for branch / merge / list / cleanup.
#
# Naming convention: short, distinct from `g*` git aliases.
#   wn  worktree-new        wt switch --create
#   ws  worktree-switch     wt switch (interactive picker if no arg)
#   wl  worktree-list       wt list --full
#   wm  worktree-merge      wt merge
#   wr  worktree-remove     wt remove
#   wc  worktree-clean      wt clean (project alias -> wt step prune)
#   wd  worktree-diff       wt step diff
#   wt- worktree-back       wt switch -   (toggle to previous)
##

# Only define aliases when wt is on PATH (e.g., not on a fresh machine).
if (( $+commands[wt] )); then
  alias wn='wt switch --create'
  alias ws='wt switch'
  alias wl='wt list --full'
  alias wm='wt merge'
  alias wr='wt remove'
  alias wc='wt clean'
  alias wd='wt step diff'
  alias wt-='wt switch -'

  # `wnc <branch>` — new worktree + spawn Claude Code in it.
  # Useful when handing off a task: opens a worktree pre-configured with
  # the project hooks and immediately launches an agent.
  wnc() {
    if [[ -z "$1" ]]; then
      print -u2 "usage: wnc <branch> [task-description]"
      return 2
    fi
    local branch="$1"; shift
    wt switch --create "$branch" -x claude -- "$*"
  }
fi
