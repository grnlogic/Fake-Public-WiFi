#!/bin/bash

# Master script untuk menjalankan semua komponen secara otomatis
# Setiap komponen berjalan di terminal terpisah dengan live log

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

clear

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Master Launcher - Fake Public WiFi Lab        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Script harus dijalankan sebagai root (gunakan sudo)${NC}"
    exit 1
fi

# Cek apakah di X11 environment (GUI)
if [ -z "$DISPLAY" ]; then
    echo -e "${RED}Error: Script ini memerlukan GUI environment${NC}"
    echo -e "${YELLOW}Jalankan dari desktop Kali Linux, bukan SSH${NC}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${YELLOW}[0/5] Auto-detecting wireless interfaces...${NC}"
./auto-detect-interface.sh > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}  ✗ Auto-detection gagal${NC}"
    echo -e "${YELLOW}  Jalankan manual: ./auto-detect-interface.sh${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ Interface configured${NC}"
sleep 1

echo -e "${YELLOW}[1/5] Memulai Access Point...${NC}"

# Terminal 1: Start AP
xterm -T "Access Point - Fake_Public_WiFi" -geometry 100x20+0+0 -hold -e "
    echo -e '\033[0;32m╔════════════════════════════════════════════════════╗\033[0m'
    echo -e '\033[0;32m║          Terminal 1: Access Point Status          ║\033[0m'
    echo -e '\033[0;32m╚════════════════════════════════════════════════════╝\033[0m'
    echo ''
    sudo ./start-ap.sh
    echo ''
    echo -e '\033[0;33m[INFO] Access Point berjalan. Jangan tutup terminal ini!\033[0m'
    echo -e '\033[0;33m[INFO] Untuk stop: sudo ./stop-ap.sh\033[0m'
    bash
" &
AP_TERM_PID=$!

echo -e "${GREEN}  ✓ Terminal AP dibuka (PID: $AP_TERM_PID)${NC}"
sleep 3

# Tunggu AP siap
echo -e "${YELLOW}  Menunggu AP siap...${NC}"
for i in {1..10}; do
    if pgrep hostapd > /dev/null; then
        echo -e "${GREEN}  ✓ AP aktif!${NC}"
        break
    fi
    sleep 1
done

if ! pgrep hostapd > /dev/null; then
    echo -e "${RED}  ✗ AP gagal start${NC}"
    exit 1
fi

sleep 2

echo -e "${YELLOW}[2/5] Auto-detect Wi-Fi credentials...${NC}"

# Cek apakah perlu auto-detect
CURRENT_SSID=$(grep "^WIFI_SSID=" connect-internet.sh | cut -d'"' -f2)
ACTIVE_SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d':' -f2)

if [ "$CURRENT_SSID" != "$ACTIVE_SSID" ] && [ ! -z "$ACTIVE_SSID" ]; then
    echo -e "${YELLOW}  SSID berubah: $CURRENT_SSID → $ACTIVE_SSID${NC}"
    echo -e "${YELLOW}  Menjalankan auto-detect...${NC}"
    sudo ./auto-detect-wifi.sh > /dev/null 2>&1
    echo -e "${GREEN}  ✓ Credentials updated${NC}"
else
    echo -e "${GREEN}  ✓ SSID masih sama: $CURRENT_SSID${NC}"
fi

sleep 2

echo -e "${YELLOW}[3/5] Menghubungkan ke internet...${NC}"

# Terminal 2: Connect Internet
xterm -T "Internet Connection" -geometry 100x20+0+300 -hold -e "
    echo -e '\033[0;32m╔════════════════════════════════════════════════════╗\033[0m'
    echo -e '\033[0;32m║       Terminal 2: Internet Connection Status       ║\033[0m'
    echo -e '\033[0;32m╚════════════════════════════════════════════════════╝\033[0m'
    echo ''
    sudo ./connect-internet.sh
    echo ''
    echo -e '\033[0;33m[INFO] Internet connection established\033[0m'
    echo -e '\033[0;33m[INFO] Monitoring koneksi... (jangan tutup terminal ini)\033[0m'
    echo ''
    while true; do
        if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
            echo -ne '\r\033[0;32m✓ Internet: ONLINE\033[0m  '
        else
            echo -ne '\r\033[0;31m✗ Internet: OFFLINE\033[0m '
        fi
        sleep 5
    done
" &
INET_TERM_PID=$!

echo -e "${GREEN}  ✓ Terminal Internet dibuka (PID: $INET_TERM_PID)${NC}"
sleep 8

# Verifikasi internet
if ping -c 2 8.8.8.8 > /dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Internet tersedia!${NC}"
else
    echo -e "${YELLOW}  ⚠ Internet belum tersedia, tapi melanjutkan...${NC}"
fi

sleep 2

echo -e "${YELLOW}[4/5] Memulai traffic monitoring...${NC}"

