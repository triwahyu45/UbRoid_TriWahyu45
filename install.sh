#!/bin/bash
# ==============================================================================
# UbRoid GUI & System Installer (PRoot / In-Ubuntu mode)
# Repository: https://github.com/triwahyu45/UbRoid_TriWahyu45
# Author: Tri Wahyu Handoyo (triwahyu45)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
# Auto Bug / Crash Reporter Trap
# ==============================================================================
report_install_error() {
    local exit_code=$?
    local failed_line=$1
    local failed_cmd=$2

    echo -e "\n\033[0;31m[!] TERJADI KESALAHAN PADA INSTALASI UBROID!\033[0m"
    echo -e "\033[0;33m[*] Baris: $failed_line | Perintah: $failed_cmd | Exit Code: $exit_code\033[0m"

    # Jalankan report-bug jika tersedia
    if command -v report-bug >/dev/null 2>&1; then
        report-bug "Install failed on line $failed_line: $failed_cmd (exit code: $exit_code)" 2>/dev/null || true
    fi
}
trap 'report_install_error $LINENO "$BASH_COMMAND"' ERR

echo "=== MEMASANG / MEMPERBARUI UBROID DESKTOP ENVIRONMENT ==="

# ==============================================================================
# Mode Selection: Desktop (Default) vs Ubuntu Touch Mobile (Poco F6)
# ==============================================================================
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
    echo -e "\n\033[1;35m==============================================================================\033[0m"
    echo -e "\033[1;36m📱 PILIH MODE TAMPILAN UBROID (UBUNTU 24.04 LTS)\033[0m"
    echo -e "\033[1;35m==============================================================================\033[0m"
    echo -e "  \033[1;33m[1]\033[0m 🖥️  \033[1mUbuntu Desktop Edition\033[0m (Default)"
    echo -e "       - Mode Desktop klasik XFCE dengan dock horizontal di bawah."
    echo -e "       - Ideal untuk Tablet, Monitor Eksternal, Keyboard & Mouse fisik.\n"
    echo -e "  \033[1;33m[2]\033[0m 📱 \033[1mUbuntu Touch Mobile Edition\033[0m (Rekomendasi Poco F6 / Layar HP)"
    echo -e "       - Tampilan mobile ala Ubuntu Touch (Lomiri) dengan launcher vertikal di sisi kiri."
    echo -e "       - Tombol & ikon besar ramah sentuhan (touchscreen friendly) & single-tap."
    echo -e "       - Integrasi On-Screen Keyboard (Gboard & Onboard auto-popup di kolom teks)."
    echo -e "       - Dilengkapi Python Mobile Studio (cocok untuk Mini PC & koding di HP)."
    echo -e "\033[1;35m==============================================================================\033[0m"

    INSTALL_MODE="desktop"
    echo -e "Pilih mode dalam 5 detik (Default: [1] Desktop):"
    for ((i=5; i>=1; i--)); do
        echo -ne "\r⏳ Memilih [1] Desktop otomatis dalam \033[1;33m${i}s\033[0m (Tekan \033[1;32m2\033[0m untuk Touch): "
        if read -t 1 -n 1 user_input; then
            echo ""
            if [ "$user_input" = "2" ]; then
                INSTALL_MODE="touch"
                echo -e "\033[1;32m✓ Mode Dipilih: Ubuntu Touch Mobile Edition!\033[0m"
            else
                INSTALL_MODE="desktop"
                echo -e "\033[1;36m✓ Mode Dipilih: Ubuntu Desktop Edition!\033[0m"
            fi
            break
        fi
    done
    if [ -z "$user_input" ]; then
        echo -e "\n\033[1;33m⏱️ Waktu habis. Otomatis memilih mode: Ubuntu Desktop Edition (Default)\033[0m"
        INSTALL_MODE="desktop"
    fi
fi

if [ "$INSTALL_MODE" != "touch" ]; then
    INSTALL_MODE="desktop"
fi

mkdir -p /etc/ubroid
echo "$INSTALL_MODE" > /etc/ubroid/mode
echo -e "-> Mode Aktif: \033[1;32m$INSTALL_MODE\033[0m"

export DEBIAN_FRONTEND=noninteractive

