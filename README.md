# 🔬 WiFi Security Lab - Fake Public WiFi Testing Environment

<div align="center">

![Kali Linux](https://img.shields.io/badge/Kali_Linux-557C94?style=for-the-badge&logo=kali-linux&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Security](https://img.shields.io/badge/Security-Research-red?style=for-the-badge)

**⚠️ EDUCATIONAL PURPOSE ONLY ⚠️**

*Framework otomatis untuk membuat Fake Public WiFi Access Point dan monitoring traffic untuk keperluan penelitian keamanan jaringan*

[Features](#-features) • [Requirements](#-requirements) • [Installation](#-installation) • [Usage](#-usage) • [Screenshots](#-screenshots)

</div>

---

## 📋 Daftar Isi

- [Overview](#-overview)
- [Features](#-features)
- [System Requirements](#-system-requirements)
- [Hardware Requirements](#-hardware-requirements)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Usage Guide](#-usage-guide)
- [Scripts Documentation](#-scripts-documentation)
- [Traffic Analysis](#-traffic-analysis)
- [Legal Disclaimer](#-legal-disclaimer)
- [Contributing](#-contributing)
- [Author](#-author)

---

## 🎯 Overview

**WiFi Security Lab** adalah framework otomatis berbasis Bash yang dirancang untuk penelitian keamanan jaringan WiFi. Tools ini memungkinkan Anda untuk:

- 🎪 Membuat **Fake Public WiFi Access Point** secara otomatis
- 📡 Monitoring dan capturing **network traffic** dari client yang terkoneksi
- 🔍 Analisis mendalam terhadap **HTTP, HTTPS, DNS, DHCP** traffic
- 🚨 Deteksi otomatis **credential leaks** dan unencrypted data
- 📊 Generate laporan analisis traffic yang komprehensif

Framework ini cocok untuk:
- Penetration Testing & Red Team Operations
- Security Research & Education
- Network Security Auditing
- Awareness Training tentang bahaya Public WiFi

---

## ✨ Features

### 🚀 Automated Setup
- ✅ **Auto-detection** wireless interface yang support AP mode
- ✅ **Auto-configuration** untuk optimal network setup
- ✅ **Auto-detect** WiFi credentials untuk internet sharing
- ✅ **One-click launch** - Jalankan semua komponen sekaligus

### 🛡️ Access Point Management
- 🎯 Setup **Fake Public WiFi** dengan SSID "Fake_Public_WiFi"
- 🌐 Built-in **DHCP server** (dnsmasq)
- 🔄 **NAT/IP Forwarding** untuk internet sharing
- 📶 Support multiple chipset WiFi adapter

### 📡 Traffic Monitoring
- 🔴 **Live traffic capture** dengan tshark
- 🕵️ Real-time detection untuk:
  - HTTP/HTTPS requests
  - DNS queries
  - DHCP transactions
  - POST requests (possible credentials)
  - Unencrypted data transmission
- 💾 Automatic **PCAP file** generation
- 📋 Comprehensive **analysis reports**

### 📊 Traffic Analysis
- 🔬 Deep packet inspection
- 📈 Protocol hierarchy analysis
- 🔗 URL extraction dan categorization
- 🚨 Credential leak detection
- 📝 Detailed timeline of activities
- 💼 Export to text reports

### 🖥️ Multi-Terminal Interface
- 🪟 Automatic spawn multiple **xterm** windows
- 👁️ Dedicated terminal untuk setiap komponen
- 📺 Real-time status monitoring
- 🎨 Color-coded output untuk readability

---

## 💻 System Requirements

### Operating System
- **Kali Linux** 2023.x atau lebih baru (Recommended)
- Debian-based Linux dengan **X11** GUI environment
- Architecture: **x86_64** atau **ARM64**

### Required Software
```bash
# Core Utilities
- hostapd        # Access Point daemon
- dnsmasq        # DHCP & DNS server
- iptables       # Firewall & NAT
- iw             # Wireless tools
- tshark         # Traffic capture & analysis
- nmcli          # NetworkManager CLI
- xterm          # Terminal emulator

# Optional (untuk analisis lanjutan)
- wireshark      # GUI packet analyzer
- tcpdump        # Alternative packet capture
- aircrack-ng    # WiFi security tools
```

### Installation Command
```bash
sudo apt update
sudo apt install -y hostapd dnsmasq iptables iw tshark \
                    network-manager xterm wireshark tcpdump \
                    aircrack-ng rfkill wireless-tools
```

---

## 🎛️ Hardware Requirements

### ⚠️ WAJIB: WiFi Adapter yang Support AP Mode

Framework ini **MEMBUTUHKAN** WiFi adapter yang support **AP (Access Point) / Master Mode**. Berikut adalah rekomendasi adapter yang **SUDAH TERUJI**:

### ✅ Recommended WiFi Adapters

#### 🏆 Top Tier (Plug & Play di Kali Linux)

| Model | Chipset | AP Mode | Monitor Mode | Price Range | Notes |
|-------|---------|---------|--------------|-------------|-------|
| **TP-Link TL-WN722N v1** | Atheros AR9271 | ✅ | ✅ | $10-15 | **Best Budget Choice** |
| **Alfa AWUS036NHA** | Atheros AR9271 | ✅ | ✅ | $30-40 | Industry Standard |
| **Alfa AWUS036NEH** | Realtek RTL8188EUS | ✅ | ✅ | $35-45 | High Power |
| **Alfa AWUS036ACH** | Realtek RTL8812AU | ✅ | ✅ | $45-60 | Dual Band AC |
| **Panda PAU09** | Ralink RT5572 | ✅ | ✅ | $25-35 | Dual Band |
| **TP-Link TL-WN722N v2/v3** | Realtek RTL8188EUS | ✅ | ✅ | $10-15 | Need Driver Mod |

#### 🥈 Good Alternative Options

| Model | Chipset | AP Mode | Monitor Mode | Notes |
|-------|---------|---------|--------------|-------|
| Alfa AWUS036AC | Realtek RTL8812AU | ✅ | ✅ | Dual Band AC1200 |
| Panda Wireless PAU05 | Ralink RT5370 | ✅ | ✅ | Compact Size |
| TP-Link Archer T2U | MediaTek MT7610U | ✅ | ✅ | AC600 |
| ASUS USB-N14 | Ralink RT5370 | ✅ | ✅ | Good Range |

### 🔴 NOT Recommended (NO AP Mode Support)
- Intel Wireless Cards (built-in laptop)
- Broadcom BCM43xx series
- Realtek RTL8192EU
- Most built-in laptop WiFi cards

### 📌 How to Check Your Adapter

```bash
# Check if your adapter supports AP mode
sudo iw list | grep -A 10 "Supported interface modes"

# You should see "* AP" in the list
```

**Example Output:**
```
Supported interface modes:
    * IBSS
    * managed
    * AP          ← THIS IS WHAT YOU NEED!
    * monitor
    * mesh point
```

### 🛒 Where to Buy
- **AliExpress**: $8-15 (TP-Link TL-WN722N v1)
- **Amazon**: $10-60 (Alfa series)
- **Local Computer Store**: Varies
- **Tokopedia/Shopee** (Indonesia): Rp 100.000 - 800.000

### 💡 Pro Tips
- Untuk dual WiFi setup (recommended), Anda perlu **2 adapter**:
  - **Adapter 1**: Built-in laptop WiFi → Internet connection
  - **Adapter 2**: External USB WiFi → Fake AP
- Pilih adapter dengan **chipset Atheros atau Ralink** untuk compatibilitas terbaik
- Hindari adapter dengan chipset Realtek yang baru (sering ada issue driver)

---

## 📦 Installation

### 1. Clone Repository
```bash
cd ~/Documents
git clone https://github.com/grnlogic/wifi-lab.git
cd wifi-lab
```

### 2. Install Dependencies
```bash
sudo apt update
sudo apt install -y hostapd dnsmasq iptables iw tshark \
                    network-manager xterm wireshark
```

### 3. Make Scripts Executable
```bash
chmod +x *.sh
```

### 4. Auto-Detect Interface
```bash
sudo ./auto-detect-interface.sh
```

Script ini akan:
- Mendeteksi interface yang support AP mode
- Update semua config file otomatis
- Siap untuk dijalankan!

---

## 🚀 Quick Start

### Method 1: Auto Launch (Recommended)
```bash
sudo ./launch-all.sh
```

Script ini akan:
1. ✅ Auto-detect wireless interfaces
2. ✅ Start Access Point "Fake_Public_WiFi"
3. ✅ Auto-detect WiFi credentials untuk internet
4. ✅ Connect internet via wlan0
5. ✅ Start traffic monitoring
6. ✅ Open multiple terminal windows untuk monitoring

### Method 2: Manual Step-by-Step
```bash
# Step 1: Setup interfaces
sudo ./auto-detect-interface.sh

# Step 2: Start Access Point
sudo ./start-ap.sh

# Step 3: Connect to internet
sudo ./auto-detect-wifi.sh
sudo ./connect-internet.sh

# Step 4: Monitor traffic
sudo ./monitor-traffic.sh
```

### Stop All Services
```bash
sudo ./stop-all.sh
```

---

## 📚 Usage Guide

### 🎪 Scenario 1: Basic AP Setup
```bash
# 1. Start AP
sudo ./start-ap.sh

# 2. Connect your phone/laptop to "Fake_Public_WiFi"
# Password: (None - Open Network)

# 3. Monitor traffic
sudo ./monitor-traffic.sh
```

### 🌐 Scenario 2: Internet-Enabled Fake AP
```bash
# 1. Make sure your Kali is connected to internet via wlan0/ethernet
# 2. Run auto-detect
sudo ./auto-detect-wifi.sh

# 3. Launch all components
sudo ./launch-all.sh

# Now clients can access internet through your Fake AP!
```

### 🔍 Scenario 3: Traffic Analysis
```bash
# While monitoring is running, clients connect and browse

# After capturing, analyze the PCAP file:
sudo ./analyze-capture.sh ./captures/traffic_YYYYMMDD_HHMMSS.pcap

# Or analyze Wireshark capture:
sudo ./analyze-capture.sh /tmp/wireshark_wlan1ABC123.pcapng
```

### 📊 Scenario 4: Demo Mode
```bash
# Quick demo capture (30 seconds)
sudo ./demo-capture.sh
```

---

## 📖 Scripts Documentation

### 🎯 Core Scripts

#### `launch-all.sh`
**Master launcher** - Menjalankan semua komponen secara otomatis dalam multiple terminal windows.
```bash
sudo ./launch-all.sh
```
- Auto-detect interfaces
- Start AP
- Auto-detect WiFi credentials
- Connect internet
- Start monitoring
- Open analysis terminal

#### `start-ap.sh`
Setup dan jalankan **Fake Access Point**.
```bash
sudo ./start-ap.sh
```
- SSID: `Fake_Public_WiFi`
- Gateway: `10.0.0.1`
- DHCP Range: `10.0.0.10-100`
- Open network (no password)

#### `stop-ap.sh`
Hentikan Access Point dan restore network settings.
```bash
sudo ./stop-ap.sh
```

#### `connect-internet.sh`
Connect wlan0 ke internet router.
```bash
sudo ./connect-internet.sh
```
- Menggunakan wpa_supplicant
- DHCP via dhcpcd
- Setup NAT untuk internet sharing

### 🔧 Auto-Detection Scripts

#### `auto-detect-interface.sh`
Detect interface yang support AP mode dan update semua config.
```bash
sudo ./auto-detect-interface.sh
```
Output:
- Interface untuk AP
- Interface untuk Internet
- Update hostapd.conf
- Update dnsmasq.conf
- Update all scripts

#### `auto-detect-wifi.sh`
Auto-detect WiFi credentials dari koneksi aktif.
```bash
sudo ./auto-detect-wifi.sh
```
- Detect SSID
- Extract password dari NetworkManager
- Update connect-internet.sh

### 📡 Monitoring Scripts

#### `monitor-traffic.sh`
Live traffic monitoring dengan real-time analysis.
```bash
sudo ./monitor-traffic.sh
```
Features:
- Real-time packet capture
- Live detection: HTTP, DNS, DHCP, POST
- Auto-generate PCAP & analysis file
- Color-coded output

#### `analyze-capture.sh`
Analyze existing PCAP/PCAPNG file.
```bash
sudo ./analyze-capture.sh <file.pcap>
```
Analysis includes:
- Protocol hierarchy
- DNS queries
- HTTP requests
- POST data (credentials)
- TLS/SSL connections
- Timeline of activities

#### `demo-capture.sh`
Quick 30-second capture untuk testing.
```bash
sudo ./demo-capture.sh
```

#### `test-monitoring.sh`
Test monitoring tanpa actual AP (standalone test).
```bash
sudo ./test-monitoring.sh
```

### 🛑 Utility Scripts

#### `stop-all.sh`
Stop semua komponen dan close all terminals.
```bash
sudo ./stop-all.sh
```
- Stop AP
- Kill monitoring processes
- Close xterm windows
- Cleanup PID files

---

## 📊 Traffic Analysis

### Output Files

Semua hasil disimpan di folder `captures/`:

```
captures/
├── traffic_20260131_112409.pcap          # Raw packet capture
├── analysis_20260131_112409.txt          # Analysis report
└── SUMMARY_LATEST_CAPTURE.txt            # Quick summary
```

### Analysis Report Format

```
=================================================================
TRAFFIC ANALYSIS REPORT - Fake_Public_WiFi
=================================================================
Capture Time: Fri Jan 31 11:24:09 WIB 2026
Interface: wlan1
Capture File: traffic_20260131_112409.pcap

=================================================================
LIVE MONITORING RESULTS
=================================================================

[DHCP] Time: 11:24:15 | Client: 10.0.0.50 | Type: DHCP Discover
[DNS] Time: 11:24:20 | Client: 10.0.0.50 | Query: www.google.com
[HTTP GET] Time: 11:24:25 | Client: 10.0.0.50 | URL: http://example.com/
[HTTP POST] Time: 11:24:30 | Client: 10.0.0.50 | URL: http://login.example.com/auth | ⚠ CHECK FOR CREDENTIALS

--- STATISTICS ---
Total Duration: 300 seconds
Total Packets: 1,234
HTTP Requests: 45
DNS Queries: 78
DHCP Transactions: 3
POST Requests: 2 ⚠

--- ACTIVE CLIENTS ---
10.0.0.50 (Samsung Galaxy S21)
10.0.0.51 (iPhone 13)

--- TOP DOMAINS VISITED ---
www.google.com (15x)
www.facebook.com (8x)
api.twitter.com (5x)
```

### What You Can Detect

✅ **HTTP Traffic**
- URLs visited
- Form submissions
- Login attempts (unencrypted)
- API requests

✅ **DNS Queries**
- All domain lookups
- Tracking user browsing pattern
- App connections

✅ **DHCP**
- Device MAC addresses
- Device hostnames
- DHCP fingerprinting

✅ **TLS/SSL**
- Encrypted connections (metadata only)
- Server Name Indication (SNI)
- Certificate details

❌ **Cannot Detect** (Encrypted)
- HTTPS content (encrypted payload)
- VPN traffic content
- Encrypted messaging apps

---

## ⚖️ Legal Disclaimer

### ⚠️ IMPORTANT - READ CAREFULLY

**Proyek ini dibuat KHUSUS untuk:**
- ✅ **Penelitian keamanan** dalam lingkungan controlled/lab
- ✅ **Pendidikan** tentang bahaya public WiFi
- ✅ **Penetration testing** dengan IZIN TERTULIS
- ✅ **Security awareness training**

**DILARANG KERAS untuk:**
- ❌ Menggunakan di jaringan publik tanpa izin
- ❌ Mencuri data atau credentials orang lain
- ❌ Melakukan serangan terhadap target tanpa otorisasi
- ❌ Melanggar privacy dan hukum yang berlaku

### 📜 Legal Notice

```
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
PENULIS TIDAK BERTANGGUNG JAWAB atas penyalahgunaan tools ini.

Penggunaan tools ini adalah TANGGUNG JAWAB PENGGUNA sepenuhnya.
Pastikan Anda memiliki IZIN LEGAL sebelum melakukan testing.

Pelanggaran dapat dikenakan sanksi pidana sesuai:
- UU ITE (Indonesia)
- Computer Fraud and Abuse Act (USA)
- Computer Misuse Act (UK)
- Atau hukum setempat yang berlaku
```

### ✅ Ethical Use Guidelines

1. **Dapatkan izin tertulis** dari pemilik jaringan
2. **Inform** semua peserta dalam security training
3. **Gunakan** hanya dalam environment isolated/lab
4. **Jangan** capture atau store sensitive data
5. **Hapus** semua capture files setelah analisis
6. **Report** vulnerability secara responsible

---

## 🐛 Troubleshooting

### Issue: "No interface support AP mode"
```bash
# Solution: Gunakan WiFi adapter external yang support AP
# Lihat bagian Hardware Requirements
sudo iw list | grep -A 10 "Supported interface modes"
```

### Issue: "hostapd gagal start"
```bash
# Solution 1: Kill conflicting processes
sudo killall wpa_supplicant
sudo systemctl stop NetworkManager

# Solution 2: Check interface not in use
sudo ip link set wlan1 down
sudo ip link set wlan1 up
```

### Issue: "Client tidak dapat internet"
```bash
# Check NAT configuration
sudo iptables -t nat -L -v

# Re-apply iptables rules
sudo iptables -t nat -F
sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sudo iptables -A FORWARD -i wlan1 -o wlan0 -j ACCEPT
```

### Issue: "Permission denied"
```bash
# Make sure running as root
sudo ./script.sh

# Check executable permission
chmod +x *.sh
```

---

## 🤝 Contributing

Kontribusi sangat diterima! Untuk contribute:

1. Fork repository ini
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

### Areas for Contribution
- 🌐 Web interface untuk monitoring
- 📱 Mobile app untuk remote control
- 🔍 Advanced traffic analysis algorithms
- 🎨 Better UI/UX untuk reports
- 🌍 Multi-language support
- 📚 More documentation & tutorials

---

## 📝 Changelog

### v1.0.0 (2026-01-31)
- ✨ Initial release
- 🎯 Auto-detection features
- 📡 Live traffic monitoring
- 📊 Traffic analysis reports
- 🖥️ Multi-terminal interface
- 🔧 Complete automation scripts

---

## 📄 License

This project is licensed under the **MIT License** - see the LICENSE file for details.

```
MIT License - Copyright (c) 2026 grnlogic

Gunakan dengan bijak dan bertanggung jawab! 🛡️
```

---

## 👨‍💻 Author

**grnlogic**

- GitHub: [@grnlogic](https://github.com/grnlogic)
- Created with ❤️ for security research community

---

## 🙏 Acknowledgments

- **Kali Linux Team** - Untuk distro security terbaik
- **Wireshark/tshark** - Amazing packet analysis tools
- **hostapd** - Robust AP daemon
- **Security Research Community** - Inspirasi dan knowledge sharing

---

## 📚 Resources & References

- [Kali Linux Documentation](https://www.kali.org/docs/)
- [Wireless Hacking 101](https://www.aircrack-ng.org/)
- [Wireshark User Guide](https://www.wireshark.org/docs/)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

---

<div align="center">

### ⚡ Stay Curious, Stay Secure! ⚡

**Made with** 💀 **in Kali Linux**

[![GitHub](https://img.shields.io/badge/GitHub-grnlogic-black?style=for-the-badge&logo=github)](https://github.com/grnlogic)

---

**⭐ Star this repo jika bermanfaat! | 🔗 Share untuk edukasi security awareness**

</div>
