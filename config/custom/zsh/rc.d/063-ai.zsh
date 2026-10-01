export FFF_FRECENCY_DB="$HOME/.config/pi-fff/frecency.db"
export FFF_HISTORY_DB="$HOME/.config/pi-fff/history.db"
# PI_FFF_MODE moved to .zshenv — must apply to non-interactive shells too
# Plannotator: local sessions (omarchy, plain mac terminal) keep the default
# browser. Mac herdr pane = headless server viewed from omarchy: open the
# loopback review URL in a terminal-browser split (renders in the herdr client,
# localhost resolves on the mac, nothing exposed on the LAN).
if [[ $OSTYPE == darwin* && $HERDR_ENV == 1 ]]; then
  export PLANNOTATOR_BROWSER="$HOME/.local/bin/plannotator-terminal-browser"
fi
