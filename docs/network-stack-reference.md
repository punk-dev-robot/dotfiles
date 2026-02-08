# Network Stack Reference: iwd + systemd-networkd vs NetworkManager

## Quick Comparison

| Feature | NetworkManager | iwd + systemd-networkd |
|---------|---------------|------------------------|
| **Memory** | ~50MB | ~10MB total |
| **Boot time** | Slower | Faster |
| **WiFi connect** | 3-5 seconds | 1-2 seconds |
| **Config style** | GUI/CLI/files | Files only |
| **Dependencies** | Many | Minimal |
| **VPN support** | Built-in | External tools |
| **Captive portals** | Automatic | Manual/iwgtk |

## Service Management

### Current Stack (NetworkManager + iwd backend)
```bash
# Services
systemctl status NetworkManager
systemctl status iwd                # Running as backend
systemctl status systemd-resolved   # DNS

# Restart networking
sudo systemctl restart NetworkManager
```

### New Stack (Pure iwd + systemd-networkd)
```bash
# Services to enable
sudo systemctl enable --now systemd-networkd
sudo systemctl enable --now systemd-resolved
sudo systemctl enable --now iwd

# Services to disable
sudo systemctl disable --now NetworkManager
```

## Configuration Files

### NetworkManager
- `/etc/NetworkManager/NetworkManager.conf` - Main config
- `/etc/NetworkManager/system-connections/` - Saved networks

### iwd + systemd-networkd
- `/etc/iwd/main.conf` - iwd config
- `/var/lib/iwd/` - WiFi network configs (PSK files)
- `/etc/systemd/network/` - Network interfaces config

## CLI Commands Cheatsheet

### NetworkManager (current)
```bash
nmcli dev status                    # Show devices
nmcli dev wifi                      # List WiFi networks  
nmcli dev wifi connect "SSID"       # Connect to WiFi
nmcli con show                      # Show connections
nmcli con up "connection-name"      # Activate connection
nmcli con down "connection-name"    # Deactivate
```

### iwd (future)
```bash
iwctl                               # Interactive mode
iwctl device list                   # List devices
iwctl station wlan0 scan            # Scan networks
iwctl station wlan0 get-networks    # Show networks
iwctl station wlan0 connect "SSID" # Connect
iwctl known-networks list           # Saved networks
iwctl station wlan0 show            # Current status
```

## Basic Configuration Examples

### systemd-networkd for WiFi (DHCP)
`/etc/systemd/network/25-wireless.network`:
```ini
[Match]
Name=wlan0

[Network]
DHCP=yes
DNS=1.1.1.1 8.8.8.8  # Optional fallback

[DHCP]
RouteMetric=20
```

### systemd-networkd for Ethernet (DHCP)
`/etc/systemd/network/20-wired.network`:
```ini
[Match]
Name=en*
Name=eth*

[Network]
DHCP=yes

[DHCP]
RouteMetric=10
```

### iwd main config
`/etc/iwd/main.conf`:
```ini
[General]
EnableNetworkConfiguration=false  # Let systemd-networkd handle it
UseDefaultInterface=true

[Network]
NameResolvingService=systemd

[Scan]
DisablePeriodicScan=true  # Save power
```

## WiFi Network Configuration

### With NetworkManager
- Stores in `/etc/NetworkManager/system-connections/`
- Binary format or keyfile

### With iwd
- Stores in `/var/lib/iwd/SSID.psk`
- Plain text format:
```ini
[Security]
PreSharedKey=your-wifi-password
Passphrase=your-wifi-password
```

## DNS Configuration

### Check current DNS
```bash
resolvectl status
resolvectl query example.com
```

### DNS with systemd-resolved
- Config: `/etc/systemd/resolved.conf`
- Fallback DNS servers
- DNSSEC validation
- DNS-over-TLS support

## Troubleshooting

### No Network After Switch
```bash
# Check services
systemctl status systemd-networkd
systemctl status iwd
systemctl status systemd-resolved

# Restart stack
sudo systemctl restart systemd-networkd
sudo systemctl restart iwd

# Check interfaces
ip link
ip addr

# Force DHCP renewal
sudo networkctl renew wlan0
```

### WiFi Not Connecting
```bash
# Check iwd logs
journalctl -u iwd -f

# Manual connection
iwctl
[iwd]# device list
[iwd]# station wlan0 scan
[iwd]# station wlan0 connect "SSID"

# Check saved networks
ls /var/lib/iwd/
```

### DNS Issues
```bash
# Check DNS status
resolvectl status

# Flush DNS cache
sudo resolvectl flush-caches

# Test DNS
resolvectl query google.com
```

## Migration Checklist

1. **Before switching:**
   - [ ] Note current WiFi passwords
   - [ ] Export VPN configs if any
   - [ ] Check static IP needs

2. **Migration steps:**
   ```bash
   # Install if needed
   sudo pacman -S iwd systemd-resolved
   
   # Stop NetworkManager
   sudo systemctl stop NetworkManager
   
   # Start new stack
   sudo systemctl start systemd-networkd
   sudo systemctl start systemd-resolved
   sudo systemctl start iwd
   
   # Connect to WiFi
   iwctl station wlan0 connect "YourSSID"
   ```

3. **Verify:**
   - [ ] WiFi connected
   - [ ] DNS working
   - [ ] Internet access

## Emergency Rollback
```bash
# If things go wrong
sudo systemctl stop systemd-networkd iwd
sudo systemctl start NetworkManager
```

## Captive Portal Handling
- **NetworkManager**: Automatic detection
- **iwd**: Use `iwgtk` or manual browser

## Tips
- iwd remembers networks automatically
- Use `iwgtk` for GUI if needed
- systemd-networkd handles multiple interfaces well
- Config changes need service restart