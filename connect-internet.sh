#!/bin/bash

# Script untuk koneksi wlan0 ke router TP-Link
# Jalankan SETELAH start-ap.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Menghubungkan wlan0 ke Internet ===${NC}"

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Script harus dijalankan sebagai root (gunakan sudo)${NC}"
    exit 1
fi

# Ganti dengan SSID dan password TP-Link Anda
WIFI_SSID="PADUDJAYA"
WIFI_PASSWORD="teuayasinyal"

echo -e "${YELLOW}[1/4] Mengaktifkan wlan0...${NC}"
ip link set wlan0 up
sleep 1

# Buat file konfigurasi wpa_supplicant
echo -e "${YELLOW}[2/4] Membuat konfigurasi koneksi...${NC}"

if [ -z "$WIFI_PASSWORD" ]; then
    # Open network (tanpa password)
    cat > /tmp/wpa_supplicant_wlan0.conf << EOF
network={
    ssid="$WIFI_SSID"
    key_mgmt=NONE
}
EOF
else
    # WPA/WPA2 network (dengan password)
    wpa_passphrase "$WIFI_SSID" "$WIFI_PASSWORD" > /tmp/wpa_supplicant_wlan0.conf
fi

# Koneksi menggunakan wpa_supplicant
echo -e "${YELLOW}[3/4] Menghubungkan ke $WIFI_SSID...${NC}"
killall wpa_supplicant 2>/dev/null
wpa_supplicant -B -i wlan0 -c /tmp/wpa_supplicant_wlan0.conf

sleep 3

# Dapatkan IP via DHCP
echo -e "${YELLOW}[4/4] Mendapatkan IP address...${NC}"

# Kill dhcpcd yang mungkin masih jalan
killall dhcpcd 2>/dev/null
sleep 2

# Start dhcpcd untuk wlan0
dhcpcd -4 wlan0 &

# Tunggu sampai dapat IP (max 15 detik)
echo -e "${YELLOW}Menunggu IP address...${NC}"
for i in {1..15}; do
    if ip addr show wlan0 | grep -q "inet "; then
        echo -e "${GREEN}✓ IP address ditemukan!${NC}"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

sleep 2

# Re-apply iptables rules (kadang hilang setelah dhcp)
echo -e "${YELLOW}Mengkonfigurasi ulang iptables NAT...${NC}"
iptables -t nat -F
iptables -F
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i wlan1 -o wlan0 -j ACCEPT
iptables -A FORWARD -i wlan0 -o wlan1 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Verifikasi koneksi
if ip addr show wlan0 | grep -q "inet "; then
    IP_ADDR=$(ip addr show wlan0 | grep "inet " | awk '{print $2}' | head -1)
    echo -e "${GREEN}✓ wlan0 terhubung ke $WIFI_SSID${NC}"
    echo -e "${GREEN}✓ IP Address: $IP_ADDR${NC}"
    
    # Test internet
    if ping -c 2 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Internet tersedia!${NC}"
        echo ""
        echo -e "${GREEN}=== Setup Lengkap ===${NC}"
        echo -e "wlan0: Terhubung ke internet via $WIFI_SSID ($IP_ADDR)"
        echo -e "wlan1: Access Point 'Fake_Public_WiFi' aktif (10.0.0.1)"
        echo ""
        echo -e "${GREEN}✓ Client yang connect ke 'Fake_Public_WiFi' sekarang bisa akses internet!${NC}"
        echo ""
        echo -e "${YELLOW}Untuk monitoring traffic:${NC}"
        echo -e "  sudo wireshark -i wlan1 -k"
    else
        echo -e "${YELLOW}⚠ IP didapat tapi internet belum tersedia${NC}"
        echo -e "${YELLOW}Coba cek koneksi ke router${NC}"
    fi
else
    echo -e "${RED}✗ Gagal mendapatkan IP address${NC}"
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo -e "  1. Cek apakah wlan0 terkoneksi: sudo iw dev wlan0 link"
    echo -e "  2. Cek password di script ini (baris 19-20)"
    echo -e "  3. Jalankan ulang: sudo ./auto-detect-wifi.sh"
fi