# 1. Pastikan DNS resolver aktif di PRoot (Anti-Fail DNS)
echo "[1/10] Memeriksa & memperbaiki konfigurasi DNS dan repository..."
rm -f /etc/resolv.conf 2>/dev/null || true
cat << 'EOF' > /etc/resolv.conf
nameserver 100.100.100.100
nameserver 10.11.12.57
nameserver 10.100.1.3
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# Konfigurasi retry, timeout & non-interactive dpkg options
mkdir -p /etc/apt/apt.conf.d
cat << 'EOF' > /etc/apt/apt.conf.d/99ubroid-network
Acquire::Retries "5";
Acquire::http::Timeout "30";
Acquire::https::Timeout "30";
Acquire::Queue-Mode "host";
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
};
EOF

# 2. Deteksi Arsitektur & Mirror Tercepat (Anti-Lag Mirror Auto-Select)
ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
case "$ARCH" in
    aarch64|arm64|armhf|armv7l|riscv64)
        UBUNTU_MIRROR="http://ports.ubuntu.com/ubuntu-ports/"
        for cand in "http://free.nchc.org.tw/ubuntu-ports/" "http://mirror.math.princeton.edu/pub/ubuntu-ports/"; do
            if curl -s -o /dev/null -w "%{http_code}" -m 3 "${cand}dists/noble/Release" 2>/dev/null | grep -q "200"; then
                UBUNTU_MIRROR="$cand"
                echo "✓ Menggunakan high-speed mirror: $UBUNTU_MIRROR"
                break
            fi
        done
        ;;
    *)
        UBUNTU_MIRROR="http://archive.ubuntu.com/ubuntu/"
        ;;
esac

CODENAME="$(grep VERSION_CODENAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"
[ -z "$CODENAME" ] && CODENAME="noble"

# Aktifkan seluruh komponen resmi: main, universe, restricted, multiverse
if [ -d /etc/apt/sources.list.d ]; then
    cat << EOF > /etc/apt/sources.list.d/ubuntu.sources
Types: deb
URIs: ${UBUNTU_MIRROR}
Suites: ${CODENAME} ${CODENAME}-updates ${CODENAME}-backports
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: ${UBUNTU_MIRROR}
Suites: ${CODENAME}-security
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
    # Kosongkan /etc/apt/sources.list agar tidak muncul warning "configured multiple times"
    cat << 'EOF' > /etc/apt/sources.list
# Ubuntu sources are managed in /etc/apt/sources.list.d/ubuntu.sources
EOF
else
    cat << EOF > /etc/apt/sources.list
deb ${UBUNTU_MIRROR} ${CODENAME} main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${CODENAME}-updates main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${CODENAME}-backports main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${CODENAME}-security main restricted universe multiverse
EOF
fi

# Bersihkan sisa lock jika ada proses instalasi sebelumnya yang terinterupsi
rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock* 2>/dev/null || true

# Update repository
apt-get update -y || apt-get update --fix-missing -y || true

# Pasang dependensi esensial (ca-certificates, gnupg, curl, software-properties-common)
apt-get install -y --no-install-recommends ca-certificates gnupg curl || true
apt-get install -y software-properties-common || apt-get install -y --fix-missing software-properties-common || true

# Konfigurasi PPA Firefox resmi
cat << 'EOF' > /etc/apt/preferences.d/mozilla-firefox
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF

if command -v add-apt-repository >/dev/null 2>&1; then
    add-apt-repository -y -P mozillateam/ppa 2>/dev/null || add-apt-repository -y ppa:mozillateam/ppa 2>/dev/null || true
fi
apt-get update -y || true

# 2. Pastikan seluruh dependencies desktop dan utilitas terpasang
echo "[2/10] Memasang paket desktop XFCE, Firefox, Python Mini PC & library sistem..."
apt-get install -y --fix-missing \
    xfce4 xfce4-panel xfwm4 xfce4-settings xfce4-terminal \
    yaru-theme-gtk yaru-theme-icon fonts-ubuntu \
    libgtk-3-dev gcc pkg-config x11proto-dev libx11-dev xdotool scrot python3-gi \
    gir1.2-gtk-3.0 pulseaudio-utils dbus-x11 bc synaptic sudo \
    firefox thunar-archive-plugin file-roller ristretto \
    adb wmctrl jq terminator mousepad pavucontrol onboard \
    dconf-cli dconf-gsettings-backend gsettings-desktop-schemas \
    python3 python3-pip python3-venv python3-dev build-essential ipython3 \
    xclip xsel wl-clipboard || true

