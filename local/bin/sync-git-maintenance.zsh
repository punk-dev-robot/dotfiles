#!/usr/bin/env zsh

# Git Maintenance Sync Script
# Keeps git maintenance configuration in sync with actual repositories

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔄 Syncing git maintenance configuration..."

# Step 1: Remove non-existent repositories
echo -e "\n${YELLOW}Step 1: Cleaning up non-existent repositories...${NC}"
removed_count=0

# Process removals
for repo in $(git config --global --get-all maintenance.repo 2>/dev/null | sort | uniq); do
    if [[ ! -d "$repo/.git" ]]; then
        echo -e "${RED}✗ Removing non-existent: $repo${NC}"
        git maintenance unregister --config-file ~/.gitconfig "$repo" 2>/dev/null || true
        ((removed_count++))
    fi
done

# Step 2: Find all git repositories in specified directories
echo -e "\n${YELLOW}Step 2: Finding all git repositories...${NC}"
repos=()

# Add your development directories here
search_dirs=(
    "/home/kuba/dev"
    "/home/kuba/.local/share/znap"
)

for dir in "${search_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        while IFS= read -r repo; do
            repos+=("$repo")
        done < <(find "$dir" -name ".git" -type d -maxdepth 4 2>/dev/null | sed 's|/\.git$||' | sort)
    fi
done

# Step 3: Register new repositories
echo -e "\n${YELLOW}Step 3: Registering repositories for maintenance...${NC}"
added_count=0

# Get current registered repos
current_repos=()
while IFS= read -r repo; do
    current_repos+=("$repo")
done < <(git config --global --get-all maintenance.repo 2>/dev/null | sort | uniq)

# Convert to associative array for quick lookup
typeset -A current_repos_map
for repo in "${current_repos[@]}"; do
    current_repos_map[$repo]=1
done

# Register new repos
for repo in "${repos[@]}"; do
    if [[ -z "${current_repos_map[$repo]:-}" ]]; then
        echo -e "${GREEN}✓ Registering: $repo${NC}"
        git maintenance register --config-file ~/.gitconfig "$repo"
        ((added_count++))
    fi
done

# Step 4: Summary
echo -e "\n${GREEN}✅ Sync complete!${NC}"
echo "  - Removed: $removed_count non-existent repositories"
echo "  - Added: $added_count new repositories"
echo "  - Total registered: $(git config --global --get-all maintenance.repo 2>/dev/null | wc -l) repositories"

# Step 5: Reset failed service if needed
if systemctl --user is-failed git-maintenance@hourly.service &>/dev/null; then
    echo -e "\n${YELLOW}Resetting failed git-maintenance service...${NC}"
    systemctl --user reset-failed git-maintenance@hourly.service
    echo -e "${GREEN}✓ Service reset complete${NC}"
fi