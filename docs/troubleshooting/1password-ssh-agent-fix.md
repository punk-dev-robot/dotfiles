# 1Password SSH Agent - GitHub Authentication Fix

## Problem
When trying to push to GitHub, received "Permission denied (publickey)" error. The issue occurred after moving from work LastPass to personal 1Password plan.

## Root Cause
The `~/.config/1Password/ssh/agent.toml` file was configured to expose SSH keys from "Employee" and "Private" vaults, but the GitHub SSH key was actually in the "Personal" vault.

## Solution Applied
1. Created new `agent.toml` in dotfiles at `/home/kuba/dotfiles/config/1Password/ssh/agent.toml`
2. Configured it to use the "Personal" vault:
   ```toml
   [[ssh-keys]]
   vault = "Personal"
   ```
3. Deployed with dotter: `dotter deploy -v --force`
4. Verified SSH keys loaded: 5 keys now available from Personal vault
5. Successfully tested GitHub authentication and git push

## Key Files
- `/home/kuba/dotfiles/config/1Password/ssh/agent.toml` - Now managed by dotter
- `/home/kuba/.config/1Password/ssh/agent.toml` - Symlinked by dotter
- Dotter config automatically handles this via existing `"config" = "~/.config"` mapping

## Tags
#ssh #1password #authentication #github #dotfiles #solved