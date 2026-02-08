#!/usr/bin/env bash
#
# Test tmux + alacritty systemd socket activation
#
set -euxo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

ITERATIONS=${1:-5}

stop_all() {
    # Stop in reverse dependency order - let errors show!
    systemctl --user stop alacritty@{work,dots,claude}.service
    systemctl --user stop tmux-sessions.target
    systemctl --user stop tmux-restore.service
    systemctl --user stop tmux.service
    systemctl --user stop tmux.socket
    
    # Kill tmux server to ensure no sessions exist
    # tmux kill-server  # Commented out - might be affecting socket
}

check_attachments() {
    local errors=0
    declare -A expected=([work]=work [dots]=dots [claude]=claude)
    
    while IFS=: read -r pid session; do
        [ -z "$pid" ] && continue
        local ppid=$(ps -o ppid= -p "$pid" | tr -d ' ')
        [ -z "$ppid" ] && continue
        
        local cmd=$(ps -o args= -p "$ppid")
        if [[ "$cmd" =~ --class[[:space:]]term-([^[:space:]]+) ]]; then
            local name="${BASH_REMATCH[1]}"
            if [ "$session" != "${expected[$name]}" ]; then
                echo -e "  ${RED}✗ term-$name → $session (expected ${expected[$name]})${NC}"
                ((errors++))
            else
                echo -e "  ${GREEN}✓ term-$name → $session${NC}"
            fi
        fi
    done < <(tmux list-clients -F "#{client_pid}:#{session_name}")
    
    [ $errors -eq 0 ]
}

run_iteration() {
    local n=$1
    echo -e "\n━━━ Iteration $n/$ITERATIONS ━━━"
    
    echo -e "\n--- Stopping all services ---"
    stop_all
    
    echo -e "\n--- Status after stop_all ---"
    systemctl --user status tmux.socket tmux.service alacritty@{work,dots,claude}.service --no-pager || true
    
    echo -e "\n--- Starting tmux.socket ---"
    systemctl --user start tmux.socket
    
    echo -e "\n--- Starting alacritty services (will trigger tmux.service via socket) ---"
    systemctl --user start alacritty@{work,dots,claude}.service
    
    echo -e "\n--- Status after starting alacritty services ---"
    systemctl --user status tmux.socket tmux.service alacritty@{work,dots,claude}.service --no-pager || true
    
    # Check services
    echo "Services:"
    # Check tmux.service got activated
    if systemctl --user is-active tmux.service >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ tmux.service (socket activated)${NC}"
    else
        echo -e "  ${RED}✗ tmux.service${NC}"
        return 1
    fi
    
    for svc in work dots claude; do
        if systemctl --user is-active "alacritty@$svc.service" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓ alacritty@$svc${NC}"
        else
            echo -e "  ${RED}✗ alacritty@$svc${NC}"
            return 1
        fi
    done
    
    # Check attachments
    echo "Attachments:"
    check_attachments || return 1
    
    # Check windows - give hyprland a moment to register them
    sleep 0.5
    local count=$(hyprctl clients | grep -cE "class: term-(work|dots|claude)" || echo 0)
    if [ "$count" -eq 3 ]; then
        echo -e "Windows: ${GREEN}✓ $count/3${NC}"
    else
        echo -e "Windows: ${RED}✗ $count/3${NC}"
        return 1
    fi
    
    # Explicit success return
    return 0
}

# Main
echo "=== TMux + Alacritty Test ==="

# Clear all logs
echo "Clearing logs..."
rm -f /tmp/tmux-service.log /tmp/tmux-systemd.log /tmp/alacritty-*.log /tmp/tmux-restore.log 2>/dev/null || true
touch /tmp/tmux-service.log /tmp/tmux-systemd.log

# Lock file to prevent concurrent runs
LOCKFILE="/tmp/test-tmux-alacritty.lock"
if [ -f "$LOCKFILE" ]; then
    echo -e "${RED}ERROR: Another test instance is already running${NC}"
    echo "Lock file exists: $LOCKFILE"
    echo "If no test is running, remove it: rm $LOCKFILE"
    exit 1
fi

# Create lock file and ensure it's removed on exit
trap "rm -f $LOCKFILE" EXIT
touch "$LOCKFILE"

cd /home/kuba/dotfiles
dotter deploy -v
systemctl --user daemon-reload

passed=0
echo "Starting test loop for $ITERATIONS iterations..."
for ((i=1; i<=ITERATIONS; i++)); do
    echo "DEBUG: Running iteration $i"
    if run_iteration $i; then
        passed=$((passed + 1))
        echo -e "${GREEN}PASS${NC}"
        echo "DEBUG: Iteration $i passed, passed count: $passed"
    else
        echo -e "${RED}FAIL${NC}"
        echo "DEBUG: Iteration $i failed, breaking"
        break
    fi
    
    # Give time to observe the terminals between iterations
    if [ $i -lt $ITERATIONS ]; then
        echo "Waiting 3 seconds before next iteration..."
        sleep 3
    fi
done
echo "DEBUG: Test loop completed, passed=$passed, ITERATIONS=$ITERATIONS"

echo -e "\n━━━ Summary ━━━"
echo "Passed: $passed/$ITERATIONS"

# Store exit code
if [ $passed -eq $ITERATIONS ]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed!"
    exit 1
fi