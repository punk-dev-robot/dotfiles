#!/bin/zsh

##
# Shell options that don't fit in any other file.
#
# Set these after sourcing plugins, because those might set options, too.
#

# Don't let > silently overwrite files. To overwrite, use >! instead.
setopt no_clobber

# Treat comments pasted into the command line as comments, not code.
setopt interactive_comments

# Don't treat non-executable files in your $path as commands. This makes sure
# they don't show up as command completions. Settinig this option can impact
# performance on older systems, but should not be a problem on modern ones.
setopt hash_executables_only

# Enable ** and *** as shortcuts for **/* and ***/*, respectively.
# https://zsh.sourceforge.io/Doc/Release/Expansion.html#Recursive-Globbing
setopt glob_star_short

# Sort numbers numerically, not lexicographically.
setopt numeric_glob_sort

# Do not query user before executing rm * or rm path/*
unsetopt rm_star_silent
