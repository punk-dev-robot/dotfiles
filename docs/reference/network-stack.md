# Network Stack Reference

## Current Stack: iwd + systemd-networkd

The active network stack uses **iwd** for WiFi management and **systemd-networkd** for network configuration, with **systemd-resolved** for DNS. NetworkManager is disabled.

### Why This Stack

Migrated from NetworkManager for lower memory footprint (~10MB vs ~50MB), faster WiFi connections (1-2s vs 3-5s), and better compatibility with the Qualcomm WCN785x WiFi 7 card in the Framework 13 AMD. The tradeoff is no automatic captive portal handling (use `iwgtk` or a browser manually).

### Services

```bash
# Check status
systemctl status iwd
systemctl status systemd-networkd
systemctl status systemd-resolved

# Restart the stack
sudo systemctl restart iwd
sudo systemctl restart systemd-networkd
```

### Configuration

| File | Purpose |
|------|---------|
| `/etc/iwd/main.conf` | iwd config (delegates network config to systemd-networkd) |
| `/var/lib/iwd/*.psk` | Saved WiFi networks (plain text PSK files) |
| `/etc/systemd/network/25-wireless.network` | WiFi interface (DHCP, route metric) |
| `/etc/systemd/network/20-wired.network` | Ethernet interface (DHCP, lower metric = preferred) |
| `/etc/systemd/resolved.conf` | DNS resolver config |

### Common Commands

```bash
# WiFi management
iwctl device list                    # List WiFi devices
iwctl station wlan0 scan             # Scan for networks
iwctl station wlan0 get-networks     # List available networks
iwctl station wlan0 connect "SSID"   # Connect to a network
iwctl station wlan0 show             # Current connection status
iwctl known-networks list            # Saved networks

# Network status
networkctl status                    # Interface overview
networkctl status wlan0              # WiFi interface details
ip addr                              # IP addresses

# DNS
resolvectl status                    # DNS configuration
resolvectl query example.com         # Test DNS resolution
sudo resolvectl flush-caches         # Flush DNS cache
```

## Framework 13 WiFi Troubleshooting

The Framework 13 AMD uses a Qualcomm WCN785x card with the `ath12k` driver. These are known quirks and fixes.

### WiFi Drops or Disappears

```bash
# 1. Quick fix: restart services
sudo systemctl restart iwd
sudo systemctl restart systemd-networkd

# 2. Check if device exists
ip link | grep wlan0

# 3. If device missing, reload driver
sudo modprobe -r ath12k_pci
sudo modprobe ath12k_pci

# 4. Check firmware is present
ls /lib/firmware/ath12k/
```

### Power Save Issues

```bash
# Disable WiFi power save (temporary, until reboot)
sudo iw dev wlan0 set power_save off

# Check current power save state
iw dev wlan0 get power_save
```

### Common Error Messages

**"Failed to D-Bus activate wpa_supplicant"** -- iwd and wpa_supplicant conflict. Only one should run:
```bash
sudo systemctl disable --now wpa_supplicant
sudo systemctl restart iwd
```

**"ACPI BDF EXT: 0"** -- Harmless firmware warning. WiFi still works.

**"Operation not possible due to RF-kill"** -- Hardware or software radio kill switch:
```bash
rfkill list
rfkill unblock wifi
```

### Emergency: USB Tethering Fallback

```bash
# Connect phone via USB, enable USB tethering on phone
# Interface appears as usb0 or enp*
ip link
sudo networkctl renew usb0
```

## NetworkManager Reference (Inactive)

NetworkManager is **not the active stack** on this system. Kept here as reference for other systems or if rollback is needed.

### Quick Commands

```bash
nmcli dev status                     # Show devices
nmcli dev wifi                       # List WiFi networks
nmcli dev wifi connect "SSID"        # Connect to WiFi
nmcli con show                       # Show saved connections
nmcli con up "connection-name"       # Activate connection
```

### Config Locations

- `/etc/NetworkManager/NetworkManager.conf` -- Main config
- `/etc/NetworkManager/system-connections/` -- Saved networks

### Rollback to NetworkManager

```bash
sudo systemctl disable --now systemd-networkd iwd
sudo systemctl enable --now NetworkManager
```
