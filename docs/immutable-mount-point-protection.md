---
title: immutable-mount-point-protection
type: documentation
permalink: system/immutable-mount-point-protection
---

# Immutable Mount Point Protection Pattern

## Problem
When mount points fail to mount (network issues, disk not connected, etc.), backup tools or scripts may write to the local filesystem instead, filling up the root partition and creating confusion.

## Solution
Use `chattr +i` to make mount directories immutable when unmounted, preventing any writes.

## Implementation

### 1. Create mount point and indicator file
```bash
sudo mkdir -p /mnt/mountpoint
sudo touch /mnt/mountpoint/NOT_MOUNTED
sudo chattr +i /mnt/mountpoint
```

### 2. When mounting succeeds
- The mount operation temporarily removes the immutable flag
- The mounted filesystem overlays the directory
- The NOT_MOUNTED file disappears (hidden by mount)

### 3. When mount fails
- Directory remains immutable
- Any write attempts fail with "Operation not permitted"
- NOT_MOUNTED file serves as visual indicator

## Current Usage
- `/mnt/usb_backups` - Encrypted backup disk
- `/mnt/truenas_btrbk` - NFS backup mount

## Benefits
- Prevents accidental writes to root filesystem
- Clear visual indicator when browsing unmounted directories
- Works with any mount type (NFS, local disks, etc.)
- No need for complex mount checking in scripts

## Example with systemd
```ini
# /etc/systemd/system/mnt-usb_backups.mount
[Unit]
Description=USB encrypted btrfs backup mount
After=dev-mapper-btrfs_backups.device

[Mount]
What=/dev/mapper/btrfs_backups
Where=/mnt/usb_backups
Type=btrfs
Options=defaults,noatime,compress=zstd:1
```

The immutable protection ensures btrbk and other tools fail safely rather than filling the root partition when mounts are unavailable.