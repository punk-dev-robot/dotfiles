#!/usr/bin/env bash
# Advisory only: remind the model to use the Linear workflow skill when the
# session involves agent task management. This hook must not write to Linear.

cat <<'EOF'
[linear-agent-workflow]
For agent task planning, Linear issue work, spec-driven task tracking, discovered follow-ups, or worktree handoff:

1. Invoke the linear-agent-workflow skill.
2. Prime with read-only Linear context before choosing work.
3. Use team 62f87de9-2d7b-401d-8bbd-749477d7a773 by default.
4. Keep notes lightweight; no continuous journal.
5. Do not write to Linear from hooks or without explicit task intent.
EOF

exit 0
