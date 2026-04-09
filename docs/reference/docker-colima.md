# Docker on macOS via Colima

CLI-only Docker setup using Colima (no Docker Desktop).

## Architecture

```
docker CLI → DOCKER_HOST (unix socket) → Colima VM (Linux/vz) → Docker daemon
```

Colima runs a lightweight Linux VM using Apple's Virtualization Framework (`vmType: vz`).
The Docker CLI is a separate brew package — it's just a client with no daemon.

## Installed packages

```bash
brew install colima docker docker-compose docker-buildx
```

## XDG layout

| Path | Purpose |
|------|---------|
| `~/.config/docker/config.json` | Docker client config (managed by dotter) |
| `~/.config/colima/` | Colima runtime data, VM state |
| `~/.config/colima/default/colima.yaml` | VM config (symlinked from dotfiles) |
| `~/Library/LaunchAgents/com.user.colima.plist` | Autostart agent (deployed by dotter) |

`~/.docker` and `~/.colima` are intentionally absent.

## Environment variables

Set in `config/zsh/rc.d/062-dev.zsh`:

```zsh
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
[[ -S "$XDG_CONFIG_HOME/colima/default/docker.sock" ]] && export DOCKER_HOST="unix://$XDG_CONFIG_HOME/colima/default/docker.sock"
```

`DOCKER_HOST` bypasses Docker's context system entirely — no `~/.docker/contexts/` needed.
The socket check makes the config safe on Linux where Docker runs natively.

## Autostart

Uses a custom LaunchAgent (`com.user.colima.plist`) instead of `brew services`.
The plist explicitly sets `COLIMA_HOME` so launchd's isolated environment finds the XDG config.

**Why not `brew services start colima`?**
Brew's generated plist only inherits `PATH` — it doesn't know about `XDG_CONFIG_HOME`.
Without `COLIMA_HOME`, Colima falls back to `~/.colima` on every boot.

To manage manually:
```bash
launchctl unload ~/Library/LaunchAgents/com.user.colima.plist
launchctl load -w ~/Library/LaunchAgents/com.user.colima.plist
```

## VM config highlights (`colima.yaml`)

- `vmType: vz` — Apple Virtualization Framework (faster than QEMU)
- `arch: aarch64` — native ARM64
- `mountType: virtiofs` — fastest volume mount for vz
- `autoActivate: false` — disabled; we use `DOCKER_HOST` directly
- `sshConfig: true` — Colima manages `~/.config/colima/ssh_config`; our SSH template includes it

## Troubleshooting

**`docker: Cannot connect to the Docker daemon`**
Colima may not be running yet (takes ~10s after login).
```bash
colima status
```

**Colima shows "Broken" after macOS update**
```bash
colima stop --force && colima start
```

**`~/.colima` reappears**
The LaunchAgent plist may have been overwritten (e.g. by `brew services start colima`).
Re-deploy with dotter and reload:
```bash
dotter && launchctl unload ~/Library/LaunchAgents/com.user.colima.plist && launchctl load -w ~/Library/LaunchAgents/com.user.colima.plist
```
