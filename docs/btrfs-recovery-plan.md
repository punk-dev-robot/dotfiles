# Btrfs Recovery and Optimization Plan

## Current Status (2025-07-26)
- **Critical Issue**: Metadata at 98% causing severe performance degradation
- **Temporary Fix**: Added USB NVMe (/dev/sda2) to pool for metadata balance
- **Balance Running**: 87 chunks being moved to fast USB device

## Immediate Next Steps

### 1. After Metadata Balance Completes (~30-60 min)
```bash
# Check balance status
sudo btrfs balance status /mnt/btr_pool

# Verify metadata is now distributed
sudo btrfs filesystem df /mnt/btr_pool
```

### 2. Resume Weekly Backup (Fast!)
```bash
# Clean up incomplete backup from NFS
sudo rm -f /mnt/truenas_btrbk/@root-weekly.20250726T1248.btrfs

# Run weekly backup - should be 150+ MB/s now
sudo /home/kuba/.local/bin/btrbk-weekly
```

### 3. After Backup Completes - Permanent Fix
```bash
# Convert metadata from DUP to single (doubles available space)
sudo btrfs balance start -f -mconvert=single /mnt/btr_pool

# This gives us 172GB metadata space instead of 86GB
# Will take several hours but prevents future issues
```

### 4. Remove USB Device
```bash
# After all operations complete
sudo btrfs device remove /dev/sda2 /mnt/btr_pool

# Verify removal
sudo btrfs filesystem show /mnt/btr_pool
```

## Performance Optimizations Completed
- ✅ SSH optimization: Added cipher + compression (25→40 MB/s)
- ✅ NFS setup: Automount with optimal settings (150+ MB/s)
- ✅ Adaptive script: Weekly only runs on home network
- ✅ Buffer increase: 2GB for NFS, 1GB for SSH

## Remaining Tasks

### High Priority
1. **Complete metadata fix** (in progress)
2. **Test daily incremental** with SSH optimizations
3. **Move old backups** from btrbk-framework to new dataset

### Medium Priority
1. **Update btrfsmaintenance** for better metadata management:
   ```bash
   # Add to /etc/default/btrfsmaintenance
   BTRFS_BALANCE_MUSAGE="5 10 20 50"
   BTRFS_BALANCE_PERIOD="weekly"
   ```

2. **Monitor metadata usage** - Add to monitoring script:
   ```bash
   # Alert if metadata > 90%
   metadata_percent=$(sudo btrfs fi df /mnt/btr_pool | grep Metadata | grep -oP '\d+\.\d+(?=%)')
   ```

### Low Priority
1. Fix suspend/resume functionality
2. Document entire setup in comprehensive guide

## Key Learnings
- Metadata fragmentation is the silent killer of btrfs performance
- 98% metadata usage causes exponential slowdown after ~125GB transfers
- USB NVMe makes excellent temporary metadata device
- DUP metadata is overkill with good backups
- NFS is 6x faster than SSH for large transfers

## Emergency Commands
```bash
# If system becomes unresponsive during balance
sudo btrfs balance cancel /mnt/btr_pool

# If USB device disconnects
sudo btrfs device missing /mnt/btr_pool

# Force cleanup if needed
sudo btrfs device delete missing /mnt/btr_pool
```

## Long-term Recommendations
1. Consider recreating filesystem with:
   - Single metadata profile (not DUP)
   - Larger nodesize (32k or 64k)
   - Better initial allocation

2. Regular maintenance schedule:
   - Weekly: Metadata balance with low usage
   - Monthly: Full balance if needed
   - Quarterly: Review and cleanup

3. Monitoring alerts:
   - Metadata > 85% = warning
   - Metadata > 95% = critical
   - Backup speed < 50MB/s = investigate

## Contact & Recovery
All configurations backed up in:
- `/home/kuba/dotfiles/` (via git)
- TrueNAS weekly backups
- This documentation