# Btrfs Configuration and Maintenance

This document describes the Btrfs filesystem setup, optimization, and maintenance procedures for this Arch Linux system.

## Table of Contents

- [Overview](#overview)
- [Current Configuration](#current-configuration)
- [Management Tools](#management-tools)
- [Maintenance Schedule](#maintenance-schedule)
- [Backup System](#backup-system)
- [Troubleshooting](#troubleshooting)
- [Emergency Recovery](#emergency-recovery)

## Overview

The system uses Btrfs with LUKS encryption, optimized for SSD storage with automatic compression and maintenance.

### Key Features
- **Filesystem**: Btrfs on LUKS encrypted NVMe SSD
- **Subvolumes**: `@root` and `@home` 
- **Compression**: zstd level 1 (fast)
- **Snapshots**: Automated via btrbk and pacman hooks
- **Monitoring**: Automated space monitoring with notifications

## Current Configuration

### Mount Options (`/etc/fstab`)
```
rw,noatime,compress=zstd:1,ssd,discard=async,space_cache=v2
```

- `noatime`: Reduces metadata writes, especially beneficial with many snapshots
- `compress=zstd:1`: Fast compression algorithm for better space usage
- `ssd`: Enables SSD optimizations
- `discard=async`: Asynchronous TRIM for better performance
- `space_cache=v2`: Improved free space tracking

### Filesystem Layout
```
/                 -> @root subvolume
/home             -> @home subvolume  
/mnt/btr_pool     -> Btrfs root (subvolid=5) for maintenance access
```

## Management Tools

All tools are available in `~/.local/bin/`:

### Monitoring Tools

#### `btrfs-health-check`
Comprehensive health status report showing:
- Filesystem usage (data and metadata)
- Device error statistics
- Scrub status
- Snapshot count
- Maintenance timer status
- Recommendations based on current state

Usage: `btrfs-health-check`

#### `btrfs-space-monitor`
Automated disk space monitoring service that:
- Checks filesystem usage every 30 minutes
- Sends notifications at 90%, 95%, and 98% thresholds
- Monitors both data and metadata allocation
- Logs events to `/var/log/btrfs-space-monitor.log`

Control: `systemctl --user status btrfs-space-monitor.timer`

#### `btrbk-status`
Shows current backup status including:
- Latest daily and weekly backups
- Next scheduled backup runs
- Timer status

Usage: `btrbk-status`

### Maintenance Tools

#### `btrfs-maintenance-run`
Runs all maintenance tasks in optimal order:
1. Checks for running btrbk processes (won't interfere with backups)
2. Runs scrub (read-only check)
3. Performs TRIM operation
4. Balances metadata if usage >90%
5. Light data balance
6. Updates GRUB snapshot entries

Usage: `sudo btrfs-maintenance-run`

#### `btrbk-optimize`
Performance optimization tool that:
- Analyzes current snapshot count
- Creates optimized SSH configuration
- Provides cleanup scripts for old snapshots
- Shows performance recommendations

Usage: `btrbk-optimize`

#### `btrfs-tools`
Quick reference showing all available tools and their status.

Usage: `btrfs-tools`

## Maintenance Schedule

Automated maintenance is handled by systemd timers:

### btrfsmaintenance (`/etc/default/btrfsmaintenance`)
- **Balance**: Weekly (Fridays)
- **Defrag**: Weekly on `/home`
- **Scrub**: Monthly 
- **TRIM**: Weekly
- **Logging**: systemd journal

Check timers: `systemctl list-timers btrfs-*`

### Space Monitoring
- **Frequency**: Every 30 minutes
- **Thresholds**: 90% (warning), 95% (critical), 98% (emergency)
- **Notifications**: Desktop notifications via notify-send

## Backup System

### btrbk Configuration
Backups are managed by btrbk with two configurations:

#### Daily Incremental (`/etc/btrbk/btrbk-daily.conf`)
- Runs daily at 3 AM
- Incremental backups to NAS
- Retains 7 days locally, 14 days on NAS

#### Weekly Full (`/etc/btrbk/btrbk-weekly.conf`)
- Runs weekly (Sundays at 2 AM)
- Full (non-incremental) backups
- Retains 4 weeks on NAS
- Uses 512MB stream buffer

### Pacman Hook Snapshots
- Location: `/mnt/btr_pool/pac_snapshots/`
- Triggers: Before and after package operations
- Managed by: btrbk_logger
- Auto-cleanup: Keep last 10 snapshots (use `btrbk-optimize` to clean)

### SSH Optimization
Optimized SSH config for btrbk transfers (`/etc/btrbk/ssh/config`):
- Fast ciphers for local network
- Disabled compression (Btrfs already compressed)
- Connection multiplexing for better performance

## Troubleshooting

### High Metadata Usage
If metadata usage exceeds 90%:
```bash
sudo btrfs balance start -musage=50 /
```

### Slow Backup Speeds
Common causes:
1. High metadata usage (check with `btrfs-health-check`)
2. Too many snapshots (clean with `btrbk-optimize`)
3. Filesystem fragmentation

### Check Filesystem Errors
```bash
sudo btrfs device stats /
sudo btrfs scrub status /
```

### Monitor Active Operations
```bash
# Check if maintenance is running
btrfs-tools

# Watch filesystem usage
watch -n 5 'sudo btrfs filesystem usage /'
```

## Emergency Recovery

### Boot from Snapshot
1. Reboot system
2. In GRUB menu, select "Arch Linux snapshots"
3. Choose desired snapshot
4. System will boot read-only from snapshot

### Manual Snapshot Management
```bash
# List all snapshots
sudo btrfs subvolume list /mnt/btr_pool

# Create manual snapshot
sudo btrfs subvolume snapshot /mnt/btr_pool/@root /mnt/btr_pool/manual-root-$(date +%Y%m%d)

# Delete snapshot
sudo btrfs subvolume delete /mnt/btr_pool/snapshot-name
```

### Restore from Backup
If booting from snapshot:
1. Mount writable root: `sudo mount -o subvol=@root /dev/mapper/archlinux /mnt`
2. Restore files as needed
3. Reboot to normal system

## Performance Notes

### What We Avoided
- **Quotas**: Not enabled due to 10-30% performance impact
- **Autodefrag mount option**: Using scheduled defrag instead

### Optimization Tips
1. Keep metadata usage below 85%
2. Limit snapshots to necessary ones
3. Run balance operations during low activity
4. Use `noatime` mount option
5. Enable compression (zstd:1 is fast)

## Related Configuration Files

- `/etc/fstab` - Mount configuration
- `/etc/default/btrfsmaintenance` - Maintenance settings
- `/etc/btrbk/*.conf` - Backup configurations
- `/etc/default/grub-btrfs/config` - Snapshot boot settings
- `~/.config/systemd/user/btrfs-space-monitor.*` - Space monitoring service

## Quick Commands Reference

```bash
# Check health
btrfs-health-check

# Run maintenance (checks for running backups)
sudo btrfs-maintenance-run

# View filesystem usage
sudo btrfs filesystem usage /

# Check device errors  
sudo btrfs device stats /

# Start manual scrub
sudo btrfs scrub start /

# Balance metadata only
sudo btrfs balance start -musage=50 /

# Show all subvolumes
sudo btrfs subvolume list /mnt/btr_pool

# Check compression ratio
sudo compsize /
```