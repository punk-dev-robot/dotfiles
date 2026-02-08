# Framework 13 AMD Network Quick Fix Guide

## Current Setup
- **WiFi Card**: Qualcomm WCN785x (ath12k driver)
- **Current**: NetworkManager with iwd backend
- **Interface**: wlan0

## If Network Dies (No WiFi)

### 1. Quick Fix - Restart Services
```bash
# Current setup
sudo systemctl restart NetworkManager
sudo systemctl restart iwd

# Or if on pure iwd
sudo systemctl restart iwd
sudo systemctl restart systemd-networkd
```

### 2. Check What's Wrong
```bash
# See if WiFi device exists
ip link | grep wlan0

# Check driver loaded
lsmod | grep ath12k

# Check service status
systemctl status NetworkManager
systemctl status iwd
```

### 3. Manual WiFi Connection (iwd)
```bash
# Enter iwd shell
iwctl

# In iwctl:
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "Your-WiFi-Name"
exit
```

### 4. Framework-Specific Issues

#### Driver not loading
```bash
# Reload WiFi driver
sudo modprobe -r ath12k_pci
sudo modprobe ath12k_pci

# Check firmware
ls /lib/firmware/ath12k/
```

#### Power saving issues
```bash
# Disable power save temporarily
sudo iwctl device wlan0 set-property Powered on
sudo iw dev wlan0 set power_save off
```

## Common Error Messages

### "Failed to D-Bus activate wpa_supplicant"
- iwd and wpa_supplicant conflict
- Solution: Use one or the other
```bash
sudo systemctl disable --now wpa_supplicant
sudo systemctl restart iwd
```

### "ACPI BDF EXT: 0"
- Harmless firmware warning
- WiFi still works

### "Operation not possible due to RF-kill"
```bash
# Check rfkill
rfkill list
rfkill unblock wifi
```

## Test Network
```bash
# Quick connectivity test
ping -c 3 1.1.1.1
ping -c 3 google.com

# DNS test
nslookup google.com
```

## Emergency Network via Phone USB
```bash
# Connect phone via USB, enable USB tethering
# Should appear as usb0
ip link
sudo dhclient usb0  # or wait for NetworkManager
```

## Remember
- WiFi passwords stored in:
  - NM: `/etc/NetworkManager/system-connections/`
  - iwd: `/var/lib/iwd/*.psk`
- Logs: `journalctl -u NetworkManager -u iwd -f`