#!/bin/bash

# Script untuk auto-detect interface yang support AP mode
# Akan memilih interface yang tepat untuk AP dan Internet

echo "=== Auto-Detecting WiFi Interfaces ==="

# Cari semua wireless interfaces
WIRELESS_INTERFACES=$(iw dev | grep Interface | awk '{print $2}')

if [ -z "$WIRELESS_INTERFACES" ]; then
    echo "❌ Tidak ada wireless interface ditemukan!"
    exit 1
fi

echo "Wireless interfaces ditemukan:"
echo "$WIRELESS_INTERFACES"
echo ""

# Cek setiap interface untuk AP mode support
AP_INTERFACE=""
CLIENT_INTERFACE=""

for iface in $WIRELESS_INTERFACES; do
    echo "Checking $iface..."
    
    # Dapatkan phy number
    PHY=$(iw dev $iface info | grep wiphy | awk '{print $2}')
    
    # Cek apakah support AP mode
    if iw phy${PHY} info | grep -q "* AP"; then
        echo "  ✓ $iface supports AP mode"
        if [ -z "$AP_INTERFACE" ]; then
            AP_INTERFACE=$iface
        fi
    else
        echo "  ✗ $iface does NOT support AP mode"
    fi
    
    # Simpan sebagai kandidat client interface
    if [ -z "$CLIENT_INTERFACE" ] && [ "$iface" != "$AP_INTERFACE" ]; then
        CLIENT_INTERFACE=$iface
    fi
done

echo ""
echo "=== Detection Results ==="

if [ -z "$AP_INTERFACE" ]; then
    echo "❌ Tidak ada interface yang support AP mode!"
    echo ""
    echo "Solusi:"
    echo "1. Pastikan wireless adapter Anda support AP/Master mode"
    echo "2. Cek dengan: iw list | grep -A 10 'Supported interface modes'"
    exit 1
fi

# Jika hanya ada 1 interface, gunakan untuk AP saja
if [ -z "$CLIENT_INTERFACE" ]; then
    echo "⚠ Hanya 1 wireless interface ditemukan"
    echo "AP Interface: $AP_INTERFACE"
    echo "Internet: Gunakan ethernet atau berbagi dari device lain"
    CLIENT_INTERFACE="eth0"  # Default ke ethernet
else
    echo "✓ 2 wireless interfaces ditemukan"
    echo "AP Interface: $AP_INTERFACE (untuk fake WiFi)"
    echo "Client Interface: $CLIENT_INTERFACE (untuk internet)"
fi

echo ""
echo "=== Updating Configuration Files ==="

# Update hostapd.conf
if [ -f "hostapd.conf" ]; then
    sed -i "s/^interface=.*/interface=$AP_INTERFACE/" hostapd.conf
    echo "✓ hostapd.conf updated: interface=$AP_INTERFACE"
fi

# Update dnsmasq.conf
if [ -f "dnsmasq.conf" ]; then
    sed -i "s/^interface=.*/interface=$AP_INTERFACE/" dnsmasq.conf
    echo "✓ dnsmasq.conf updated: interface=$AP_INTERFACE"
fi

# Update start-ap.sh
if [ -f "start-ap.sh" ]; then
    sed -i "s/^AP_INTERFACE=.*/AP_INTERFACE=\"$AP_INTERFACE\"  # Auto-detected/" start-ap.sh
    sed -i "s/^INTERNET_INTERFACE=.*/INTERNET_INTERFACE=\"$CLIENT_INTERFACE\"  # Auto-detected/" start-ap.sh
    echo "✓ start-ap.sh updated: AP=$AP_INTERFACE, Internet=$CLIENT_INTERFACE"
fi

# Update stop-ap.sh
if [ -f "stop-ap.sh" ]; then
    # Update semua referensi wlan0/wlan1 ke interface yang benar
    sed -i "s/wlan[01]/$AP_INTERFACE/g" stop-ap.sh
    echo "✓ stop-ap.sh updated: interface=$AP_INTERFACE"
fi

# Update atau buat NetworkManager unmanage config
UNMANAGE_CONF="99-unmanage-${AP_INTERFACE}.conf"
cat > "$UNMANAGE_CONF" << EOF
[keyfile]
unmanaged-devices=interface-name:$AP_INTERFACE
EOF
echo "✓ Created $UNMANAGE_CONF"

# Update start-ap.sh untuk menggunakan config file yang benar
if [ -f "start-ap.sh" ]; then
    sed -i "s/99-unmanage-wlan[01].conf/$UNMANAGE_CONF/" start-ap.sh
    echo "✓ start-ap.sh updated to use $UNMANAGE_CONF"
fi

echo ""
echo "=== Configuration Complete ==="
echo ""
echo "Interface yang akan digunakan:"
echo "  AP (Fake WiFi): $AP_INTERFACE"
echo "  Internet: $CLIENT_INTERFACE"
echo ""
echo "Untuk memulai AP, jalankan:"
echo "  sudo ./start-ap.sh"
echo ""
echo "CATATAN: Pastikan $CLIENT_INTERFACE sudah terkoneksi ke internet"
echo "         sebelum menjalankan start-ap.sh"
