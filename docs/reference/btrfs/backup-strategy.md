# BTRFS Backup Strategy with btrbk

## Architecture Overview

The backup system uses multiple independent btrbk configurations, each with its own lockfile and systemd timer. This decoupling prevents a failing backup target from blocking local snapshot cleanup.

**The problem it solves:** btrbk preserves ALL snapshots when ANY backup target is unreachable (safety feature to maintain incremental chains). A single unavailable target can cause unbounded snapshot accumulation on the local filesystem.

**The solution:** Each backup target has its own config, lockfile, and systemd timer. Local snapshots are managed independently.

## Configuration Files

All configs are managed in the dotfiles repo at `etc/btrbk/`.

### btrbk.conf -- Local Snapshots

- **Purpose:** Local snapshot management only, no backup targets
- **Schedule:** Hourly via `btrbk.timer` (first run 10min after boot)
- **Snapshot creation:** `onchange` (only when changes detected)
- **Retention:** 7 days of snapshots
- **Location:** `/mnt/btr_pool/btrbk_snapshots/`
- **Subvolumes:** `@root`, `@home`
- **Lockfile:** `/run/lock/btrbk.lock`

### btrbk-usb.conf -- USB Backup

- **Purpose:** Backup to portable encrypted USB drive
- **Schedule:** Every 4 hours via `btrbk-usb.timer` (first run 15min after boot)
- **Snapshot creation:** `no` (uses existing snapshots from main config)
- **Retention:** 7 days + 4 weekly
- **Target:** `/mnt/usb_backups` (LUKS-encrypted btrfs, mounted via `mnt-usb_backups.mount`)
- **Conditions:** Only runs when on AC power (`ConditionACPower=true`) and USB is mounted (`ConditionPathIsMountPoint=/mnt/usb_backups`)
- **Lockfile:** `/run/lock/btrbk-usb.lock`
- **Pre-run:** Cleans incomplete subvolumes from previous failed attempts
- **Sleep inhibition:** Blocks sleep/lid-switch during backup

### btrbk-ssh.conf -- SSH Remote Backup

- **Purpose:** Network backup to homelab NAS via SSH
- **Schedule:** Every 4 hours via `btrbk-ssh.timer` (first run 20min after boot)
- **Snapshot creation:** `no` (uses existing snapshots from main config)
- **Retention:** 7 days + 4 weekly + 3 monthly
- **Target:** `ssh://px-nas.lan/laptop_backups`
- **Conditions:** Only runs when on AC power and `px-nas.lan` is reachable (ExecCondition ping check)
- **Performance:** 1GB stream buffers on both sender and receiver, no stream/ssh compression (filesystem already uses zstd:1)
- **Lockfile:** `/run/lock/btrbk-ssh.lock`
- **Status:** Timer currently disabled (needs server-side subvolume creation)

### framework-backup.conf -- Framework Laptop Backup to Homelab

- **Purpose:** Full laptop backup to homelab server via SSH
- **Target:** `ssh://kbs.lan/mnt/hdd/framework`
- **Snapshot retention:** 2 days min, 14 days preserved
- **Target retention:** 20 days + 10 weekly + all monthly
- **Subvolumes:** `root`, `home`
- **SSH identity:** `/etc/btrbk/ssh/id_rsa`

### btrbk-pac.conf -- Pacman Hook Snapshots

- **Purpose:** Pre/post package operation snapshots
- **Retention:** 48h snapshots, targets kept 10h/8d/3w/1m
- **Location:** `/mnt/btr_pool/btrbk_snapshots/`
- **Subvolume:** `root` only

## Systemd Units

Located in `etc/systemd/system/`:

| Unit | Schedule | Status |
|------|----------|--------|
| `btrbk.timer` / `btrbk.service` | Hourly (local snapshots) | Enabled |
| `btrbk-usb.timer` / `btrbk-usb.service` | Every 4h (USB backup) | Enabled |
| `btrbk-ssh.timer` / `btrbk-ssh.service` | Every 4h (SSH backup) | Disabled |

Mount units for backup targets:

| Unit | Purpose |
|------|---------|
| `mnt-usb_backups.mount` | Encrypted USB btrfs mount at `/mnt/usb_backups` |
| `mnt-usb_backups.automount` | Automount with 4h idle timeout |
| `mnt-truenas_btrbk.mount` | NFS mount for TrueNAS at `/mnt/truenas_btrbk` |

## Monitoring

The `btrfs-space-monitor` script (`local/bin/btrfs-space-monitor`) runs as a user systemd timer every 30 minutes. It checks `/mnt/btr_pool` unallocated space and sends desktop notifications:

- **Warning:** <50GB unallocated
- **Critical:** <20GB unallocated
- **Metadata pressure:** >99% metadata usage with <100GB unallocated

Units in `config/systemd/user/btrfs-space-monitor.{service,timer}`.

## Common Commands

```bash
# Check timer status
systemctl list-timers | grep btrbk

# Manual snapshot run
sudo btrbk run

# Manual USB backup
sudo btrbk -c /etc/btrbk/btrbk-usb.conf run

# Manual SSH backup
sudo btrbk -c /etc/btrbk/btrbk-ssh.conf run

# Check snapshot list
sudo btrbk list snapshots

# Enable SSH timer when ready
sudo systemctl enable --now btrbk-ssh.timer
```

## Incident: January 2026 Space Exhaustion

### Root Cause Chain

1. USB backup drive filled up (late 2025)
2. btrbk backup to USB failed
3. btrbk preserved all snapshots (safety feature to maintain incremental chain)
4. Manual deletion of old snapshots broke incremental chain
5. btrbk tried full (non-incremental) sends which always failed
6. Snapshots accumulated for ~1 month (296 snapshots)
7. Main filesystem ran out of space

### Fix Applied

1. Separated backup targets into independent configs (the multi-config architecture above)
2. Cleaned up 288 accumulated snapshots
3. Deleted all USB backups to reset incremental chain
4. USB drive showed I/O errors -- needs hardware inspection
5. USB backups subsequently disabled; framework-backup.conf added as replacement remote backup path

### Lessons Learned

- Never couple local snapshot lifecycle to external backup target health
- btrbk's `noauto` option still checks target state; must fully separate configs
- Independent lockfiles prevent one slow/stuck backup from blocking others
