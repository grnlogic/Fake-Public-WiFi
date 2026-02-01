#!/bin/bash

# Quick test script untuk verifikasi monitoring berfungsi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Quick Test - Verifikasi Monitoring Setup       ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Check 1: AP Status
echo -e "${YELLOW}[1/5] Cek status Access Point...${NC}"
if pgrep hostapd > /dev/null; then
    echo -e "${GREEN}  ✓ hostapd running${NC}"
else
    echo -e "${RED}  ✗ hostapd NOT running - jalankan: sudo ./start-ap.sh${NC}"
    exit 1
fi

# Check 2: Internet connectivity
echo -e "${YELLOW}[2/5] Cek koneksi internet...${NC}"
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Internet available${NC}"
else
    echo -e "${RED}  ✗ No internet - jalankan: sudo ./connect-internet.sh${NC}"
    exit 1
fi

# Check 3: Connected clients
echo -e "${YELLOW}[3/5] Cek client yang terkoneksi...${NC}"
if [ -f /var/lib/dnsmasq/dnsmasq.leases ]; then
    CLIENT_COUNT=$(wc -l < /var/lib/dnsmasq/dnsmasq.leases)
    if [ $CLIENT_COUNT -gt 0 ]; then
        echo -e "${GREEN}  ✓ $CLIENT_COUNT client(s) connected:${NC}"
        cat /var/lib/dnsmasq/dnsmasq.leases | while read line; do
            IP=$(echo $line | awk '{print $3}')
            MAC=$(echo $line | awk '{print $2}')
            echo -e "    • IP: ${YELLOW}$IP${NC} (MAC: $MAC)"
        done
    else
        echo -e "${YELLOW}  ⚠ No clients connected yet${NC}"
        echo -e "${YELLOW}    Connect device lain ke 'Fake_Public_WiFi' dulu${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠ No lease file found${NC}"
fi

# Check 4: Interface monitoring capability
echo -e "${YELLOW}[4/5] Cek interface wlan1...${NC}"
if ip link show wlan1 | grep -q "UP"; then
    echo -e "${GREEN}  ✓ wlan1 is UP${NC}"
    WLAN1_IP=$(ip addr show wlan1 | grep "inet " | awk '{print $2}')
    echo -e "    IP: ${YELLOW}$WLAN1_IP${NC}"
else
    echo -e "${RED}  ✗ wlan1 is DOWN${NC}"
    exit 1
fi

# Check 5: tshark availability
echo -e "${YELLOW}[5/5] Cek tshark...${NC}"
if command -v tshark > /dev/null; then
    echo -e "${GREEN}  ✓ tshark installed${NC}"
else
    echo -e "${RED}  ✗ tshark NOT installed${NC}"
    echo -e "${YELLOW}    Install: sudo apt install tshark -y${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Setup OK! Siap untuk monitoring${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Test recommendations
echo -e "${YELLOW}LANGKAH TESTING:${NC}"
echo ""
echo -e "${BLUE}1. Pastikan device LAIN (bukan laptop Kali ini) sudah connect ke 'Fake_Public_WiFi'${NC}"
echo ""
echo -e "${BLUE}2. Jalankan monitoring:${NC}"
echo -e "   ${GREEN}sudo ./monitor-traffic.sh${NC}"
echo ""
echo -e "${BLUE}3. Dari device yang terkoneksi, buka website HTTP (BUKAN HTTPS):${NC}"
echo -e "   • ${YELLOW}http://neverssl.com${NC} (website khusus HTTP)"
echo -e "   • ${YELLOW}http://example.com${NC}"
echo -e "   • ${YELLOW}http://testphp.vulnweb.com${NC} (untuk test login)"
echo ""
echo -e "${BLUE}4. Untuk test login HTTP:${NC}"
echo -e "   • Buka: ${YELLOW}http://testphp.vulnweb.com/login.php${NC}"
echo -e "   • Username: ${YELLOW}test${NC}"
echo -e "   • Password: ${YELLOW}test${NC}"
echo -e "   • Klik Login"
echo -e "   • ${RED}Password akan tertangkap!${NC}"
echo ""
echo -e "${BLUE}5. Lihat output monitoring - akan muncul:${NC}"
echo -e "   ${GREEN}[DNS]${NC} Query ke domain"
echo -e "   ${GREEN}[HTTP GET]${NC} Request ke website"
echo -e "   ${RED}[HTTP POST]${NC} ⚠ POSSIBLE CREDENTIALS!"
echo ""
echo -e "${YELLOW}CATATAN PENTING:${NC}"
echo -e "  • Website ${RED}HTTPS${NC} (ada gembok 🔒) = Password ${GREEN}AMAN${NC} (terenkripsi)"
echo -e "  • Website ${RED}HTTP${NC} (tidak ada gembok) = Password ${RED}TERLIHAT${NC} (plaintext)"
echo ""
