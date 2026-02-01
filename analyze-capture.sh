#!/bin/bash

# Script untuk menganalisis file .pcap/.pcapng yang sudah ada
# Berguna untuk analisis file capture dari Wireshark

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    Traffic Analyzer - Analisis File Capture       ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Cek argumen
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Usage: $0 <file.pcap|file.pcapng>${NC}"
    echo ""
    echo -e "${YELLOW}Contoh:${NC}"
    echo -e "  $0 /tmp/wireshark_wlan1ABC123.pcapng"
    echo -e "  $0 ./captures/traffic_20260131_112000.pcap"
    echo ""
    
    # Tampilkan file yang tersedia
    if [ -d "./captures" ]; then
        echo -e "${GREEN}File capture yang tersedia:${NC}"
        ls -lh ./captures/*.pcap* 2>/dev/null | awk '{print "  "$9" ("$5")"}'
    fi
    
    # Cek file temp wireshark
    TEMP_FILES=$(ls -t /tmp/wireshark_wlan1*.pcapng 2>/dev/null | head -5)
    if [ ! -z "$TEMP_FILES" ]; then
        echo ""
        echo -e "${GREEN}File Wireshark temporary (5 terbaru):${NC}"
        ls -lht /tmp/wireshark_wlan1*.pcapng 2>/dev/null | head -5 | awk '{print "  "$9" ("$5") - "$6" "$7" "$8}'
    fi
    
    exit 1
fi

PCAP_FILE="$1"

# Cek apakah file ada
if [ ! -f "$PCAP_FILE" ]; then
    echo -e "${RED}✗ File tidak ditemukan: $PCAP_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Menganalisis file: ${YELLOW}$PCAP_FILE${NC}"
echo ""

# Buat output file
OUTPUT_FILE="${PCAP_FILE%.pcap*}_analysis.txt"

echo -e "${YELLOW}[1/6] Informasi dasar file...${NC}"

# File info
FILE_SIZE=$(ls -lh "$PCAP_FILE" | awk '{print $5}')
PACKET_COUNT=$(tshark -r "$PCAP_FILE" -q -z io,stat,0 2>/dev/null | grep "Interval" -A 1 | tail -1 | awk '{print $2}')

echo -e "  File size: ${GREEN}$FILE_SIZE${NC}"
echo -e "  Total packets: ${GREEN}$PACKET_COUNT${NC}"
echo ""

# Mulai analisis
cat > "$OUTPUT_FILE" << EOF
=================================================================
TRAFFIC ANALYSIS REPORT
=================================================================
File: $PCAP_FILE
Size: $FILE_SIZE
Total Packets: $PACKET_COUNT
Analysis Time: $(date)

=================================================================
EOF

echo -e "${YELLOW}[2/6] Analisis protokol...${NC}"
echo "" >> "$OUTPUT_FILE"
echo "--- PROTOCOL HIERARCHY ---" >> "$OUTPUT_FILE"
tshark -r "$PCAP_FILE" -q -z io,phs 2>/dev/null >> "$OUTPUT_FILE"
echo -e "${GREEN}  ✓ Protocol hierarchy${NC}"

echo -e "${YELLOW}[3/6] Analisis DNS queries...${NC}"
DNS_COUNT=$(tshark -r "$PCAP_FILE" -Y "dns.qry.name" 2>/dev/null | wc -l)
echo "" >> "$OUTPUT_FILE"
echo "--- DNS QUERIES (Total: $DNS_COUNT) ---" >> "$OUTPUT_FILE"
tshark -r "$PCAP_FILE" -Y "dns.qry.name" -T fields \
    -e frame.time -e ip.src -e dns.qry.name 2>/dev/null | \
    awk '{print $1" "$2" | Client: "$3" → "$4}' | sort -u >> "$OUTPUT_FILE"
echo -e "${GREEN}  ✓ DNS queries: $DNS_COUNT${NC}"

echo -e "${YELLOW}[4/6] Analisis HTTP traffic...${NC}"
HTTP_COUNT=$(tshark -r "$PCAP_FILE" -Y "http.request" 2>/dev/null | wc -l)
echo "" >> "$OUTPUT_FILE"
echo "--- HTTP REQUESTS (Total: $HTTP_COUNT) ---" >> "$OUTPUT_FILE"
tshark -r "$PCAP_FILE" -Y "http.request" -T fields \
    -e frame.time -e ip.src -e http.request.method -e http.host -e http.request.uri 2>/dev/null | \
    awk '{print $1" "$2" | Client: "$3" | "$4" http://"$5$6}' >> "$OUTPUT_FILE"
echo -e "${GREEN}  ✓ HTTP requests: $HTTP_COUNT${NC}"

echo -e "${YELLOW}[5/6] Mencari credentials (HTTP POST)...${NC}"
POST_COUNT=$(tshark -r "$PCAP_FILE" -Y "http.request.method == POST" 2>/dev/null | wc -l)
echo "" >> "$OUTPUT_FILE"
echo "--- ⚠ POTENTIAL CREDENTIALS (HTTP POST: $POST_COUNT) ---" >> "$OUTPUT_FILE"

if [ $POST_COUNT -gt 0 ]; then
    tshark -r "$PCAP_FILE" -Y "http.request.method == POST" -T fields \
        -e frame.time -e ip.src -e http.host -e http.request.uri -e http.file_data 2>/dev/null | \
        head -20 >> "$OUTPUT_FILE"
    echo -e "${RED}  ⚠ HTTP POST found: $POST_COUNT (POSSIBLE CREDENTIALS!)${NC}"
else
    echo "  No HTTP POST requests found" >> "$OUTPUT_FILE"
    echo -e "${GREEN}  ✓ No HTTP POST (no credentials captured)${NC}"
fi

echo -e "${YELLOW}[6/6] Analisis client connections...${NC}"
echo "" >> "$OUTPUT_FILE"
echo "--- CLIENT IP ADDRESSES ---" >> "$OUTPUT_FILE"
tshark -r "$PCAP_FILE" -Y "ip.src == 10.0.0.0/24" -T fields -e ip.src 2>/dev/null | \
    sort -u | while read ip; do
    MAC=$(tshark -r "$PCAP_FILE" -Y "ip.src == $ip" -T fields -e eth.src 2>/dev/null | head -1)
    echo "  Client: $ip (MAC: $MAC)" >> "$OUTPUT_FILE"
    echo -e "  ${GREEN}Client: $ip${NC}"
done

# Summary
echo "" >> "$OUTPUT_FILE"
echo "=================================================================" >> "$OUTPUT_FILE"
echo "SUMMARY" >> "$OUTPUT_FILE"
echo "=================================================================" >> "$OUTPUT_FILE"
echo "Total Packets: $PACKET_COUNT" >> "$OUTPUT_FILE"
echo "DNS Queries: $DNS_COUNT" >> "$OUTPUT_FILE"
echo "HTTP Requests: $HTTP_COUNT" >> "$OUTPUT_FILE"
echo "HTTP POST (Credentials): $POST_COUNT" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Security findings
echo "--- SECURITY FINDINGS ---" >> "$OUTPUT_FILE"
if [ $POST_COUNT -gt 0 ]; then
    echo "⚠ HIGH RISK: HTTP POST requests detected - possible credentials transmitted in plaintext" >> "$OUTPUT_FILE"
fi
if [ $HTTP_COUNT -gt 0 ]; then
    echo "⚠ MEDIUM RISK: Unencrypted HTTP traffic detected - data visible to attacker" >> "$OUTPUT_FILE"
fi
if [ $DNS_COUNT -gt 0 ]; then
    echo "⚠ INFO: DNS queries visible - attacker can see browsing history" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "=================================================================" >> "$OUTPUT_FILE"
echo "End of Analysis - $(date)" >> "$OUTPUT_FILE"
echo "=================================================================" >> "$OUTPUT_FILE"

# Display results
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}ANALISIS SELESAI!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}SUMMARY:${NC}"
echo -e "  • Total Packets: ${YELLOW}$PACKET_COUNT${NC}"
echo -e "  • DNS Queries: ${YELLOW}$DNS_COUNT${NC}"
echo -e "  • HTTP Requests: ${YELLOW}$HTTP_COUNT${NC}"
echo -e "  • HTTP POST (Credentials): ${RED}$POST_COUNT${NC}"
echo ""
echo -e "${GREEN}HASIL:${NC}"
echo -e "  📄 Analysis file: ${YELLOW}$OUTPUT_FILE${NC}"
echo ""
echo -e "${YELLOW}Untuk melihat detail:${NC}"
echo -e "  cat $OUTPUT_FILE"
echo ""
echo -e "${YELLOW}Untuk membuka di Wireshark:${NC}"
echo -e "  wireshark $PCAP_FILE"
echo ""

# Security recommendations
if [ $POST_COUNT -gt 0 ] || [ $HTTP_COUNT -gt 0 ]; then
    echo -e "${RED}⚠ SECURITY ALERT:${NC}"
    [ $POST_COUNT -gt 0 ] && echo -e "  ${RED}• Credentials mungkin tertangkap dalam HTTP POST!${NC}"
    [ $HTTP_COUNT -gt 0 ] && echo -e "  ${YELLOW}• Traffic HTTP tidak terenkripsi terdeteksi${NC}"
    echo ""
fi
