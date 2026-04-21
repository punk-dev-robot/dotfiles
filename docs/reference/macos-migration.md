# macOS Migration Guide

Step-by-step guide for setting up a new Mac from the dotfiles repo. Assumes a fresh macOS account (no account migration).

## Prerequisites

- New Mac with fresh account, signed into Apple ID
- External drive with backup data (see [Backup from old Mac](#backup-from-old-mac))
- This dotfiles repo cloned to `~/dotfiles`

---

## Backup from Old Mac

Run these on the **old** machine before wiping. Mount an external drive at `$EXT` (e.g., `/Volumes/Migration`).

```bash
EXT="/Volumes/Migration"  # adjust to your external drive mount

# 1. Zen browser profile (~612MB)
mkdir -p "$EXT/zen-backup"
cp -R ~/Library/Application\ Support/zen/ "$EXT/zen-backup/"

# 2. Rectangle Pro preferences
defaults export com.knollsoft.Hookshot "$EXT/rectangle-pro.plist"

# 3. SSH keys (if not using 1Password SSH agent)
cp -R ~/.ssh "$EXT/ssh-backup"

# 4. GPG keys (if any)
# gpg --export-secret-keys > "$EXT/gpg-private.asc"

# 5. Raycast — already exported to backups/raycast.rayconfig (password-protected)

# 6. Dotfiles repo (ensure everything is committed)
cd ~/dotfiles && git status
```

---

## New Mac Setup

### Phase 1: Bootstrap (manual steps)

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install git (comes with Xcode CLT, but brew version is newer)
brew install git

# Clone dotfiles
git clone <your-dotfiles-repo-url> ~/dotfiles
cd ~/dotfiles
```

### Phase 2: Install all packages

```bash
# Install everything from Brewfile
brew bundle --file=~/dotfiles/Brewfile

# Install Mac App Store apps (requires Apple ID sign-in)
# mas is installed by the Brewfile, but App Store apps need manual sign-in first
mas install 937984704  # Amphetamine
```

### Phase 3: Deploy dotfiles with dotter

```bash
# Create the local.toml for this machine
cat > ~/dotfiles/.dotter/$(hostname).local.toml << 'EOF'
packages = ["macos"]

[variables]
gh_binary = "/opt/homebrew/bin/gh"
delta_theme_path = "~/.config/delta/catppuccin.gitconfig"
tpm_path = "/opt/homebrew/opt/tpm/share/tpm/tpm"
op_agent_sock = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
home_dir = "/Users/<your-username>"
is_macos = true
EOF

# Preview what dotter will do
cd ~/dotfiles
dotter -v -d

# Deploy
dotter deploy
```

### Phase 4: Restore backups from external drive

```bash
EXT="/Volumes/Migration"  # adjust to your external drive mount

# Zen browser profile
# Install Zen first (already done via Brewfile), launch once to create profile dir, then quit
# Replace the empty profile with backed-up data:
rm -rf ~/Library/Application\ Support/zen/
cp -R "$EXT/zen-backup/" ~/Library/Application\ Support/zen/

# Rectangle Pro preferences
defaults import com.knollsoft.Hookshot "$EXT/rectangle-pro.plist"

# SSH keys (if backed up, and not using 1Password SSH agent)
# cp -R "$EXT/ssh-backup/"* ~/.ssh/
# chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*

# Raycast — import from backups/raycast.rayconfig:
#   Raycast → Settings → Advanced → Import → select the .rayconfig file
```

### Phase 5: Runtime versions

```bash
# Node via fnm
fnm install 22

# Python via pyenv (if needed beyond system python)
# pyenv install 3.13

# Rust
rustup-init

# UV tools
uv tool install basic-memory
uv tool install huggingface-hub
uv tool install serena-agent
uv tool install specify-cli
```

### Phase 6: Post-install configuration

These require manual interaction — can't be fully automated:

1. **1Password** — Sign in, enable SSH agent in Settings → Developer
2. **1Password CLI** — `op signin` (device-specific auth)
3. **Ghostty** — Launch to verify config loaded from `~/.config/ghostty`
4. **Karabiner-Elements** — Grant Input Monitoring permissions in System Settings → Privacy
5. **Hammerspoon** — Grant Accessibility permissions in System Settings → Privacy
6. **AeroSpace** — Grant Accessibility permissions
7. **Raycast** — Import settings backup, set as Spotlight replacement (disable Spotlight shortcut in System Settings → Keyboard → Shortcuts)
8. **Cloudflare WARP** — Sign in to corporate Zero Trust
9. **gcloud** — `gcloud auth login` and `gcloud auth application-default login`
10. **Tailscale** — Sign in
11. **Docker/Colima** — `colima start` (LaunchAgent handles auto-start after first run)
12. **tmux** — Launch, press `prefix + I` to install plugins via tpm
13. **Neovim** — Launch, let lazy.nvim install plugins automatically
14. **Wispr Flow** — Sign in (no config to migrate)
15. **Slack** — Sign in to workspaces
16. **Todoist** — Sign in
17. **Linear** — Sign in
18. **Notion** — Sign in
19. **Spotify** — Sign in
20. **WhatsApp** — Link device via QR code

### Phase 7: macOS System Settings (manual)

- **Keyboard** → Key repeat rate: fast, Delay: short
- **Trackpad** → Tap to click, tracking speed
- **Dock** → Auto-hide, reduce size
- **Mission Control** → Disable "Automatically rearrange Spaces"
- **Sound** → Configure Sound Control if using external audio interface
- **Privacy** → Grant permissions as apps request them

---

## Corporate Apps (auto-provisioned by JumpCloud)

These are managed by MDM — do NOT install manually:
- JumpCloud agent
- SentinelOne

---

## Apps NOT in Brewfile (manual install)

- **Amphetamine** — Mac App Store (`mas install 937984704`)
- **Xcode** — Mac App Store if needed (`mas install 497799835`)
- **Intent by Augment** — Download from vendor

---

## Verification Checklist

After setup, verify these work:

- [ ] Shell: `zsh` with starship prompt, atuin history
- [ ] Terminal: Ghostty opens with correct theme/font
- [ ] Editor: `nvim` launches with plugins
- [ ] Git: `git log` shows delta pager, `lazygit` works
- [ ] SSH: `ssh -T git@github.com` authenticates via 1Password agent
- [ ] Docker: `colima status` shows running, `docker ps` works
- [ ] Kubernetes: `kubectl get nodes` connects to cluster
- [ ] Karabiner: modifier remapping active
- [ ] Hammerspoon: overlay detection working
- [ ] Raycast: hotkey works, extensions loaded
- [ ] Zen: bookmarks, extensions, logins restored
- [ ] Rectangle Pro: window shortcuts working
- [ ] Borders: window borders visible
