#!/bin/zsh

##
# History settings
#
# Always set these first, so history is preserved, no matter what happens.
#

# Enable additional glob operators. (Globbing = pattern matching)
# https://zsh.sourceforge.io/Doc/Release/Expansion.html#Filename-Generation
setopt extended_glob

# Tell zsh where to store history.
  HISTFILE=${XDG_DATA_HOME:=~/.local/share}/zsh/history

# Just in case: If the parent directory doesn't exist, create it.
[[ -d $HISTFILE:h ]] ||
    mkdir -p $HISTFILE:h

# Max number of entries to keep in history file.
SAVEHIST=$(( 100 * 1000 ))      # Use multiplication for readability.

# Max number of history entries to keep in memory.
HISTSIZE=$(( 1.2 * SAVEHIST ))  # Zsh recommended value

# Use modern file-locking mechanisms, for better safety & performance.
setopt hist_fcntl_lock

# Keep only the most recent copy of each duplicate entry in history.
setopt hist_ignore_all_dups

# Write commands to the history file immediately, share across sessions,
# and record timestamps and durations.
setopt incappendhistory
setopt extended_history
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_verify

# Auto-sync history between concurrent sessions.
setopt share_history
