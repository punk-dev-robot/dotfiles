#!/bin/bash
# Logging functions for consistent output and notifications
# Depends on: colors.sh

# Default log tag for systemd journal
: ${LOG_TAG:="shell-script"}

# Logging functions with colors and icons
log::header() {
    printf "\n${BOLD}${PURPLE}========== %s ==========${RESET}\n" "$@"
}

log::info() {
    printf "${BLUE}ℹ %s${RESET}\n" "$@"
    echo "$@" | systemd-cat -t "$LOG_TAG" -p info
}

log::success() {
    printf "${GREEN}✔ %s${RESET}\n" "$@"
    echo "$@" | systemd-cat -t "$LOG_TAG" -p info
}

log::error() {
    printf "${RED}✖ %s${RESET}\n" "$@" >&2
    echo "$@" | systemd-cat -t "$LOG_TAG" -p err
}

log::warning() {
    printf "${YELLOW}⚠ %s${RESET}\n" "$@"
    echo "$@" | systemd-cat -t "$LOG_TAG" -p warning
}

log::debug() {
    if [[ -n "$DEBUG" ]]; then
        printf "${CYAN}🔍 %s${RESET}\n" "$@" >&2
        echo "$@" | systemd-cat -t "$LOG_TAG" -p debug
    fi
}

log::arrow() {
    printf "➜ %s\n" "$@"
}

log::underline() {
    printf "${UNDERLINE}${BOLD}%s${RESET}\n" "$@"
}

log::bold() {
    printf "${BOLD}%s${RESET}\n" "$@"
}

log::note() {
    printf "${UNDERLINE}${BOLD}${BLUE}Note:${RESET} ${BLUE}%s${RESET}\n" "$@"
}

# Section headers for better organization
log::section() {
    local title="$1"
    local width=60
    local padding=$(( (width - ${#title} - 2) / 2 ))
    
    echo
    printf "${BOLD}${BLUE}"
    printf '=%.0s' $(seq 1 $width)
    printf "${RESET}\n"
    
    printf "${BOLD}${BLUE}="
    printf ' %.0s' $(seq 1 $padding)
    printf "%s" "$title"
    printf ' %.0s' $(seq 1 $padding)
    [[ $(( (width - ${#title} - 2) % 2 )) -eq 1 ]] && printf " "
    printf "=${RESET}\n"
    
    printf "${BOLD}${BLUE}"
    printf '=%.0s' $(seq 1 $width)
    printf "${RESET}\n"
}

# Simple separator line
log::separator() {
    printf "${BLUE}"
    printf '─%.0s' $(seq 1 ${1:-60})
    printf "${RESET}\n"
}

# Log with timestamp
log::timestamp() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "[%s] %s\n" "$timestamp" "$@"
    echo "[$timestamp] $@" | systemd-cat -t "$LOG_TAG" -p info
}

# Log command execution
log::exec() {
    log::arrow "Executing: $@"
    "$@"
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        log::success "Command completed successfully"
    else
        log::error "Command failed with exit code: $exit_code"
    fi
    return $exit_code
}