# Jalankan perbaikan dependensi & pastikan paket esensial tidak ada yang terlewat
dpkg --configure -a || true
apt-get install -f -y || true
apt-get install -y \
    xfce4 xfce4-panel xfwm4 xfce4-settings xfce4-terminal \
    yaru-theme-gtk yaru-theme-icon fonts-ubuntu \
    libgtk-3-dev gcc pkg-config x11proto-dev libx11-dev xdotool scrot \
    pulseaudio-utils dbus-x11 bc synaptic sudo firefox \
    terminator mousepad onboard dconf-cli \
    python3 python3-pip python3-venv \
    xclip xsel wl-clipboard || true

# Bersihkan browser berat seperti Chromium jika ada
apt-get purge -y chromium chromium-common 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true

# Set Firefox sebagai default browser
update-alternatives --set x-www-browser /usr/bin/firefox 2>/dev/null || true
update-alternatives --set gnome-www-browser /usr/bin/firefox 2>/dev/null || true

# 3. Pasang wallpaper & icon resmi
echo "[3/10] Memasang wallpaper dan tema icon Ubuntu..."
mkdir -p /usr/share/backgrounds /usr/share/backgrounds/xfce
cp "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/warty-final-ubuntu.png 2>/dev/null || true
cp "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/ubuntu-touch-default.png 2>/dev/null || true
cp "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/warty-1280x800.png 2>/dev/null || true
cp "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/noble-numbat.png 2>/dev/null || true
cp "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/jammy-jellyfish.png 2>/dev/null || true
for xf in /usr/share/backgrounds/xfce/*.png; do
    [ -e "$xf" ] && cp -f "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" "$xf" 2>/dev/null || true
done
cp -f "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/xfce/xfce-teal.png 2>/dev/null || true
cp -f "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/xfce/xfce-blue.png 2>/dev/null || true
cp -f "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/xfce/xfce-stripes.png 2>/dev/null || true

mkdir -p /usr/share/icons/hicolor/scalable/apps /usr/share/icons/Yaru/scalable/apps
cp "$SCRIPT_DIR"/assets/icons/*.svg /usr/share/icons/hicolor/scalable/apps/ 2>/dev/null || true
cp "$SCRIPT_DIR"/assets/icons/*.svg /usr/share/icons/Yaru/scalable/apps/ 2>/dev/null || true
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
gtk-update-icon-cache -f /usr/share/icons/Yaru 2>/dev/null || true

# 4. Pasang konfigurasi XFCE, GTK, Panel, Desktop & File Associations
echo "[4/10] Mengonfigurasi desktop environment (Profil: $INSTALL_MODE)..."
mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml
mkdir -p /root/.config/xfce4/panel
mkdir -p /root/.config/gtk-3.0
mkdir -p /root/.config/autostart
mkdir -p /root/.config/terminator
mkdir -p /root/Desktop
mkdir -p /etc/xdg/xfce4/xfconf/xfce-perchannel-xml
mkdir -p /etc/xdg/autostart
mkdir -p /etc/ubroid/profiles

# Simpan seluruh profil ke /etc/ubroid/profiles agar switch-mode siap dipakai kapan saja
cp -r "$SCRIPT_DIR/configs/profiles/"* /etc/ubroid/profiles/ 2>/dev/null || true

# Tentukan folder profil yang aktif
ACTIVE_PROFILE_DIR="$SCRIPT_DIR/configs/profiles/$INSTALL_MODE"
[ ! -d "$ACTIVE_PROFILE_DIR" ] && ACTIVE_PROFILE_DIR="$SCRIPT_DIR/configs/profiles/desktop"
[ ! -d "$ACTIVE_PROFILE_DIR" ] && ACTIVE_PROFILE_DIR="$SCRIPT_DIR/configs"

cp "$SCRIPT_DIR/configs/ubroid-about.desktop" /usr/share/applications/ 2>/dev/null || true

# Salin seluruh XML pengaturan XFCE dari profil aktif
cp "$ACTIVE_PROFILE_DIR/"*.xml /root/.config/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true
cp "$ACTIVE_PROFILE_DIR/"*.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true

# Salin konfigurasi GTK, Terminator, & Mimeapps
if [ -f "$ACTIVE_PROFILE_DIR/gtk.css" ]; then
    cp "$ACTIVE_PROFILE_DIR/gtk.css" /root/.config/gtk-3.0/
else
    cp "$SCRIPT_DIR/configs/gtk.css" /root/.config/gtk-3.0/
fi
cp "$SCRIPT_DIR/configs/bookmarks" /root/.config/gtk-3.0/ 2>/dev/null || true
cp "$SCRIPT_DIR/configs/.Xresources" /root/.Xresources 2>/dev/null || true
cp "$SCRIPT_DIR/configs/mimeapps.list" /root/.config/mimeapps.list 2>/dev/null || true
cp "$SCRIPT_DIR/configs/mimeapps.list" /etc/xdg/mimeapps.list 2>/dev/null || true
cp "$SCRIPT_DIR/configs/terminator/config" /root/.config/terminator/config 2>/dev/null || true

# Konfigurasi Onboard Virtual Keyboard dconf system-wide (Auto-popup pada teks)
mkdir -p /etc/dconf/db/local.d /etc/dconf/profile
cat << 'DCONF_EOF' > /etc/dconf/profile/user
user-db:user
system-db:local
DCONF_EOF
if [ -f "$SCRIPT_DIR/configs/onboard/01-onboard" ]; then
    cp "$SCRIPT_DIR/configs/onboard/01-onboard" /etc/dconf/db/local.d/01-onboard
    dconf update 2>/dev/null || true
fi

# Inisialisasi folder kerja Python Mobile Studio & Mini PC
mkdir -p /root/Python_Workspace
if [ ! -f /root/Python_Workspace/welcome.py ]; then
    cat << 'PY_EOF' > /root/Python_Workspace/welcome.py
# ==============================================================================
# Selamat datang di Python Mobile Studio di POCO F6!
# Anda bisa menjalankan script ini kapan saja: python3 welcome.py
# ==============================================================================
import platform
import os
import sys

print(f"🚀 Selamat Datang di Python Mobile Mini PC!")
print(f"📦 Arsitektur : {platform.machine()}")
print(f"💻 Sistem OS  : {platform.system()} {platform.release()}")
print(f"🐍 Python Ver : {platform.python_version()}")
print(f"📂 Direktori  : {os.getcwd()}")
print("\nUbRoid siap digunakan untuk analisis data, coding, dan otomasi.")
PY_EOF
fi

# Pasang shortcut desktop resmi
cp "$SCRIPT_DIR/configs/desktop/"*.desktop /root/Desktop/ 2>/dev/null || true
chmod +x /root/Desktop/*.desktop 2>/dev/null || true
for f in /root/Desktop/*.desktop; do
    [ -f "$f" ] && gio set "$f" metadata::trusted true 2>/dev/null || true
done

# Bersihkan dan pasang panel launchers dari profil aktif
rm -rf /root/.config/xfce4/panel/launcher-*
if [ -d "$ACTIVE_PROFILE_DIR/panel_launchers" ]; then
    cp -r "$ACTIVE_PROFILE_DIR/panel_launchers/"* /root/.config/xfce4/panel/ 2>/dev/null || true
else
    cp -r "$SCRIPT_DIR/configs/panel_launchers/"* /root/.config/xfce4/panel/ 2>/dev/null || true
fi

# 5. Pasang autostart daemons
echo "[5/10] Memasang layanan autostart..."
cp "$SCRIPT_DIR/configs/autostart/"* /root/.config/autostart/ 2>/dev/null || true
cp "$SCRIPT_DIR/configs/autostart/"* /etc/xdg/autostart/ 2>/dev/null || true

# 6. Pasang script executables ke /usr/local/bin
echo "[6/10] Memasang daemons status bar, tools dock, & utilitas UbRoid..."
mkdir -p /usr/local/bin
cp "$SCRIPT_DIR/bin/"* /usr/local/bin/ 2>/dev/null || true
chmod +x /usr/local/bin/* 2>/dev/null || true
ln -sf /usr/local/bin/ubroid-switch-mode /usr/local/bin/switch-mode 2>/dev/null || true

# 7. Konfigurasi Antigravity CLI (AGY) Turbo Mode
echo "[7/10] Menyiapkan Antigravity CLI (agy) Turbo Mode..."
mkdir -p /root/.gemini/antigravity-cli /root/.local/bin /usr/local/bin
if [ -f "$SCRIPT_DIR/configs/antigravity/settings.json" ]; then
    cp "$SCRIPT_DIR/configs/antigravity/settings.json" /root/.gemini/antigravity-cli/settings.json
fi

# Unduh & siapkan binary resmi Antigravity CLI jika belum ada
if [ ! -f /root/.local/bin/agy.real ]; then
    if [ -f /root/.local/bin/agy ] && [ ! -L /root/.local/bin/agy ]; then
        mv /root/.local/bin/agy /root/.local/bin/agy.real
    else
        echo "  -> Memasang Antigravity CLI resmi..."
        curl -fsSL https://antigravity.google/cli/install.sh | bash 2>/dev/null || true
        if [ -f /root/.local/bin/agy ] && [ ! -L /root/.local/bin/agy ]; then
            mv /root/.local/bin/agy /root/.local/bin/agy.real
        fi
    fi
fi
if [ -f "$SCRIPT_DIR/bin/agy" ]; then
    cp "$SCRIPT_DIR/bin/agy" /usr/local/bin/agy
    chmod +x /usr/local/bin/agy
    ln -sf /usr/local/bin/agy /root/.local/bin/agy 2>/dev/null || true
fi

# 8. Kompilasi libnogap.so (Native C Interceptor)
echo "[8/10] Mengompilasi libnogap.so (Native C Interceptor)..."
mkdir -p /usr/local/src /usr/local/lib
cp "$SCRIPT_DIR/src/libnogap.c" /usr/local/src/libnogap.c
gcc -O2 -shared -fPIC /usr/local/src/libnogap.c -o /usr/local/lib/libnogap.so $(pkg-config --cflags --libs gtk+-3.0) 2>/dev/null || true

# Wrapper xfce4-panel agar selalu memuat libnogap
if [ -f /usr/bin/xfce4-panel.bin ]; then
    :
elif [ -f /usr/bin/xfce4-panel ]; then
    mv /usr/bin/xfce4-panel /usr/bin/xfce4-panel.bin
    cat << 'WRAPPER_EOF' > /usr/bin/xfce4-panel
#!/bin/bash
export LD_PRELOAD=/usr/local/lib/libnogap.so${LD_PRELOAD:+:$LD_PRELOAD}
exec /usr/bin/xfce4-panel.bin "$@"
WRAPPER_EOF
    chmod +x /usr/bin/xfce4-panel
fi

# 9. Pasang start desktop script & shutdown script
echo "[9/10] Menyiapkan start_desktop.sh & shutdown-ubuntu..."
cp "$SCRIPT_DIR/scripts/start_desktop.sh" /root/start_desktop.sh
chmod +x /root/start_desktop.sh
cp "$SCRIPT_DIR/scripts/shutdown_ubuntu.sh" /usr/local/bin/shutdown-ubuntu 2>/dev/null || true
chmod +x /usr/local/bin/shutdown-ubuntu 2>/dev/null || true

# 10. Pasang DetronicsID Welcome Banner & bashrc
echo "[10/10] Mengonfigurasi terminal & DetronicsID Welcome Banner..."
if [ -f "$SCRIPT_DIR/configs/bash/ubuntu_bashrc" ]; then
    cp "$SCRIPT_DIR/configs/bash/ubuntu_bashrc" /root/.bashrc
fi

# Restart panel jika desktop sedang aktif
if pgrep -x xfce4-panel >/dev/null 2>&1 || pgrep -f xfce4-panel.bin >/dev/null 2>&1; then
    /usr/local/bin/restart_panel.sh 2>/dev/null || true
fi

echo -e "\n=============================================================================="
echo -e "✓ UbRoid Desktop Environment (Ubuntu 24.04 LTS) berhasil dipasang dan dikonfigurasi!"
echo -e "==============================================================================\n"
