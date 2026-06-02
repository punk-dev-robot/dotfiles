#!/usr/bin/env bash
# Stop hook — fires when the model is about to stop producing output for
# the turn. Forces the model to flush any unrecorded task-observer
# observations to disk before stopping, so the user never has to ask
# "Any observations logged?" themselves.
#
# Claude Code's Stop hook output is fed back as additional context that
# the model can act on before actually stopping. If observations exist
# but aren't yet written, the model will write them and then stop.

cat <<'EOF'
[task-observer end-of-turn flush]
Before stopping this turn:

1. If task-observer captured any observations in-session that are NOT
   yet on disk, append them to ~/Documents/notes/skill-observations/log.md
   using the skill's documented format. Do not require the user to ask.
2. If any staged skill updates were produced, write them under
   ~/Documents/notes/skill-updates/ for later review.
3. If nothing new was captured this turn, simply stop — no need to
   surface an "empty" summary to the user.

This runs every Stop event; idempotent on no-op turns.
EOF

exit 0
