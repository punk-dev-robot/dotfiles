export FFF_FRECENCY_DB="$HOME/.config/pi-fff/frecency.db"
export FFF_HISTORY_DB="$HOME/.config/pi-fff/history.db"
# pi-fff replaces built-in grep/find instead of adding ffgrep/fffind alongside them.
# Precedence is --fff-mode flag > PI_FFF_MODE > default(tools-and-ui); there is no
# persistent config key, so the env var is the only route that survives a new session.
export PI_FFF_MODE=override
