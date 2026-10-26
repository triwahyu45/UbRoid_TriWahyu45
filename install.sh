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

export DEBIAN_FRONTEND=noninteractive

# 1. Pastikan DNS resolver aktif di PRoot (Anti-Fail DNS)
echo "[1/10] Memeriksa & memperbaiki konfigurasi DNS dan repository..."
if [ ! -f /etc/resolv.conf ] || grep -q "127.0.0.53" /etc/resolv.conf 2>/dev/null || [ ! -s /etc/resolv.conf ]; then
    rm -f /etc/resolv.conf
    cat << 'EOF' > /etc/resolv.conf
nameserver 8.8.8.8
nameserver 1.1.1.1
nameserver 8.8.4.4
nameserver 9.9.9.9
EOF
fi

# 2. Deteksi Arsitektur & Codename Ubuntu (Noble/Jammy, Ports vs Archive)
ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
case "$ARCH" in
    aarch64|arm64) UBUNTU_MIRROR="http://ports.ubuntu.com/ubuntu-ports/" ;;
    armhf|armv7l)  UBUNTU_MIRROR="http://ports.ubuntu.com/ubuntu-ports/" ;;
    riscv64)       UBUNTU_MIRROR="http://ports.ubuntu.com/ubuntu-ports/" ;;
    *)             UBUNTU_MIRROR="http://archive.ubuntu.com/ubuntu/" ;;
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
fi

cat << EOF > /etc/apt/sources.list
deb ${UBUNTU_MIRROR} ${CODENAME} main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${CODENAME}-updates main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${CODENAME}-backports main restricted universe multiverse
deb ${UBUNTU_MIRROR} ${CODENAME}-security main restricted universe multiverse
EOF

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
echo "[2/10] Memasang paket desktop XFCE, Firefox & library sistem..."
apt-get install -y --fix-missing \
    xfce4 xfce4-panel xfwm4 xfce4-settings xfce4-terminal \
    yaru-theme-gtk yaru-theme-icon fonts-ubuntu \
    libgtk-3-dev gcc pkg-config xdotool scrot python3-gi \
    gir1.2-gtk-3.0 pulseaudio-utils dbus-x11 bc synaptic sudo \
    firefox thunar-archive-plugin file-roller ristretto \
    adb wmctrl jq terminator mousepad pavucontrol onboard \
    xclip xsel wl-clipboard || apt-get install -f -y

# Bersihkan browser berat seperti Chromium jika ada
apt-get purge -y chromium chromium-common 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true

# Set Firefox sebagai default browser
update-alternatives --set x-www-browser /usr/bin/firefox 2>/dev/null || true
update-alternatives --set gnome-www-browser /usr/bin/firefox 2>/dev/null || true

# 3. Pasang wallpaper & icon resmi
echo "[3/10] Memasang wallpaper dan tema icon Ubuntu..."
mkdir -p /usr/share/backgrounds
cp "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/warty-final-ubuntu.png 2>/dev/null || true
cp "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/noble-numbat.png 2>/dev/null || true
cp "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/jammy-jellyfish.png 2>/dev/null || true

mkdir -p /usr/share/icons/hicolor/scalable/apps /usr/share/icons/Yaru/scalable/apps
cp "$SCRIPT_DIR"/assets/icons/*.svg /usr/share/icons/hicolor/scalable/apps/ 2>/dev/null || true
cp "$SCRIPT_DIR"/assets/icons/*.svg /usr/share/icons/Yaru/scalable/apps/ 2>/dev/null || true
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
gtk-update-icon-cache -f /usr/share/icons/Yaru 2>/dev/null || true

# 4. Pasang konfigurasi XFCE, GTK, Panel, Desktop & File Associations
echo "[4/10] Mengonfigurasi panel dock, window manager, desktop & GTK..."
mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml
mkdir -p /root/.config/xfce4/panel
mkdir -p /root/.config/gtk-3.0
mkdir -p /root/.config/autostart
mkdir -p /root/.config/terminator
mkdir -p /root/Desktop
mkdir -p /etc/xdg/xfce4/xfconf/xfce-perchannel-xml
mkdir -p /etc/xdg/autostart

cp "$SCRIPT_DIR/configs/ubroid-about.desktop" /usr/share/applications/ 2>/dev/null || true

# Salin seluruh XML pengaturan XFCE
cp "$SCRIPT_DIR/configs/"*.xml /root/.config/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true
cp "$SCRIPT_DIR/configs/"*.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true

# Salin konfigurasi GTK, Terminator, & Mimeapps
cp "$SCRIPT_DIR/configs/gtk.css" /root/.config/gtk-3.0/
cp "$SCRIPT_DIR/configs/bookmarks" /root/.config/gtk-3.0/ 2>/dev/null || true
cp "$SCRIPT_DIR/configs/.Xresources" /root/.Xresources 2>/dev/null || true
cp "$SCRIPT_DIR/configs/mimeapps.list" /root/.config/mimeapps.list 2>/dev/null || true
cp "$SCRIPT_DIR/configs/mimeapps.list" /etc/xdg/mimeapps.list 2>/dev/null || true
cp "$SCRIPT_DIR/configs/terminator/config" /root/.config/terminator/config 2>/dev/null || true

# Pasang shortcut desktop resmi
cp "$SCRIPT_DIR/configs/desktop/"*.desktop /root/Desktop/ 2>/dev/null || true
chmod +x /root/Desktop/*.desktop 2>/dev/null || true

# Bersihkan dan pasang panel launchers terbaru
rm -rf /root/.config/xfce4/panel/launcher-*
cp -r "$SCRIPT_DIR/configs/panel_launchers/"* /root/.config/xfce4/panel/ 2>/dev/null || true

# 5. Pasang autostart daemons
echo "[5/10] Memasang layanan autostart..."
cp "$SCRIPT_DIR/configs/autostart/"* /root/.config/autostart/ 2>/dev/null || true
cp "$SCRIPT_DIR/configs/autostart/"* /etc/xdg/autostart/ 2>/dev/null || true

# 6. Pasang script executables ke /usr/local/bin
echo "[6/10] Memasang daemons status bar, tools dock, & utilitas UbRoid..."
mkdir -p /usr/local/bin
cp "$SCRIPT_DIR/bin/"* /usr/local/bin/ 2>/dev/null || true
chmod +x /usr/local/bin/* 2>/dev/null || true

# 7. Konfigurasi Antigravity CLI (AGY) Turbo Mode
echo "[7/10] Menyiapkan Antigravity CLI (agy) Turbo Mode..."
mkdir -p /root/.gemini/antigravity-cli /root/.local/bin
if [ -f "$SCRIPT_DIR/configs/antigravity/settings.json" ]; then
    cp "$SCRIPT_DIR/configs/antigravity/settings.json" /root/.gemini/antigravity-cli/settings.json
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
