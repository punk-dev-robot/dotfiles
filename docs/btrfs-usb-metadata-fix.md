# URGENT: Correct USB NVMe Metadata Fix

## Problem
Current balance command `-mdevid=1` only moves FROM device 1, not TO device 2!

## Solution - Cancel and Restart

### 1. Cancel Current Balance
```bash
sudo btrfs balance cancel /mnt/btr_pool
```

### 2. Force Metadata to USB via Profile Change
```bash
# Temporarily convert to RAID1 - forces write to both devices
sudo btrfs balance start -f -mconvert=raid1 /mnt/btr_pool
```

### 3. Verify USB is Being Used
```bash
# Check during balance - device 2 should show usage
sudo btrfs filesystem show /mnt/btr_pool
```

### 4. After Balance, Convert to Single on USB
```bash
# This keeps metadata on the least-used device (USB)
sudo btrfs balance start -f -mconvert=single /mnt/btr_pool
```

## Alternative: Direct Soft Profile
```bash
# Force new allocations to prefer device 2
sudo btrfs balance start -msoft,devid=2 /mnt/btr_pool
```

## Monitor Progress
Watch in separate terminal:
```bash
watch -n 5 'sudo btrfs fi show /mnt/btr_pool | grep -E "(devid|used)"'
```

Device 2 (USB) should start showing GBs of usage!