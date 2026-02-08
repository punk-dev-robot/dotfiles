#!/bin/zsh

if [[ ! -o interactive ]]; then
    echo "This script is meant to be run interactively, try \`upd\` instead"
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Counters
total_steps=8
current_step=0
failed_steps=0

# Functions
print_header() {
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${BOLD}                           System Update Manager                              ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo -e "${BLUE}                             $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    echo
}

print_section() {
    ((current_step++))
    echo
    echo -e "${BLUE}[$current_step/$total_steps]${RESET} ${BOLD}===== $1 =====${RESET}"
}

print_success() {
    echo -e "${GREEN}[✓]${RESET} $1"
}

print_error() {
    echo -e "${RED}[✗]${RESET} $1"
    ((failed_steps++))
}

print_info() {
    echo -e "${BLUE}[*]${RESET} $1"
}

print_separator() {
    echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────────${RESET}"
}

# Start
print_header

# Check for news
print_section "Checking for news"
news_output=$(yay -Pw 2>/dev/null)
if [[ -n "$news_output" ]]; then
    echo "$news_output"
    print_success "News found - please review above"
    echo -e "${YELLOW}Press Enter to continue...${RESET}"
    read -r
else
    print_info "No news"
fi
print_separator

# Remove orphans
print_section "Removing orphan packages"
# Use ${(f)...} to split output on newlines into array - zsh doesn't split
# unquoted variables on whitespace by default (unlike bash)
orphans=(${(f)"$(yay --quiet --query --deps --unrequired)"})
if (( ${#orphans} > 0 )); then
    # Expand array properly so each package is a separate argument
    yay --remove --recursive "${orphans[@]}"
    if [[ $? -eq 0 ]]; then
        print_success "Orphans removed"
    else
        print_error "Failed to remove some orphans"
    fi
else
    print_info "No orphans to remove"
fi
print_separator

# Update system packages
print_section "Updating repository and AUR packages"
yay -Syu --devel
if [[ $? -eq 0 ]]; then
    print_success "System packages updated"
else
    print_error "Failed to update some packages"
fi

# Update neovim nightly
yay -S --needed neovim-nightly-bin
if [[ $? -eq 0 ]]; then
    print_success "Neovim nightly updated"
else
    print_error "Failed to update Neovim nightly"
fi
print_separator

# Refresh caches and update tools
print_section "Refreshing caches and updating tools"
\rm -f "$XDG_CACHE_HOME"/zsh-snap/eval/* 2>/dev/null
print_info "Znap eval cache cleared"

uv tool upgrade --all
if [[ $? -eq 0 ]]; then
    print_success "UV tools updated"
else
    print_info "UV tools update skipped or failed"
fi

\rm -f "$XDG_CACHE_HOME"/cliphist/db 2>/dev/null
print_info "Cliphist cache cleared"
print_separator

# Update eget binaries
print_section "Updating eget binaries"
eget --download-all
if [[ $? -eq 0 ]]; then
    print_success "Eget binaries updated"
else
    print_info "Some eget binaries failed to update"
fi
print_separator

# Update znap packages
print_section "Updating znap packages"
znap pull
if [[ $? -eq 0 ]]; then
    print_success "Znap packages updated"
else
    print_error "Failed to update znap packages"
fi
print_separator

# Update firmware
print_section "Updating firmware"
fwupdmgr refresh >/dev/null 2>&1
refresh_exit_code=$?
if [[ $refresh_exit_code -eq 0 ]]; then
    print_info "Firmware metadata refreshed"
elif [[ $refresh_exit_code -eq 2 ]]; then
    print_info "Firmware metadata already up to date"
else
    print_error "Failed to refresh firmware metadata"
fi

# Check if updates are available
fwupdmgr get-updates >/dev/null 2>&1
check_exit_code=$?
if [[ $check_exit_code -eq 2 ]]; then
    print_info "No firmware updates available"
elif [[ $check_exit_code -eq 0 ]]; then
    # Updates are available, install them
    fwupdmgr update
    if [[ $? -eq 0 ]]; then
        print_success "Firmware updated"
    else
        print_error "Failed to update firmware"
    fi
else
    print_error "Failed to check for firmware updates"
fi

# Summary
echo
print_separator
echo
echo -e "${BOLD}===== Update Summary =====${RESET}"
if [[ $failed_steps -eq 0 ]]; then
    echo -e "${GREEN}[✓] All updates completed successfully!${RESET}"
else
    echo -e "${YELLOW}[!] Update completed with $failed_steps errors${RESET}"
fi
echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${RESET}"
echo
