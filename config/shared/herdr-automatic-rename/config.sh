# herdr-automatic-rename config. Sourced (bash) by the plugin engine before
# naming.sh — must be a file here, not zsh env vars: the engine also runs from
# herdr server events, which never inherit shell exports. Arrays are why it's
# a script (ICON_MAP, SHELLS, PROGRAM_ALIASES, ...).
# All knobs + defaults: config.example.sh in the plugin dir
# (~/.config/herdr/plugins/github/herdr-automatic-rename-*/).
#
# Defaults we keep: NAME_TABS=1, AUTO_INDEX=1 (workspaces+tabs+agents),
# AGENT_TITLES=1 (agent tabs show task), MAX_NAME_LEN=20, HIDE_SHELL=0.

# Program icon next to the name (Nerd Font glyphs).
ICONS_ENABLED=1
