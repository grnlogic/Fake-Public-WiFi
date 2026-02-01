#!/bin/bash

# Script untuk auto-detect Wi-Fi yang sedang terkoneksi
# dan update connect-internet.sh dengan SSID + password tersebut

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}=== Auto-Detect Wi-Fi Credentials ===${NC}"
echo ""

# Cek apakah dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Script harus dijalankan sebagai root (gunakan sudo)${NC}"
    exit 1
fi

# Cari koneksi Wi-Fi yang aktif
echo -e "${YELLOW}[1/4] Mencari koneksi Wi-Fi aktif...${NC}"

# Cek dengan nmcli (NetworkManager)
ACTIVE_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)

if [ -z "$ACTIVE_SSID" ]; then
    # Fallback: cek dengan iw
    ACTIVE_SSID=$(iw dev wlan0 link 2>/dev/null | grep "SSID:" | awk '{print $2}')
fi

if [ -z "$ACTIVE_SSID" ]; then
    echo -e "${RED}✗ Tidak ada koneksi Wi-Fi aktif ditemukan${NC}"
    echo -e "${YELLOW}Pastikan Anda sudah terkoneksi ke Wi-Fi sebelum menjalankan script ini${NC}"
    exit 1
fi

echo -e "${GREEN}✓ SSID ditemukan: ${ACTIVE_SSID}${NC}"

# Cari file konfigurasi NetworkManager untuk SSID tersebut
echo -e "${YELLOW}[2/4] Mencari password untuk '${ACTIVE_SSID}'...${NC}"

# Lokasi file konfigurasi NetworkManager
NM_CONNECTIONS="/etc/NetworkManager/system-connections/"

# Cari file yang match dengan SSID
CONNECTION_FILE=$(grep -rl "^ssid=${ACTIVE_SSID}$" ${NM_CONNECTIONS} 2>/dev/null | head -1)

if [ -z "$CONNECTION_FILE" ]; then
    echo -e "${YELLOW}⚠ File konfigurasi tidak ditemukan di NetworkManager${NC}"
    echo -e "${YELLOW}Mencoba metode alternatif...${NC}"
    
    # Coba cari dengan nama yang mengandung SSID
    CONNECTION_FILE=$(ls -1 ${NM_CONNECTIONS} | grep -i "${ACTIVE_SSID}" | head -1)
    if [ ! -z "$CONNECTION_FILE" ]; then
        CONNECTION_FILE="${NM_CONNECTIONS}${CONNECTION_FILE}"
    fi
fi

# Extract password dari file konfigurasi
WIFI_PASSWORD=""
if [ ! -z "$CONNECTION_FILE" ] && [ -f "$CONNECTION_FILE" ]; then
    echo -e "${GREEN}✓ File konfigurasi: ${CONNECTION_FILE}${NC}"
    
    # Cek apakah WPA-PSK (password)
    if grep -q "key-mgmt=wpa-psk" "$CONNECTION_FILE" 2>/dev/null; then
        WIFI_PASSWORD=$(grep "^psk=" "$CONNECTION_FILE" | cut -d'=' -f2)
        echo -e "${GREEN}✓ Password ditemukan (WPA/WPA2)${NC}"
    elif grep -q "key-mgmt=none" "$CONNECTION_FILE" 2>/dev/null; then
        echo -e "${GREEN}✓ Open network (tanpa password)${NC}"
        WIFI_PASSWORD=""
    else
        echo -e "${YELLOW}⚠ Tipe keamanan tidak dikenali${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Tidak dapat menemukan password${NC}"
    echo -e "${YELLOW}Asumsi: Open network (tanpa password)${NC}"
    WIFI_PASSWORD=""
fi

# Tampilkan hasil
echo ""
echo -e "${BLUE}=== Credentials Ditemukan ===${NC}"
echo -e "SSID:     ${GREEN}${ACTIVE_SSID}${NC}"
if [ -z "$WIFI_PASSWORD" ]; then
    echo -e "Password: ${GREEN}(Open Network / No Password)${NC}"
else
    # Tampilkan password dengan sensor
    PASS_LENGTH=${#WIFI_PASSWORD}
    MASKED_PASS=$(printf '%*s' "$PASS_LENGTH" | tr ' ' '*')
    echo -e "Password: ${GREEN}${MASKED_PASS}${NC} (${PASS_LENGTH} karakter)"
fi
echo ""

# Update connect-internet.sh
echo -e "${YELLOW}[3/4] Mengupdate connect-internet.sh...${NC}"

SCRIPT_FILE="./connect-internet.sh"

if [ ! -f "$SCRIPT_FILE" ]; then
    echo -e "${RED}✗ File connect-internet.sh tidak ditemukan${NC}"
    exit 1
fi

# Backup file original
cp "$SCRIPT_FILE" "${SCRIPT_FILE}.backup"
echo -e "${GREEN}✓ Backup dibuat: ${SCRIPT_FILE}.backup${NC}"

# Replace SSID dan password
sed -i "s/^WIFI_SSID=.*/WIFI_SSID=\"${ACTIVE_SSID}\"/" "$SCRIPT_FILE"
sed -i "s/^WIFI_PASSWORD=.*/WIFI_PASSWORD=\"${WIFI_PASSWORD}\"/" "$SCRIPT_FILE"

echo -e "${GREEN}✓ File connect-internet.sh berhasil diupdate${NC}"

# Verifikasi
echo -e "${YELLOW}[4/4] Verifikasi update...${NC}"
echo ""
echo -e "${BLUE}Isi connect-internet.sh sekarang:${NC}"
grep -E "^WIFI_SSID=|^WIFI_PASSWORD=" "$SCRIPT_FILE" | while read line; do
    if [[ $line == WIFI_PASSWORD=* ]] && [ ! -z "$WIFI_PASSWORD" ]; then
        # Sensor password di output
        echo -e "  ${GREEN}WIFI_PASSWORD=\"***\"${NC}"
    else
        echo -e "  ${GREEN}${line}${NC}"
    fi
done

echo ""
echo -e "${GREEN}=== Setup Selesai! ===${NC}"
echo ""
echo -e "${YELLOW}Langkah selanjutnya:${NC}"
echo -e "  1. sudo ./start-ap.sh          # Mulai Access Point"
echo -e "  2. sudo ./connect-internet.sh  # Koneksi internet (otomatis ke ${ACTIVE_SSID})"
echo -e "  3. sudo wireshark -i wlan1 -k  # Monitor traffic (opsional)"
echo ""
echo -e "${BLUE}Credentials sudah tersimpan, Anda tidak perlu edit manual lagi!${NC}"
