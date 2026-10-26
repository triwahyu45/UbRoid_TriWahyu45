#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# UbRoid - Authentic Ubuntu 24.04 LTS Desktop Environment for Android
# Master 1-Click Universal Installer (Phones & Tablets)
# Repository: https://github.com/triwahyu45/UbRoid_TriWahyu45
# Author: Tri Wahyu Handoyo (triwahyu45 / DetronicsID)
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

# Handler Laporan Error Otomatis ke GitHub Issues
report_install_error() {
    local exit_code=$?
    local line_num=$1
    local cmd="$2"

    echo -e "\n${RED}==============================================================================${NC}"
    echo -e "${RED}❌ TERJADI KESALAHAN PADA INSTALASI UBROID! (Exit Code: $exit_code)${NC}"
    echo -e "${RED}   Gagal di baris: $line_num | Perintah: $cmd${NC}"
    echo -e "${RED}==============================================================================${NC}"

    local dev_name
    dev_name=$(getprop ro.product.marketname 2>/dev/null || getprop ro.product.model 2>/dev/null || echo "Unknown Device")
    local android_ver
    android_ver=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    local arch
    arch=$(uname -m 2>/dev/null || echo "aarch64")

    local issue_title="[Bug Report] Instalasi Gagal di $dev_name ($arch)"
    local issue_body="### 📱 Informasi Perangkat & Sistem
* **Perangkat:** $dev_name
* **Versi Android:** $android_ver
* **Arsitektur CPU:** $arch
* **Gagal di Baris:** $line_num
* **Perintah Gagal:** \`$cmd\`
* **Kode Keluar (Exit Code):** $exit_code

### 📝 Catatan / Gejala Tambahan
Jelaskan gejala yang dialami:
"

    local log_path="$HOME/ubroid_error.log"
    echo -e "Device: $dev_name\nAndroid: $android_ver\nArch: $arch\nLine: $line_num\nCmd: $cmd\nCode: $exit_code" > "$log_path"
    [ -d "/sdcard/Download" ] && cp "$log_path" "/sdcard/Download/ubroid_error.log" 2>/dev/null || true

    echo -e "\n${YELLOW}Laporan error telah disimpan ke: $log_path${NC}"
    echo -e "Membuka formulir pelaporan bug otomatis ke GitHub Issues Tri Wahyu Handoyo..."

    local encoded_url
    encoded_url=$(python3 -c "
import urllib.parse, sys
title = sys.argv[1]
body = sys.argv[2]
url = 'https://github.com/triwahyu45/UbRoid_TriWahyu45/issues/new?title=' + urllib.parse.quote(title) + '&body=' + urllib.parse.quote(body)
print(url)
" "$issue_title" "$issue_body" 2>/dev/null || echo "https://github.com/triwahyu45/UbRoid_TriWahyu45/issues/new")

    echo -e "\n${CYAN}🔗 Tautan Pelaporan Error GitHub (Tinggal Tap 'Submit New Issue'):${NC}"
    echo -e "${YELLOW}$encoded_url${NC}\n"

    /system/bin/am start -a android.intent.action.VIEW -d "$encoded_url" 2>/dev/null || true
    exit $exit_code
}

trap 'report_install_error $LINENO "$BASH_COMMAND"' ERR

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
        exec bash "$SCRIPT_DIR/install.sh" "$@"
    elif [ -f "/root/UbRoid_TriWahyu45/install.sh" ]; then
        exec bash "/root/UbRoid_TriWahyu45/install.sh" "$@"
    else
        echo -e "${RED}[!] File install.sh tidak ditemukan!${NC}"
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# KASUS 2: DIJALANKAN DARI TERMUX (MASTER INSTALLER)
# ------------------------------------------------------------------------------

# Mode Selection: Desktop (Default) vs Ubuntu Touch Mobile (Poco F6)
INSTALL_MODE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            INSTALL_MODE="$2"
            shift 2
            ;;
        --mode=*)
            INSTALL_MODE="${1#*=}"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [ -z "$INSTALL_MODE" ]; then
    echo -e "${PURPLE}==============================================================================${NC}"
    echo -e "${CYAN}📱 PILIH MODE TAMPILAN UBROID (UBUNTU 24.04 LTS)${NC}"
    echo -e "${PURPLE}==============================================================================${NC}"
    echo -e "  ${YELLOW}[1]${NC} 🖥️  \033[1mUbuntu Desktop Edition\033[0m (Default)"
    echo -e "       - Mode Desktop klasik XFCE dengan dock horizontal di bawah."
    echo -e "       - Ideal untuk Tablet, Monitor Eksternal, Keyboard & Mouse fisik.\n"
    echo -e "  ${YELLOW}[2]${NC} 📱 \033[1mUbuntu Touch Mobile Edition\033[0m (Rekomendasi Poco F6 / Layar HP)"
    echo -e "       - Tampilan mobile ala Ubuntu Touch (Lomiri) dengan launcher vertikal di sisi kiri."
    echo -e "       - Tombol & ikon besar ramah sentuhan (touchscreen friendly) & single-tap."
    echo -e "       - Integrasi On-Screen Keyboard (Gboard & Onboard auto-popup di kolom teks)."
    echo -e "       - Dilengkapi Python Mobile Studio (cocok untuk Mini PC & koding di HP)."
    echo -e "${PURPLE}==============================================================================${NC}"

    INSTALL_MODE="desktop"
    echo -e "Pilih mode tampilan dalam 5 detik (Default: [1] Desktop):"
    for ((i=5; i>=1; i--)); do
        echo -ne "\r⏳ Memilih [1] Desktop otomatis dalam \033[1;33m${i}s\033[0m (Tekan \033[1;32m2\033[0m untuk Touch): "
        if read -t 1 -n 1 user_input; then
            echo ""
            if [ "$user_input" = "2" ]; then
                INSTALL_MODE="touch"
                echo -e "${GREEN}✓ Mode Dipilih: Ubuntu Touch Mobile Edition!${NC}\n"
            else
                INSTALL_MODE="desktop"
                echo -e "${CYAN}✓ Mode Dipilih: Ubuntu Desktop Edition!${NC}\n"
            fi
            break
        fi
    done
    if [ -z "$user_input" ]; then
        echo -e "\n${YELLOW}⏱️ Waktu habis. Otomatis memilih mode: Ubuntu Desktop Edition (Default)${NC}\n"
        INSTALL_MODE="desktop"
    fi
fi

if [ "$INSTALL_MODE" != "touch" ]; then
    INSTALL_MODE="desktop"
fi

# 0. Pastikan izin penyimpanan & kebersihan login terminal
if [ ! -d "$HOME/storage" ] && [ ! -d "/sdcard/Download" ]; then
    echo -e "${YELLOW}[!] Meminta izin akses penyimpanan Android (Storage Permission)...${NC}"
    termux-setup-storage 2>/dev/null || true
    sleep 2
fi
touch "$HOME/.hushlogin"

echo -e "${CYAN}[1/7] Menyiapkan environment Termux & dependensi dasar...${NC}"
pkg update -y
pkg install -y proot-distro x11-repo termux-x11-nightly pulseaudio wget git tar bc python

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

# Periksa apakah container ubuntu sudah ada (kompatibel proot-distro v4 & v5)
is_ubuntu_present() {
    proot-distro list --quiet 2>/dev/null | grep -qx "ubuntu" && return 0
    [ -d "/data/data/com.termux/files/usr/var/lib/proot-distro/containers/ubuntu" ] && return 0
    [ -d "$HOME/.local/share/proot-distro/containers/ubuntu" ] && return 0
    [ -d "/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu" ] && return 0
    proot-distro login ubuntu -- /bin/true >/dev/null 2>&1 && return 0
    return 1
}

if is_ubuntu_present; then
    UBUNTU_CONTAINER="ubuntu"
    echo -e "${GREEN}✓ Container 'ubuntu' sudah terpasang.${NC}"
else
    echo "Mengunduh & memasang Ubuntu 24.04 LTS (Noble Numbat) via proot-distro..."
    # Jangan sembunyikan output agar user dapat melihat progress bar resmi
    if ! proot-distro install ubuntu:24.04 --name ubuntu; then
        echo -e "${YELLOW}[*] Mencoba instalasi dengan 'ubuntu:24.04'...${NC}"
        if ! proot-distro install ubuntu:24.04; then
            echo -e "${YELLOW}[*] Mencoba instalasi dengan 'ubuntu'...${NC}"
            if ! proot-distro install ubuntu; then
                echo -e "${RED}[!] Gagal memasang rootfs Ubuntu via proot-distro.${NC}"
                exit 1
            fi
        fi
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

# 6. Jalankan instalasi GUI di dalam Ubuntu PRoot (Dynamic Storage Binds)
echo -e "${CYAN}[6/7] Menjalankan instalasi Desktop Environment di dalam Ubuntu PRoot...${NC}"
TMPDIR=/data/data/com.termux/files/usr/tmp
mkdir -p "$TMPDIR/.X11-unix"

# Siapkan DNS multi-tier (Android Network DNS + Gateway + Fallback Public DNS)
DNS_LIST=()
for prop in net.dns1 net.dns2 net.dns3 net.dns4 net.wlan0.dns1 net.wlan0.dns2 net.rmnet_data0.dns1; do
    d=$(getprop "$prop" 2>/dev/null)
    [ -n "$d" ] && DNS_LIST+=("$d")
done
GW=$(ip route show 2>/dev/null | awk '/default/ {print $3}' | head -n1)
[ -n "$GW" ] && DNS_LIST+=("$GW")
# Prioritaskan Tailscale MagicDNS dan DNS internal eduroam/Android
DNS_LIST+=("100.100.100.100")
for d in $(/system/bin/dumpsys connectivity 2>/dev/null | grep -o 'DnsAddresses: \[ [^]]* \]' | tr -d '[]/' | tr ',' ' '); do
    [ "$d" != "DnsAddresses:" ] && DNS_LIST+=("$d")
done
DNS_LIST+=("8.8.8.8" "1.1.1.1" "8.8.4.4" "9.9.9.9")

> "$TMPDIR/resolv.conf"
for d in "${DNS_LIST[@]}"; do
    if ! grep -q "nameserver $d" "$TMPDIR/resolv.conf" 2>/dev/null; then
        echo "nameserver $d" >> "$TMPDIR/resolv.conf"
    fi
done

PROOT_BINDS=()
[ -d "$TMPDIR/.X11-unix" ] && PROOT_BINDS+=(--bind "$TMPDIR/.X11-unix:/tmp/.X11-unix")
[ -d "$REPO_DIR" ] && PROOT_BINDS+=(--bind "$REPO_DIR:/root/UbRoid_TriWahyu45")
[ -d "$HOME" ] && PROOT_BINDS+=(--bind "$HOME:/root/termux_home")
[ -f "$TMPDIR/resolv.conf" ] && PROOT_BINDS+=(--bind "$TMPDIR/resolv.conf:/etc/resolv.conf")

# Deteksi Penyimpanan Android yang Benar-Benar Ada di HP
STORAGE_TARGET=""
if [ -d "/sdcard" ] && [ -r "/sdcard" ]; then
    STORAGE_TARGET="/sdcard"
elif [ -d "/storage/emulated/0" ] && [ -r "/storage/emulated/0" ]; then
    STORAGE_TARGET="/storage/emulated/0"
elif [ -d "$HOME/storage/shared" ] && [ -r "$HOME/storage/shared" ]; then
    STORAGE_TARGET="$HOME/storage/shared"
fi

if [ -n "$STORAGE_TARGET" ]; then
    PROOT_BINDS+=(--bind "$STORAGE_TARGET:/root/Android_Storage")
fi

proot-distro login "$UBUNTU_CONTAINER" "${PROOT_BINDS[@]}" -- bash /root/UbRoid_TriWahyu45/install.sh --mode "$INSTALL_MODE"

# 7. Salin APK ke folder Download Android agar mudah dipasang pengguna
echo -e "${CYAN}[7/7] Menyalin APK pendukung ke folder Download Android...${NC}"
APK_DEST=""
if [ -d "/sdcard/Download" ]; then
    APK_DEST="/sdcard/Download/UbRoid_APKs"
elif [ -d "/storage/emulated/0/Download" ]; then
    APK_DEST="/storage/emulated/0/Download/UbRoid_APKs"
elif [ -d "$HOME/storage/downloads" ]; then
    APK_DEST="$HOME/storage/downloads/UbRoid_APKs"
else
    APK_DEST="$HOME/UbRoid_APKs"
fi

mkdir -p "$APK_DEST" 2>/dev/null || true
cp "$REPO_DIR"/apks/*.apk "$APK_DEST/" 2>/dev/null || true

# Buka dialog izin Overlay Android untuk Termux-X11
/system/bin/am start -a android.settings.action.MANAGE_OVERLAY_PERMISSION -d "package:com.termux.x11" 2>/dev/null || true

# Matikan trap error karena instalasi sukses
trap - ERR

# 8. Selesai
echo -e "\n${GREEN}==============================================================================${NC}"
echo -e "${GREEN}🎉 INSTALASI UBROID BERHASIL DISELESAIKAN UNTUK ${DEV_NAME}!${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo -e "Langkah Terakhir (Sangat Mudah):"
echo -e "1. File APK pendukung otomatis disalin ke folder internal:"
echo -e "   📂 ${YELLOW}$APK_DEST${NC}"
echo -e "   Buka File Manager Android -> Download -> UbRoid_APKs, lalu pasang:"
echo -e "   - ${CYAN}termux-x11.apk${NC} (Display Server X11)"
echo -e "   - ${CYAN}Ubuntu_Launcher.apk${NC} (Peluncur 1-Tap Homescreen)"
echo -e "2. Pastikan izin ${YELLOW}'Tampilkan di atas aplikasi lain'${NC} aktif untuk Termux-X11."
echo -e "3. Jalankan perintah di Termux: ${YELLOW}ubuntu${NC} (atau tap icon aplikasi Ubuntu di Homescreen)!"
echo -e "${GREEN}==============================================================================${NC}\n"
