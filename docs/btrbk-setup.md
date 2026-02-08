# Btrbk Backup System Setup

## Overview

This setup provides automated incremental backups with intelligent retention:
- Local snapshots: 7 days (minimal for laptop space)
- Remote backups: 7 daily + 4 weekly + 12 monthly + all yearly
- Automatic NFS detection for fast home network backups
- Falls back to SSH when away from home
- Prevents accidental writes to local filesystem

## Configuration Files

1. `/etc/btrbk/btrbk.conf` - Main configuration
2. `/home/kuba/.local/bin/btrbk-run` - Intelligent wrapper script
3. Systemd timer/service for automation

## Installation

```bash
# Copy configuration
sudo cp /home/kuba/dotfiles/etc/btrbk/btrbk.conf /etc/btrbk/btrbk.conf

# Ensure SSH key exists
sudo ls -la /etc/btrbk/ssh/id_rsa

# Install systemd units
sudo cp /home/kuba/dotfiles/systemd/system/btrbk.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable btrbk.timer
```

## Testing

### 1. Test Configuration
```bash
# Check configuration syntax
btrbk -c /etc/btrbk/btrbk.conf -n dryrun

# Show retention schedule
btrbk -c /etc/btrbk/btrbk.conf -S
```

### 2. Test NFS Mount Safety
```bash
# This should detect if NFS is available
/home/kuba/.local/bin/btrbk-run -n dryrun
```

### 3. Run First Backup
```bash
# Create initial full backup
sudo /home/kuba/.local/bin/btrbk-run
```

### 4. Verify Backups
```bash
# List local snapshots
sudo btrbk -c /etc/btrbk/btrbk.conf list snapshots

# List remote backups
sudo btrbk -c /etc/btrbk/btrbk.conf list backups

# Check latest backup
sudo btrbk -c /etc/btrbk/btrbk.conf list latest
```

## How It Works

### Retention Policy: `7d 4w 12m *y`

This creates a sparse incremental chain:
- Base backup (full) created once
- All subsequent backups are incremental
- Btrbk keeps strategic snapshots:
  - Daily for past week
  - Weekly for past month  
  - Monthly for past year
  - Yearly forever

### Recovery Example

To recover from 6 months ago:
1. Base → Month1 → Month2 → ... → Month6
2. Only ~6 snapshots in the chain (not 180!)

### Space Usage

- Each incremental only stores changes
- Btrfs deduplication reduces storage further
- Typical growth: ~1-5GB per daily backup

## Monitoring

Check backup status:
```bash
# View recent runs
sudo journalctl -u btrbk.service -n 50

# Check timer
systemctl status btrbk.timer

# Manual backup
sudo systemctl start btrbk.service
```

## Troubleshooting

### NFS Mount Issues
```bash
# Check if on home network
ping -c 1 truenas.lan

# Test NFS mount manually
sudo mount -t nfs truenas.lan:/mnt/storage/backups/desktop-archives/kuba-laptop/btrbk /mnt/truenas_btrbk

# Check mount
mount | grep truenas
```

### SSH Connection Issues
```bash
# Test SSH connection
sudo -u root ssh -i /etc/btrbk/ssh/id_rsa kuba@truenas.lan

# Check SSH config
sudo btrbk -c /etc/btrbk/btrbk.conf -n run
```

## Important Notes

1. **Never** manually create files in `/mnt/truenas_btrbk` when NFS is not mounted
2. The script checks for this condition and will abort if local files exist
3. Backups run daily via systemd timer
4. All backups after the first are incremental (space efficient)