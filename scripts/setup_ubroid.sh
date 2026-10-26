#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# UbRoid - Authentic Ubuntu 24.04 LTS Desktop Environment for Android
# Master 1-Click Universal Installer (Phones & Tablets)
# Repository: https://github.com/triwahyu45/UbRoid_TriWahyu45
# Author: Tri Wahyu Handoyo (triwahyu45)
# ==============================================================================

set -e

GREEN='\033[0;32m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Deteksi Perangkat Android (Model / Nama Pasar)
DEV_NAME=$(getprop ro.product.marketname 2>/dev/null)
[ -z "$DEV_NAME" ] && DEV_NAME=$(getprop ro.product.model 2>/dev/null)
[ -z "$DEV_NAME" ] && DEV_NAME="Android Device"

# Deteksi Lingkungan: Apakah dijalankan di Termux atau di dalam PRoot Ubuntu?
IS_TERMUX=false
if [ -d "/data/data/com.termux" ] && [ -x "/data/data/com.termux/files/usr/bin/pkg" ]; then
    IS_TERMUX=true
elif [ -n "$TERMUX_VERSION" ]; then
    IS_TERMUX=true
fi

echo -e "${PURPLE}"
cat << "EOF"
  _   _ _     ____       _     _ 
 | | | | |__ |  _ \ ___ (_) __| |
 | | | | '_ \| |_) / _ \| |/ _` |
 | |_| | |_) |  _ < (_) | | (_| |
  \___/|_.__/|_| \_\___/|_|\__,_|
  ⚡ Ubuntu 24.04 LTS for Android Tablets & Phones
  🚀 Authentic Ubuntu Desktop • 0% Flickering • Dynamic Resolution
EOF
echo -e "${NC}"
echo -e "Perangkat Terdeteksi: ${YELLOW}${DEV_NAME}${NC}\n"

# ------------------------------------------------------------------------------
# KASUS 1: DIJALANKAN DARI DALAM UBUNTU PROOT
# ------------------------------------------------------------------------------
if [ "$IS_TERMUX" = false ]; then
    echo -e "${CYAN}[*] Terdeteksi berjalan di dalam container Ubuntu PRoot.${NC}"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/install.sh" ]; then
        exec bash "$SCRIPT_DIR/install.sh"
    elif [ -f "/root/UbRoid_TriWahyu45/install.sh" ]; then
        exec bash "/root/UbRoid_TriWahyu45/install.sh"
    else
        echo -e "${RED}[!] File install.sh tidak ditemukan!${NC}"
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# KASUS 2: DIJALANKAN DARI TERMUX (MASTER INSTALLER)
# ------------------------------------------------------------------------------
echo -e "${CYAN}[1/7] Menyiapkan environment Termux & dependensi dasar...${NC}"
pkg update -y
pkg install -y proot-distro x11-repo pulseaudio wget git tar bc

# Pastikan permission external app diizinkan untuk launcher APK
mkdir -p "$HOME/.termux"
if [ -f "$HOME/.termux/termux.properties" ]; then
    sed -i '/allow-external-apps/d' "$HOME/.termux/termux.properties"
fi
echo "allow-external-apps = true" >> "$HOME/.termux/termux.properties"
echo -e "${GREEN}✓ Termux properties dikonfigurasi (allow-external-apps = true)${NC}"

# 2. Unduh atau perbarui repository UbRoid
echo -e "${CYAN}[2/7] Mengunduh repository UbRoid...${NC}"
REPO_DIR="$HOME/UbRoid_TriWahyu45"
SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"

if [ -n "$SCRIPT_SOURCE_DIR" ] && [ -f "$SCRIPT_SOURCE_DIR/install.sh" ]; then
    REPO_DIR="$SCRIPT_SOURCE_DIR"
    echo -e "${GREEN}✓ Menggunakan repository dari $REPO_DIR${NC}"
else
    if [ -d "$REPO_DIR/.git" ]; then
        echo "Memperbarui repository yang sudah ada..."
        cd "$REPO_DIR" && git pull || true
    else
        echo "Meng-clone repository UbRoid..."
        git clone https://github.com/triwahyu45/UbRoid_TriWahyu45.git "$REPO_DIR"
    fi
fi

# 3. Memasang container Ubuntu 24.04 LTS (Noble Numbat)
echo -e "${CYAN}[3/7] Menyiapkan rootfs resmi Ubuntu 24.04 LTS (Noble Numbat)...${NC}"
UBUNTU_CONTAINER="ubuntu"

# Periksa apakah sudah ada container ubuntu atau ubuntu:24.04 terpasang
if proot-distro list 2>/dev/null | grep -q "^ubuntu\b.*installed"; then
    UBUNTU_CONTAINER="ubuntu"
    echo -e "${GREEN}✓ Container 'ubuntu' sudah terpasang.${NC}"
elif proot-distro list 2>/dev/null | grep -q "ubuntu:24.04.*installed"; then
    UBUNTU_CONTAINER="ubuntu:24.04"
    echo -e "${GREEN}✓ Container 'ubuntu:24.04' sudah terpasang.${NC}"
else
    echo "Mengunduh & memasang Ubuntu 24.04 LTS via proot-distro..."
    # Gunakan tag versi terkunci 24.04 agar tidak terpasang versi rolling yang tidak stabil
    if proot-distro install ubuntu:24.04 --override-alias ubuntu 2>/dev/null; then
        UBUNTU_CONTAINER="ubuntu"
    elif proot-distro install ubuntu:24.04 2>/dev/null; then
        UBUNTU_CONTAINER="ubuntu:24.04"
    else
        proot-distro install ubuntu
        UBUNTU_CONTAINER="ubuntu"
    fi
    echo -e "${GREEN}✓ Rootfs Ubuntu 24.04 LTS berhasil dipasang.${NC}"
fi

# 4. Konfigurasi Termux ~/.bashrc & Banner DetronicsID
echo -e "${CYAN}[4/7] Memasang Banner DetronicsID & shortcut di Termux...${NC}"
if [ -f "$REPO_DIR/configs/bash/termux_bashrc" ]; then
    cp "$REPO_DIR/configs/bash/termux_bashrc" "$HOME/.bashrc"
    echo -e "${GREEN}✓ DetronicsID welcome banner & shortcut dipasang ke ~/.bashrc Termux.${NC}"
fi

# 5. Pasang script peluncur ~/launch_ubuntu.sh dengan Dynamic Resolution
echo -e "${CYAN}[5/7] Mengonfigurasi script peluncur ~/launch_ubuntu.sh (Dynamic Scaling)...${NC}"
cp "$REPO_DIR/scripts/launch_ubuntu.sh" "$HOME/launch_ubuntu.sh"
chmod +x "$HOME/launch_ubuntu.sh"

# Sesuaikan target container di launch_ubuntu.sh jika berbeda
if [ "$UBUNTU_CONTAINER" != "ubuntu" ]; then
    sed -i "s/UBUNTU_CONTAINER=\"ubuntu\"/UBUNTU_CONTAINER=\"$UBUNTU_CONTAINER\"/g" "$HOME/launch_ubuntu.sh"
fi
echo -e "${GREEN}✓ Script ~/launch_ubuntu.sh siap dengan kalkulasi DPI dinamis.${NC}"

# 6. Jalankan instalasi GUI di dalam Ubuntu PRoot
echo -e "${CYAN}[6/7] Menjalankan instalasi Desktop Environment di dalam Ubuntu PRoot...${NC}"
TMPDIR=/data/data/com.termux/files/usr/tmp
mkdir -p "$TMPDIR/.X11-unix"
cat << "RESOLV" > "$TMPDIR/resolv.conf"
nameserver 1.1.1.1
nameserver 8.8.8.8
RESOLV

proot-distro login "$UBUNTU_CONTAINER" \
  --bind "$TMPDIR/.X11-unix:/tmp/.X11-unix" \
  --bind "$REPO_DIR:/root/UbRoid_TriWahyu45" \
  --bind "$HOME:/root/termux_home" \
  --bind /sdcard:/sdcard \
  --bind /sdcard:/root/Android_Storage \
  --bind "$TMPDIR/resolv.conf:/etc/resolv.conf" \
  -- bash /root/UbRoid_TriWahyu45/install.sh

# 7. Selesai
echo -e "\n${GREEN}==============================================================================${NC}"
echo -e "${GREEN}🎉 INSTALASI UBROID BERHASIL DISELESAIKAN UNTUK ${DEV_NAME}!${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo -e "Langkah Selanjutnya:"
echo -e "1. Install APK pendukung dari folder: ${YELLOW}$REPO_DIR/apks/${NC}"
echo -e "   - ${CYAN}termux-x11.apk${NC} (X11 Display Server)"
echo -e "   - ${CYAN}Ubuntu_Launcher.apk${NC} (Peluncur 1-Tap dari Homescreen Android)"
echo -e "2. Jalankan perintah di Termux: ${YELLOW}ubuntu${NC} (atau klik icon aplikasi Ubuntu di Homescreen Android)"
echo -e "${GREEN}==============================================================================${NC}\n"
