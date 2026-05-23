#!/usr/bin/env bash
# SessionStart hook — auto-invokes the task-observer skill on every Claude
# Code session so the user never has to remember to load it. Output reaches
# the model as additional context (system-reminder block) and primes the
# session to (1) load task-observer before any tool use and (2) check the
# observation log for OPEN observations to apply mid-session.
#
# Reasoning: the task-observer SKILL.md and its USER-GUIDE both call for a
# "dual-layer" activation pattern — description-level skill matching alone
# is unreliable because the model focuses on the user's task, not on
# loading background skills. The structural CLAUDE.md instruction is the
# first layer; this hook is the second layer.

cat <<'EOF'
[task-observer auto-activation]
This is a task-oriented Claude Code session. Before any tool use:

1. Invoke the task-observer skill now (do not wait to be asked).
2. Tail ~/Documents/notes/skill-observations/log.md and apply any OPEN
   observations tagged to skills you may load during this session.
3. Throughout the session, log observations to that file in the skill's
   structured format — do not wait for the user to ask "Any observations
   logged?". Logging is background work; it must not interrupt the task.

Workspace folder for task-observer = ~/Documents/notes/. Never write
skill-observations/ or skill-updates/ into the current project cwd.
EOF

exit 0
