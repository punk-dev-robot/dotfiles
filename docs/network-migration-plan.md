# Simple Network Migration Plan

## Networks to Re-add
- [ ] wearthefoxhat (home - WiFi 7)
- [ ] Team Trint (office)
- [ ] Phone hotspot (backup)
- [ ] Any other essential networks

## Migration Steps

### 1. Create systemd-networkd configs
```bash
# Create WiFi config
sudo tee /etc/systemd/network/25-wireless.network << 'EOF'
[Match]
Name=wlan0

[Network]
DHCP=yes
IPv6PrivacyExtensions=yes

[DHCP]
RouteMetric=20
UseDNS=yes
EOF

# Create wired config (for dock)
sudo tee /etc/systemd/network/20-wired.network << 'EOF'
[Match]
Name=en*
Name=eth*

[Network]
DHCP=yes

[DHCP]
RouteMetric=10
UseDNS=yes
EOF
```

### 2. Configure iwd
```bash
sudo tee /etc/iwd/main.conf << 'EOF'
[General]
EnableNetworkConfiguration=false
UseDefaultInterface=true

[Network]
NameResolvingService=systemd

[Settings]
AutoConnect=true
EOF
```

### 3. Switch Services
```bash
# Stop NetworkManager
sudo systemctl disable --now NetworkManager

# Enable new stack
sudo systemctl enable --now systemd-networkd
sudo systemctl enable --now systemd-resolved
sudo systemctl restart iwd

# Check status
networkctl status
```

### 4. Connect to WiFi
```bash
# Connect to each network fresh
iwctl

# In iwctl:
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "wearthefoxhat"
# Enter password when prompted
exit
```

### 5. Verify
```bash
# Check connection
ip addr
ping 1.1.1.1
resolvectl status
```

## Rollback if Needed
```bash
sudo systemctl disable --now systemd-networkd
sudo systemctl enable --now NetworkManager
```

## Benefits After Migration
- Faster boot (less services)
- Less memory usage
- Cleaner system
- Better WiFi 7 support (iwd is more modern)