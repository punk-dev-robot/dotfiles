#!/bin/bash
# Color definitions for terminal output
# Provides consistent color variables and text formatting

# Check if terminal supports colors
if [[ -t 1 ]] && [[ -n "$TERM" ]] && which tput &>/dev/null && tput colors &>/dev/null; then
  _colors_supported=true
  ncolors=$(tput colors)
else
  _colors_supported=false
fi

if [[ $_colors_supported == true ]] && [[ $ncolors -ge 8 ]]; then
  # Text formatting
  export BOLD="$(tput bold)"
  export UNDERLINE="$(tput sgr 0 1)"
  export REVERSE="$(tput rev)"
  export RESET="$(tput sgr0)"

  # Regular colors
  export BLACK="$(tput setaf 0)"
  export RED="$(tput setaf 1)"
  export GREEN="$(tput setaf 2)"
  export YELLOW="$(tput setaf 3)"
  export BLUE="$(tput setaf 4)"
  export MAGENTA="$(tput setaf 5)"
  export CYAN="$(tput setaf 6)"
  export WHITE="$(tput setaf 7)"

  # Bright colors (if supported)
  if [[ $ncolors -ge 16 ]]; then
    export BRIGHT_BLACK="$(tput setaf 8)"
    export BRIGHT_RED="$(tput setaf 9)"
    export BRIGHT_GREEN="$(tput setaf 10)"
    export BRIGHT_YELLOW="$(tput setaf 11)"
    export BRIGHT_BLUE="$(tput setaf 12)"
    export BRIGHT_MAGENTA="$(tput setaf 13)"
    export BRIGHT_CYAN="$(tput setaf 14)"
    export BRIGHT_WHITE="$(tput setaf 15)"
  fi

  # Extended colors for 256 color terminals
  if [[ $ncolors -ge 256 ]]; then
    export ORANGE="$(tput setaf 208)"
    export PURPLE="$(tput setaf 171)"
    export TAN="$(tput setaf 3)"
    export BLUE2="$(tput setaf 38)"
  else
    # Fallback for non-256 color terminals
    export ORANGE="$YELLOW"
    export PURPLE="$MAGENTA"
    export TAN="$YELLOW"
    export BLUE2="$BLUE"
  fi
else
  # No color support - set all to empty
  export BOLD=""
  export UNDERLINE=""
  export REVERSE=""
  export RESET=""
  export BLACK=""
  export RED=""
  export GREEN=""
  export YELLOW=""
  export BLUE=""
  export MAGENTA=""
  export CYAN=""
  export WHITE=""
  export BRIGHT_BLACK=""
  export BRIGHT_RED=""
  export BRIGHT_GREEN=""
  export BRIGHT_YELLOW=""
  export BRIGHT_BLUE=""
  export BRIGHT_MAGENTA=""
  export BRIGHT_CYAN=""
  export BRIGHT_WHITE=""
  export ORANGE=""
  export PURPLE=""
  export TAN=""
  export BLUE2=""
fi

# Color functions for easy text coloring
color::red() { echo -e "${RED}$*${RESET}"; }
color::green() { echo -e "${GREEN}$*${RESET}"; }
color::yellow() { echo -e "${YELLOW}$*${RESET}"; }
color::blue() { echo -e "${BLUE}$*${RESET}"; }
color::magenta() { echo -e "${MAGENTA}$*${RESET}"; }
color::cyan() { echo -e "${CYAN}$*${RESET}"; }
color::white() { echo -e "${WHITE}$*${RESET}"; }
color::black() { echo -e "${BLACK}$*${RESET}"; }

# Special colors
color::orange() { echo -e "${ORANGE}$*${RESET}"; }
color::purple() { echo -e "${PURPLE}$*${RESET}"; }

# Text formatting functions
color::bold() { echo -e "${BOLD}$*${RESET}"; }
color::underline() { echo -e "${UNDERLINE}$*${RESET}"; }
color::reverse() { echo -e "${REVERSE}$*${RESET}"; }

# Combined formatting
color::bold_red() { echo -e "${BOLD}${RED}$*${RESET}"; }
color::bold_green() { echo -e "${BOLD}${GREEN}$*${RESET}"; }
color::bold_yellow() { echo -e "${BOLD}${YELLOW}$*${RESET}"; }
color::bold_blue() { echo -e "${BOLD}${BLUE}$*${RESET}"; }
color::bold_purple() { echo -e "${BOLD}${PURPLE}$*${RESET}"; }

