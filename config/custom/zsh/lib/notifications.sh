#!/bin/bash
# Desktop notification functions
# Provides systemd-aware notifications with multiple urgency levels

# Check if we're running under systemd as a service (not just in systemd environment)
_is_systemd_service() {
    # We're a systemd service if we're root or if we're explicitly marked as a service
    # but NOT if we're just running in a systemd user session
    [[ $EUID -eq 0 && -n "$INVOCATION_ID" ]] || [[ -n "$NOTIFY_IS_SERVICE" ]]
}

# Get the active user for notifications
_get_notification_user() {
    # If running as service, try to find the logged-in user
    if _is_systemd_service; then
        # Try to get the user who owns the active graphical session
        local active_user=$(loginctl list-sessions --no-legend | awk '$3 == "seat0" {print $3}' | head -n1)
        if [[ -z "$active_user" ]]; then
            # Fallback to any graphical session
            active_user=$(loginctl list-sessions --no-legend | grep -v 'tty' | awk '{print $3}' | head -n1)
        fi
        if [[ -z "$active_user" ]]; then
            # Final fallback
            active_user="kuba"
        fi
        echo "$active_user"
    else
        echo "${USER:-kuba}"
    fi
}

# Core notification function
notify::send() {
    local title="$1"
    local message="$2"
    local icon="${3:-dialog-information}"
    local urgency="${4:-normal}"
    local timeout="${5:-5000}"
    
    # Always log to systemd journal
    echo "$title: $message" | systemd-cat -t "${LOG_TAG:-notification}" -p info
    
    # Check if notify-send is available
    if ! command -v notify-send &> /dev/null; then
        return 0
    fi
    
    # Send desktop notification
    if _is_systemd_service; then
        local user=$(_get_notification_user)
        # Use sudo to run as the target user if we're root, otherwise systemd-run might ask for auth
        if [[ $EUID -eq 0 ]]; then
            sudo -u "$user" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$user")/bus" \
                notify-send -u "$urgency" -i "$icon" -t "$timeout" "$title" "$message" 2>/dev/null || true
        else
            systemd-run --uid="$user" --pipe --quiet \
                notify-send -u "$urgency" -i "$icon" -t "$timeout" "$title" "$message" 2>/dev/null || true
        fi
    else
        notify-send -u "$urgency" -i "$icon" -t "$timeout" "$title" "$message" 2>/dev/null || true
    fi
}

# Urgency-specific functions
notify::critical() {
    local title="$1"
    local message="$2"
    local icon="${3:-dialog-error}"
    notify::send "$title" "$message" "$icon" "critical" 0  # No timeout for critical
}

notify::warning() {
    local title="$1"
    local message="$2"
    local icon="${3:-dialog-warning}"
    notify::send "$title" "$message" "$icon" "normal" 10000
}

notify::normal() {
    local title="$1"
    local message="$2"
    local icon="${3:-dialog-information}"
    notify::send "$title" "$message" "$icon" "normal" 5000
}

notify::info() {
    notify::normal "$@"
}

notify::low() {
    local title="$1"
    local message="$2"
    local icon="${3:-dialog-information}"
    notify::send "$title" "$message" "$icon" "low" 3000
}

notify::success() {
    local title="$1"
    local message="$2"
    local icon="${3:-emblem-default}"  # Checkmark icon
    notify::send "$title" "$message" "$icon" "normal" 5000
}

# Specialized notification types
notify::disk() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    notify::send "$title" "$message" "drive-harddisk" "$urgency"
}

notify::backup() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    notify::send "$title" "$message" "drive-harddisk" "$urgency"
}

notify::system() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    notify::send "$title" "$message" "computer" "$urgency"
}

notify::network() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"
    notify::send "$title" "$message" "network-wired" "$urgency"
}

notify::security() {
    local title="$1"
    local message="$2"
    local urgency="${3:-critical}"
    notify::send "$title" "$message" "security-high" "$urgency"
}

# Fun notification with cowsay if available
notify::cow() {
    local message="$1"
    local urgency="${2:-normal}"
    
    if command -v cowsay &> /dev/null; then
        local cow_message=$(cowsay "$message" 2>/dev/null | head -n 8)
        notify::send "🐄 Moo!" "$cow_message" "dialog-information" "$urgency" 8000
    else
        notify::send "Message" "$message" "dialog-information" "$urgency"
    fi
}