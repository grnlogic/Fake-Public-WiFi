#!/bin/bash

# Demo script untuk menangkap aktivitas browsing
# Jalankan ini, lalu lakukan browsing dari device client

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

clear

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          DEMO: Menangkap Aktivitas Browsing        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Cek client
echo -e "${YELLOW}[INFO] Client yang terkoneksi:${NC}"
if [ -f /var/lib/dnsmasq/dnsmasq.leases ]; then
    cat /var/lib/dnsmasq/dnsmasq.leases | while read line; do
        IP=$(echo $line | awk '{print $3}')
        MAC=$(echo $line | awk '{print $2}')
        echo -e "  ${GREEN}• IP: $IP${NC} (MAC: $MAC)"
    done
else
    echo -e "  ${RED}Tidak ada client${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}INSTRUKSI UNTUK ANDA:${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}1. Dari device yang terkoneksi (smartphone/laptop lain):${NC}"
echo ""
echo -e "${YELLOW}   Test A - Lihat DNS Queries (Browsing History):${NC}"
echo -e "   • Buka browser"
echo -e "   • Ketik: ${MAGENTA}google.com${NC} (Enter)"
echo -e "   • Ketik: ${MAGENTA}facebook.com${NC} (Enter)"
echo -e "   • Ketik: ${MAGENTA}youtube.com${NC} (Enter)"
echo ""
echo -e "${YELLOW}   Test B - Lihat HTTP Traffic:${NC}"
echo -e "   • Ketik: ${MAGENTA}http://neverssl.com${NC} (PENTING: http, bukan https!)"
echo -e "   • Ketik: ${MAGENTA}http://example.com${NC}"
echo ""
echo -e "${YELLOW}   Test C - Tangkap Credentials (HTTP Login):${NC}"
echo -e "   • Ketik: ${MAGENTA}http://testphp.vulnweb.com/login.php${NC}"
echo -e "   • Username: ${MAGENTA}test${NC}"
echo -e "   • Password: ${MAGENTA}test${NC}"
echo -e "   • Klik ${MAGENTA}Login${NC}"
echo -e "   • ${RED}⚠ PASSWORD AKAN TERTANGKAP!${NC}"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}2. Monitoring akan dimulai dalam 5 detik...${NC}"
echo -e "${YELLOW}   Siapkan device Anda sekarang!${NC}"
echo ""

for i in {5..1}; do
    echo -ne "   ${YELLOW}Starting in $i...${NC}\r"
    sleep 1
done

echo ""
echo -e "${GREEN}✓ Monitoring DIMULAI!${NC}"
echo ""
echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}LIVE TRAFFIC (Tekan Ctrl+C untuk stop):${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
echo ""

# Start monitoring
CAPTURE_DIR="./captures"
mkdir -p "$CAPTURE_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CAPTURE_FILE="${CAPTURE_DIR}/demo_${TIMESTAMP}.pcap"

# Start tshark di background
tshark -i wlan1 -w "$CAPTURE_FILE" -q &
TSHARK_PID=$!

# Live display
tshark -i wlan1 -Y "ip.src == 10.0.0.0/24 or ip.dst == 10.0.0.0/24" -T fields \
    -e frame.time -e ip.src -e ip.dst \
    -e http.request.method -e http.host -e http.request.uri \
    -e dns.qry.name \
    2>/dev/null | while IFS=$'\t' read -r timestamp src dst http_method http_host http_uri dns_query; do
    
    # DNS
    if [ ! -z "$dns_query" ]; then
        echo -e "${BLUE}[DNS]${NC} $src → ${YELLOW}$dns_query${NC}"
    fi
    
    # HTTP
    if [ ! -z "$http_method" ]; then
        if [ "$http_method" == "POST" ]; then
            echo -e "${RED}[HTTP POST]${NC} $src → ${YELLOW}$http_host$http_uri${NC} ${RED}⚠ CREDENTIALS!${NC}"
        else
            echo -e "${GREEN}[HTTP $http_method]${NC} $src → ${YELLOW}$http_host$http_uri${NC}"
        fi
    fi
done &
MONITOR_PID=$!

# Cleanup function
cleanup() {
    echo ""
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Menghentikan monitoring...${NC}"
    
    kill $TSHARK_PID 2>/dev/null
    kill $MONITOR_PID 2>/dev/null
    
    sleep 2
    
    echo -e "${GREEN}✓ Capture selesai!${NC}"
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}HASIL CAPTURE:${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
    echo -e "📁 File: ${YELLOW}$CAPTURE_FILE${NC}"
    echo ""
    
    # Quick analysis
    if [ -f "$CAPTURE_FILE" ]; then
        PACKET_COUNT=$(tshark -r "$CAPTURE_FILE" 2>/dev/null | wc -l)
        DNS_COUNT=$(tshark -r "$CAPTURE_FILE" -Y "dns.qry.name" 2>/dev/null | wc -l)
        HTTP_COUNT=$(tshark -r "$CAPTURE_FILE" -Y "http.request" 2>/dev/null | wc -l)
        POST_COUNT=$(tshark -r "$CAPTURE_FILE" -Y "http.request.method == POST" 2>/dev/null | wc -l)
        
        echo -e "${GREEN}STATISTIK:${NC}"
        echo -e "  • Total Packets: ${YELLOW}$PACKET_COUNT${NC}"
        echo -e "  • DNS Queries: ${YELLOW}$DNS_COUNT${NC}"
        echo -e "  • HTTP Requests: ${YELLOW}$HTTP_COUNT${NC}"
        echo -e "  • HTTP POST (Credentials): ${RED}$POST_COUNT${NC}"
        echo ""
        
        if [ $POST_COUNT -gt 0 ]; then
            echo -e "${RED}⚠ CREDENTIALS DETECTED!${NC}"
            echo ""
        fi
        
        echo -e "${YELLOW}Untuk analisis detail:${NC}"
        echo -e "  sudo ./analyze-capture.sh $CAPTURE_FILE"
        echo ""
        echo -e "${YELLOW}Untuk membuka di Wireshark:${NC}"
        echo -e "  wireshark $CAPTURE_FILE"
    fi
    
    echo ""
    exit 0
}

trap cleanup INT

# Wait
wait $MONITOR_PID
