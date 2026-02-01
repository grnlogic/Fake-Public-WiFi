#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Menghentikan Access Point ===${NC}"

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Script harus dijalankan sebagai root (gunakan sudo)${NC}"
    exit 1
fi

# Stop services
killall hostapd 2>/dev/null
killall dnsmasq 2>/dev/null

# Flush iptables
iptables -t nat -F
iptables -F

# Disable IP forwarding
echo 0 > /proc/sys/net/ipv4/ip_forward

# Reset wlan1 ke mode managed
ip link set wlan1 down
ip addr flush dev wlan1
ip link set wlan1 up

# Remove NetworkManager unmanage config
rm -f /etc/NetworkManager/conf.d/99-unmanage-wlan1.conf

# Restore wlan1 to NetworkManager management
nmcli device set wlan1 managed yes 2>/dev/null

# Restart NetworkManager
systemctl restart NetworkManager

echo -e "${GREEN}✓ Access Point dihentikan${NC}"
echo -e "${GREEN}✓ NetworkManager direstart${NC}"
echo -e "${GREEN}✓ wlan1 dikembalikan ke NetworkManager${NC}"