# Terminal 3: Traffic Monitor
xterm -T "Traffic Monitoring - Live" -geometry 120x30+600+0 -hold -e "
    echo -e '\033[0;35m╔════════════════════════════════════════════════════╗\033[0m'
    echo -e '\033[0;35m║         Terminal 3: Live Traffic Monitor          ║\033[0m'
    echo -e '\033[0;35m╚════════════════════════════════════════════════════╝\033[0m'
    echo ''
    echo -e '\033[0;33mMonitoring akan dimulai dalam 3 detik...\033[0m'
    echo -e '\033[0;33mSiapkan device client untuk browsing!\033[0m'
    echo ''
    sleep 3
    sudo ./monitor-traffic.sh
    echo ''
    echo -e '\033[0;32m✓ Monitoring selesai\033[0m'
    echo -e '\033[0;33mTekan Enter untuk menutup terminal ini...\033[0m'
    read
" &
MON_TERM_PID=$!

echo -e "${GREEN}  ✓ Terminal Monitoring dibuka (PID: $MON_TERM_PID)${NC}"
sleep 2

echo -e "${YELLOW}[5/5] Membuka status dashboard...${NC}"

# Terminal 4: Status Dashboard
xterm -T "Status Dashboard" -geometry 100x15+600+600 -hold -e "
    echo -e '\033[0;36m╔════════════════════════════════════════════════════╗\033[0m'
    echo -e '\033[0;36m║            Terminal 4: Status Dashboard            ║\033[0m'
    echo -e '\033[0;36m╚════════════════════════════════════════════════════╝\033[0m'
    echo ''
    
    while true; do
        clear
        echo -e '\033[0;36m╔════════════════════════════════════════════════════╗\033[0m'
        echo -e '\033[0;36m║            Terminal 4: Status Dashboard            ║\033[0m'
        echo -e '\033[0;36m╚════════════════════════════════════════════════════╝\033[0m'
        echo ''
        
        # AP Status
        if pgrep hostapd > /dev/null; then
            echo -e '\033[0;32m✓ Access Point: RUNNING\033[0m'
            echo -e '  SSID: Fake_Public_WiFi'
            echo -e '  IP: 10.0.0.1'
        else
            echo -e '\033[0;31m✗ Access Point: STOPPED\033[0m'
        fi
        
        echo ''
        
        # Internet Status
        if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
            WLAN0_IP=\$(ip addr show wlan0 | grep 'inet ' | awk '{print \$2}')
            echo -e '\033[0;32m✓ Internet: ONLINE\033[0m'
            echo -e \"  wlan0: \$WLAN0_IP\"
        else
            echo -e '\033[0;31m✗ Internet: OFFLINE\033[0m'
        fi
        
        echo ''
        
        # Connected Clients
        if [ -f /var/lib/dnsmasq/dnsmasq.leases ]; then
            CLIENT_COUNT=\$(wc -l < /var/lib/dnsmasq/dnsmasq.leases)
            if [ \$CLIENT_COUNT -gt 0 ]; then
                echo -e \"\033[0;32m✓ Clients Connected: \$CLIENT_COUNT\033[0m\"
                cat /var/lib/dnsmasq/dnsmasq.leases | while read line; do
                    IP=\$(echo \$line | awk '{print \$3}')
                    MAC=\$(echo \$line | awk '{print \$2}')
                    echo -e \"  • \$IP (MAC: \$MAC)\"
                done
            else
                echo -e '\033[0;33m⚠ Clients Connected: 0\033[0m'
            fi
        else
            echo -e '\033[0;33m⚠ Clients Connected: 0\033[0m'
        fi
        
        echo ''
        echo -e '\033[0;33m────────────────────────────────────────────────────\033[0m'
        echo -e '\033[0;33mUpdate setiap 5 detik... (Ctrl+C untuk stop)\033[0m'
        
        sleep 5
    done
" &
DASH_TERM_PID=$!

echo -e "${GREEN}  ✓ Terminal Dashboard dibuka (PID: $DASH_TERM_PID)${NC}"
sleep 1

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ SEMUA KOMPONEN BERJALAN!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Terminal yang dibuka:${NC}"
echo -e "  1. ${GREEN}Access Point${NC} - Status AP"
echo -e "  2. ${GREEN}Internet Connection${NC} - Status koneksi internet"
echo -e "  3. ${MAGENTA}Traffic Monitoring${NC} - Live capture (Ctrl+C untuk stop)"
echo -e "  4. ${BLUE}Status Dashboard${NC} - Overview semua komponen"
echo ""
echo -e "${YELLOW}Untuk menghentikan semua:${NC}"
echo -e "  ${RED}sudo ./stop-ap.sh${NC}"
echo -e "  (atau tutup semua terminal)"
echo ""
echo -e "${GREEN}Setup selesai! Selamat testing! 🎉${NC}"
echo ""

# Trap untuk cleanup
cleanup() {
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Menghentikan semua komponen...${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
    
    # Stop AP
    ./stop-ap.sh > /dev/null 2>&1
    
    # Kill terminals
    if [ -f /tmp/wifi-lab-pids.txt ]; then
        while read pid; do
            kill $pid 2>/dev/null
        done < /tmp/wifi-lab-pids.txt
        rm /tmp/wifi-lab-pids.txt
    fi
    
    # Kill processes
    killall tshark 2>/dev/null
    killall xterm 2>/dev/null
    
    echo -e "${GREEN}✓ Semua komponen dihentikan!${NC}"
    echo ""
}

trap cleanup EXIT

echo -e "${YELLOW}Tekan Enter untuk STOP semua komponen dan keluar...${NC}"
read

cleanup
