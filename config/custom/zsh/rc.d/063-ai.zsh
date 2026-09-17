export FFF_FRECENCY_DB="$HOME/.config/pi-fff/frecency.db"
export FFF_HISTORY_DB="$HOME/.config/pi-fff/history.db"
# PI_FFF_MODE moved to .zshenv — must apply to non-interactive shells too
# Plannotator over herdr remote host: pi runs on the Mac, I'm on omarchy. Never
# `open` (headless Mac screen); print a LAN URL to open in Zen on the client.
# terminal-browser split is parked until zenbu-labs/terminal-browser ships the
# perf fix (merged, unpublished) — then swap back to plannotator-terminal-browser.
export PLANNOTATOR_BROWSER=none
export PLANNOTATOR_URL_HOST="$(ipconfig getifaddr en0 2>/dev/null || hostname)"
