#!/bin/bash

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Memulai Fake Public WiFi Access Point ===${NC}"

# Cek apakah dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Script harus dijalankan sebagai root (gunakan sudo)${NC}"
    exit 1
fi

# Interface untuk AP dan Internet
AP_INTERFACE="wlan1"  # Auto-detected
INTERNET_INTERFACE="wlan0"  # Auto-detected

# Unmanage wlan0 dari NetworkManager
echo -e "${YELLOW}[1/10] Melepas ${AP_INTERFACE} dari NetworkManager...${NC}"
# Copy config file to NetworkManager directory
cp 99-unmanage-wlan1.conf /etc/NetworkManager/conf.d/ 2>/dev/null
systemctl reload NetworkManager 2>/dev/null
sleep 1
nmcli device set ${AP_INTERFACE} managed no 2>/dev/null
nmcli connection down "GERAN 1" 2>/dev/null
sleep 1

# Stop services yang mungkin konflik
echo -e "${YELLOW}[2/10] Menghentikan wpa_supplicant...${NC}"
killall wpa_supplicant 2>/dev/null
sleep 1

# Disconnect dan reset interface
echo -e "${YELLOW}[3/10] Mereset ${AP_INTERFACE}...${NC}"
ip link set ${AP_INTERFACE} down
sleep 1
rfkill unblock wifi
sleep 1

# Flush semua konfigurasi lama
echo -e "${YELLOW}[4/10] Membersihkan konfigurasi lama ${AP_INTERFACE}...${NC}"
ip addr flush dev ${AP_INTERFACE}
sleep 1

# Set IP address untuk AP
echo -e "${YELLOW}[5/10] Mengkonfigurasi IP address ${AP_INTERFACE}...${NC}"
ip addr add 10.0.0.1/24 dev ${AP_INTERFACE}
ip link set ${AP_INTERFACE} up
sleep 1

# Enable IP forwarding
echo -e "${YELLOW}[6/10] Mengaktifkan IP forwarding...${NC}"
echo 1 > /proc/sys/net/ipv4/ip_forward

# Konfigurasi iptables untuk NAT
echo -e "${YELLOW}[7/10] Mengkonfigurasi iptables NAT...${NC}"
iptables -t nat -F
iptables -F
iptables -t nat -A POSTROUTING -o ${INTERNET_INTERFACE} -j MASQUERADE
iptables -A FORWARD -i ${AP_INTERFACE} -o ${INTERNET_INTERFACE} -j ACCEPT
iptables -A FORWARD -i ${INTERNET_INTERFACE} -o ${AP_INTERFACE} -m state --state RELATED,ESTABLISHED -j ACCEPT

# Buat direktori untuk dnsmasq lease file
mkdir -p /var/lib/dnsmasq
touch /var/lib/dnsmasq/dnsmasq.leases

# Start dnsmasq
echo -e "${YELLOW}[8/10] Memulai dnsmasq...${NC}"
killall dnsmasq 2>/dev/null
dnsmasq -C dnsmasq.conf

# Start hostapd
echo -e "${YELLOW}[9/10] Memulai hostapd...${NC}"
killall hostapd 2>/dev/null
sleep 1
hostapd -B hostapd.conf

# Verifikasi
echo -e "${YELLOW}[10/10] Verifikasi status...${NC}"
sleep 2

if pgrep hostapd > /dev/null; then
    echo -e "${GREEN}✓ hostapd berjalan${NC}"
else
    echo -e "${RED}✗ hostapd gagal berjalan${NC}"
fi

if pgrep dnsmasq > /dev/null; then
    echo -e "${GREEN}✓ dnsmasq berjalan${NC}"
else
    echo -e "${RED}✗ dnsmasq gagal berjalan${NC}"
fi

echo ""
echo -e "${GREEN}=== Access Point Aktif ===${NC}"
echo -e "SSID: ${GREEN}Fake_Public_WiFi${NC}"
echo -e "IP Gateway: ${GREEN}10.0.0.1${NC}"
echo -e "DHCP Range: ${GREEN}10.0.0.10 - 10.0.0.100${NC}"
echo ""
echo -e "${YELLOW}Untuk monitoring traffic, jalankan:${NC}"
echo -e "  sudo wireshark -i ${AP_INTERFACE} -k"
echo ""
echo -e "${YELLOW}Untuk menghentikan AP, jalankan:${NC}"
echo -e "  sudo ./stop-ap.sh"
