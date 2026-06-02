#!/bin/zsh

##
# Plugin manager
#

local znap=~znap/zsh-snap/znap.zsh

# Auto-install Znap if it's not there yet.
if ! [[ -r $znap ]]; then   # Check if the file exists and can be read.
  mkdir -p ~znap
  # Using fork with fix for duplicate repository basenames
  # Original: https://github.com/marlonrichert/zsh-snap.git
  git -C ~znap clone --depth 1 -- https://github.com/punk-dev-robot/zsh-snap.git
fi

. $znap   # Load Znap.

##
# Prompt theme
#

# Reduce startup time by making the left side of the primary prompt visible
# *immediately.*
# znap prompt sindresorhus/pure
znap eval starship 'starship init zsh --print-full-init'
znap prompt
