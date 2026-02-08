#!/bin/zsh

##
# Environment variables
#

# -U ensures each entry in these is unique (that is, discards duplicates).
export -U PATH path FPATH fpath MANPATH manpath
export -UT INFOPATH infopath  # -T creates a "tied" pair; see below.

# Add your functions to your $fpath, so you can autoload them.
fpath=(
    $ZDOTDIR/functions
    $fpath
    ~/.local/share/zsh/site-functions
)

# if command -v brew > /dev/null; then
#   # `znap eval <name> '<command>'` is like `eval "$( <command> )"` but with
#   # caching and compilation of <command>'s output, making it 10 times faster.
#   znap eval brew-shellenv 'brew shellenv'
#
#   # Add dirs containing completion functions to your $fpath and they will be
#   # picked up automatically when the completion system is initialized.
#   # Here, we add it to the end of $fpath, so that we use brew's completions
#   # only for those commands that zsh doesn't already know how to complete.
#   fpath+=(
#       $HOMEBREW_PREFIX/share/zsh/site-functions
#   )
# fi

# Shell utility library directory
export ZSH_LIB_DIR="$ZDOTDIR/lib"

# Default applications
export EDITOR="nvim"
export VISUAL="nvim"
export TERMINAL="alacritty"
export BROWSER="zen-browser"
export READER="zathura"
export FILE="lf"
export PAGER="moar"
# use nvim as man viewer
export MANPAGER='nvim +Man!'

# Settings
# Kill the lag after <ESC> (https://dougblack.io/words/zsh-vi-mode.html)
export KEYTIMEOUT=1
