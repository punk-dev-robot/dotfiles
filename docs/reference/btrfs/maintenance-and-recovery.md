# BTRFS Maintenance and Recovery

## Subvolume Layout

The system uses BTRFS on a LUKS-encrypted NVMe SSD with the following subvolume structure:

```
/                 -> @root subvolume
/home             -> @home subvolume
/mnt/btr_pool     -> btrfs root (subvolid=5) for maintenance access
```

Snapshot directory: `/mnt/btr_pool/btrbk_snapshots/`

## Mount Options

Current `/etc/fstab` mount options:

```
rw,noatime,compress=zstd:1,ssd,discard=async,space_cache=v2
```

| Option | Purpose |
|--------|---------|
| `noatime` | Reduces metadata writes, especially with many snapshots |
| `compress=zstd:1` | Fast compression, good space savings |
| `ssd` | Enables SSD-specific optimizations |
| `discard=async` | Asynchronous TRIM for better performance |
| `space_cache=v2` | Improved free space tracking |

### Performance Notes

- **Quotas** are not enabled (10-30% performance impact)
- **Autodefrag** mount option is not used; scheduled defrag preferred
- Keep metadata usage below 85% for optimal performance

## Filesystem Maintenance

### Scrub

Read-only integrity check for all data and metadata:

```bash
# Start scrub
sudo btrfs scrub start /

# Check scrub status
sudo btrfs scrub status /
```

### Balance

Rebalances data/metadata across allocated chunks. Use targeted balance operations rather than full rebalance:

```bash
# Balance metadata only (when usage exceeds 50%)
sudo btrfs balance start -musage=50 /

# Check balance status
sudo btrfs balance status /mnt/btr_pool

# Cancel a running balance
sudo btrfs balance cancel /mnt/btr_pool
```

### General Health Checks

```bash
# View filesystem usage
sudo btrfs filesystem usage /

# Check device errors
sudo btrfs device stats /

# Show all subvolumes
sudo btrfs subvolume list /mnt/btr_pool

# Check compression ratio
sudo compsize /
```

## Space Monitoring

The `btrfs-space-monitor` script runs as a user systemd timer every 30 minutes, checking `/mnt/btr_pool` unallocated space and metadata pressure. See [backup-strategy.md](backup-strategy.md) for threshold details.

Units: `config/systemd/user/btrfs-space-monitor.{service,timer}`

## Mount Units

Systemd mount units for backup targets in `etc/systemd/system/`:

| Unit | Mount Point | Type |
|------|------------|------|
| `mnt-usb_backups.mount` | `/mnt/usb_backups` | Encrypted BTRFS (LUKS) |
| `mnt-usb_backups.automount` | `/mnt/usb_backups` | Automount, 4h idle timeout |
| `mnt-truenas_btrbk.mount` | `/mnt/truenas_btrbk` | NFS v3 to TrueNAS |

## Emergency Recovery

### Boot from Snapshot

1. Reboot system
2. In GRUB menu, select "Arch Linux snapshots"
3. Choose desired snapshot
4. System boots read-only from snapshot

### Manual Snapshot Management

```bash
# List all snapshots
sudo btrfs subvolume list /mnt/btr_pool

# Create manual snapshot
sudo btrfs subvolume snapshot /mnt/btr_pool/@root /mnt/btr_pool/manual-root-$(date +%Y%m%d)

# Delete snapshot
sudo btrfs subvolume delete /mnt/btr_pool/snapshot-name
```

### Restore from Snapshot

If booted from snapshot:

1. Mount writable root: `sudo mount -o subvol=@root /dev/mapper/archlinux /mnt`
2. Restore files as needed
3. Reboot to normal system

## Incident: July 2025 Metadata Crisis

### Situation

Metadata reached 98% causing severe performance degradation. Transfers slowed exponentially after ~125GB. The root cause was metadata DUP profile consuming double the space needed.

### Recovery Steps

1. Added USB NVMe (`/dev/sda2`) to pool as temporary metadata device
2. Ran metadata balance to distribute across both devices:
   ```bash
   sudo btrfs balance start -f -mconvert=raid1 /mnt/btr_pool
   ```
3. After balance, converted metadata to single profile (doubles available space):
   ```bash
   sudo btrfs balance start -f -mconvert=single /mnt/btr_pool
   ```
4. Removed temporary USB device:
   ```bash
   sudo btrfs device remove /dev/sda2 /mnt/btr_pool
   ```

### Emergency Commands

```bash
# If system becomes unresponsive during balance
sudo btrfs balance cancel /mnt/btr_pool

# If temporary USB device disconnects during operation
sudo btrfs device missing /mnt/btr_pool
sudo btrfs device delete missing /mnt/btr_pool
```

### Lessons Learned

- Metadata fragmentation is a silent performance killer on BTRFS
- DUP metadata profile is overkill with good backups; single profile doubles available space
- USB NVMe makes an excellent temporary metadata device for recovery
- NFS is ~6x faster than SSH for large btrfs send/receive transfers
