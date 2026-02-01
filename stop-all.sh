#!/bin/bash

# Script untuk menghentikan semua komponen dan menutup terminal

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Menghentikan Semua Komponen WiFi Lab...${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Script harus dijalankan sebagai root (gunakan sudo)${NC}"
    exit 1
fi

# Stop AP
echo -e "${YELLOW}[1/3] Menghentikan Access Point...${NC}"
./stop-ap.sh > /dev/null 2>&1
echo -e "${GREEN}  ✓ AP stopped${NC}"

# Kill terminal processes
echo -e "${YELLOW}[2/3] Menutup terminal windows...${NC}"
if [ -f /tmp/wifi-lab-pids.txt ]; then
    while read pid; do
        kill $pid 2>/dev/null
    done < /tmp/wifi-lab-pids.txt
    rm /tmp/wifi-lab-pids.txt
    echo -e "${GREEN}  ✓ Terminals closed${NC}"
else
    echo -e "${YELLOW}  ⚠ No PID file found${NC}"
fi

# Kill any remaining processes
echo -e "${YELLOW}[3/3] Cleanup processes...${NC}"
killall tshark 2>/dev/null
killall xterm 2>/dev/null
echo -e "${GREEN}  ✓ Cleanup done${NC}"

echo ""
echo -e "${GREEN}✓ Semua komponen dihentikan!${NC}"
echo ""
