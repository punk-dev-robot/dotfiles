---
title: BTRFS Backup Strategy with btrbk
type: note
permalink: systems/btrfs-backup-strategy-with-btrbk
tags:
- btrbk
- btrfs
- backup
- snapshots
- systemd
---

# BTRFS Backup Strategy with btrbk

## Architecture Overview

The backup system uses three independent btrbk configurations to decouple snapshot management from backup target availability.

### Why Separate Configs?

- [problem] btrbk's safety feature preserves ALL snapshots when ANY backup target fails #root-cause
- [problem] A failing USB drive or unreachable NAS would block local snapshot cleanup #architecture
- [solution] Each backup target has its own config, lockfile, and systemd timer #decoupling

## Configuration Files

All managed via dotfiles repo at `/home/kuba/dotfiles/etc/btrbk/`

### 1. Main Config: btrbk.conf
- [purpose] Local snapshot management only, no backup targets #snapshots
- [schedule] Hourly via btrbk.timer
- [retention] 7 days of snapshots
- [location] Snapshots in `/mnt/btr_pool/btrbk_snapshots/`

### 2. USB Config: btrbk-usb.conf  
- [purpose] Backup to portable USB drive #usb-backup
- [schedule] Every 4 hours via btrbk-usb.timer
- [retention] 7 days + 4 weekly
- [target] `/mnt/usb_backups`
- [condition] Only runs when USB is mounted (ConditionPathIsMountPoint)
- [note] Uses existing snapshots from main config (snapshot_create no)

### 3. SSH Config: btrbk-ssh.conf
- [purpose] Network backup to homelab NAS #network-backup
- [schedule] Every 4 hours via btrbk-ssh.timer (currently DISABLED)
- [retention] 7 days + 4 weekly + 3 monthly
- [target] `ssh://px-nas.lan/laptop_backups`
- [condition] Only runs when px-nas.lan is reachable (ExecCondition ping check)
- [todo] Need to create `/laptop_backups` btrfs subvolume on px-nas.lan

## Systemd Units

Located in `/home/kuba/dotfiles/etc/systemd/system/`

| Unit | Purpose | Status |
|------|---------|--------|
| btrbk.timer | Hourly local snapshots | Enabled |
| btrbk-usb.timer | 4-hourly USB backup | Enabled |
| btrbk-ssh.timer | 4-hourly SSH backup | Disabled (needs server setup) |

## Subvolumes Backed Up

- @root - System root
- @home - User home directory

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
ls /mnt/btr_pool/btrbk_snapshots/

# Enable SSH timer when ready
sudo systemctl enable --now btrbk-ssh.timer
```

## Incident: January 2026 Space Exhaustion

### Root Cause Chain
1. [event] USB backup drive filled up (late 2025) #incident
2. [effect] btrbk backup to USB failed
3. [effect] btrbk preserved all snapshots (safety feature to maintain incremental chain)
4. [event] Manual deletion of old snapshots broke incremental chain
5. [effect] btrbk tried full (non-incremental) sends which always failed
6. [effect] Snapshots accumulated for ~1 month (296 snapshots)
7. [effect] Main filesystem ran out of space

### Fix Applied
1. [fix] Separated backup targets into independent configs #solution
2. [fix] Cleaned up 288 accumulated snapshots
3. [fix] Deleted all USB backups to reset incremental chain
4. [fix] USB drive showed I/O errors - needs hardware inspection

### Lesson Learned
- [insight] Never couple local snapshot lifecycle to external backup target health #architecture
- [insight] btrbk's `noauto` option still checks target state; must fully comment out or use separate config #btrbk
