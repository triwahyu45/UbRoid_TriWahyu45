#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# UbRoid - 1-Command Permanent Switch to Ubuntu Touch Mobile Edition
# Repository: https://github.com/triwahyu45/UbRoid_TriWahyu45
# Author: Tri Wahyu Handoyo (triwahyu45 / DetronicsID)
# ==============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${PURPLE}==============================================================================${NC}"
echo -e "${GREEN}📱 Mengaktifkan Mode Ubuntu Touch Mobile Edition (Permanen)...${NC}"
echo -e "${PURPLE}==============================================================================${NC}"

# 1. Deteksi container Ubuntu di Termux
UBUNTU_CONTAINER="ubuntu"
if ! proot-distro list 2>/dev/null | grep -q "^ubuntu\b.*installed"; then
    if proot-distro list 2>/dev/null | grep -q "ubuntu:24.04.*installed"; then
        UBUNTU_CONTAINER="ubuntu:24.04"
    fi
fi

# 2. Pasang shortcut perintah mandiri 'touch-mode' & 'desktop-mode' di Termux
PREFIX_BIN="/data/data/com.termux/files/usr/bin"
if [ -d "$PREFIX_BIN" ]; then
    cat << 'EOF' > "$PREFIX_BIN/touch-mode"
#!/data/data/com.termux/files/usr/bin/bash
c="ubuntu"
proot-distro list 2>/dev/null | grep -q "ubuntu:24.04.*installed" && c="ubuntu:24.04"
echo "Mengaktifkan mode Ubuntu Touch Mobile..."
proot-distro login "$c" --bind /sdcard:/sdcard -- bash -c '
    if [ -x /usr/local/bin/ubroid-switch-mode ]; then
        /usr/local/bin/ubroid-switch-mode touch
    else
        echo "touch" > /etc/ubroid/mode
    fi
'
echo "✓ Mode Ubuntu Touch aktif permanen. Jalankan 'ubuntu' untuk masuk."
EOF
    chmod +x "$PREFIX_BIN/touch-mode"

    cat << 'EOF' > "$PREFIX_BIN/desktop-mode"
#!/data/data/com.termux/files/usr/bin/bash
c="ubuntu"
proot-distro list 2>/dev/null | grep -q "ubuntu:24.04.*installed" && c="ubuntu:24.04"
echo "Mengaktifkan mode Ubuntu Desktop..."
proot-distro login "$c" --bind /sdcard:/sdcard -- bash -c '
    if [ -x /usr/local/bin/ubroid-switch-mode ]; then
        /usr/local/bin/ubroid-switch-mode desktop
    else
        echo "desktop" > /etc/ubroid/mode
    fi
'
echo "✓ Mode Ubuntu Desktop aktif permanen. Jalankan 'ubuntu' untuk masuk."
EOF
    chmod +x "$PREFIX_BIN/desktop-mode"

    cat << 'EOF' > "$PREFIX_BIN/ubuntu-os"
#!/data/data/com.termux/files/usr/bin/bash
bash ~/launch_ubuntu.sh --dedicated "$@"
EOF
    chmod +x "$PREFIX_BIN/ubuntu-os"
    ln -sf "$PREFIX_BIN/ubuntu-os" "$PREFIX_BIN/uos" 2>/dev/null || true
fi

# 3. Update atau sinkronisasi repository UbRoid di Termux
REPO_DIR="$HOME/UbRoid_TriWahyu45"
if [ -d "$REPO_DIR/.git" ]; then
    echo -e "${CYAN}[1/4] Memperbarui file konfigurasi dari repository GitHub...${NC}"
    cd "$REPO_DIR" && git pull origin main || true
else
    echo -e "${CYAN}[1/4] Mengunduh profil Ubuntu Touch terbaru...${NC}"
    git clone https://github.com/triwahyu45/UbRoid_TriWahyu45.git "$REPO_DIR" 2>/dev/null || true
fi

# 4. Terapkan konfigurasi profil touch di dalam container Ubuntu
echo -e "${CYAN}[2/4] Menerapkan UI ramah sentuhan (Lomiri 68px, 170 DPI, Onboard, 26px scrollbar, Anti-Rat Wallpaper)...${NC}"
proot-distro login "$UBUNTU_CONTAINER" --bind /sdcard:/sdcard --bind "$REPO_DIR:/root/UbRoid_TriWahyu45" -- bash -c '
    set -e
    SRC="/root/UbRoid_TriWahyu45"
    [ ! -d "$SRC" ] && SRC="/etc/ubroid"

    mkdir -p /etc/ubroid/profiles /root/.config/xfce4/xfconf/xfce-perchannel-xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml /root/.config/gtk-3.0 /root/.config/xfce4/panel /usr/local/bin

    # Salin profil touch
    if [ -d "$SRC/configs/profiles/touch" ]; then
        cp -r "$SRC/configs/profiles/"* /etc/ubroid/profiles/ 2>/dev/null || true
        cp "$SRC/configs/profiles/touch/"*.xml /root/.config/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true
        cp "$SRC/configs/profiles/touch/"*.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true
        cp "$SRC/configs/profiles/touch/gtk.css" /root/.config/gtk-3.0/gtk.css 2>/dev/null || true
        rm -rf /root/.config/xfce4/panel/launcher-*
        cp -r "$SRC/configs/profiles/touch/panel_launchers/"* /root/.config/xfce4/panel/ 2>/dev/null || true
    fi

    # Pasang wallpaper resmi Ubuntu & hilangkan wallpaper tikus XFCE selamanya
    WP_SRC="$SRC/assets/wallpapers/warty-final-ubuntu.png"
    if [ -f "$WP_SRC" ]; then
        mkdir -p /usr/share/backgrounds/xfce 2>/dev/null || true
        cp -f "$WP_SRC" /usr/share/backgrounds/warty-final-ubuntu.png 2>/dev/null || true
        cp -f "$WP_SRC" /usr/share/backgrounds/warty-1280x800.png 2>/dev/null || true
        cp -f "$WP_SRC" /usr/share/backgrounds/noble-numbat.png 2>/dev/null || true
        for xf in /usr/share/backgrounds/xfce/*.png; do
            [ -e "$xf" ] && cp -f "$WP_SRC" "$xf" 2>/dev/null || true
        done
        cp -f "$WP_SRC" /usr/share/backgrounds/xfce/xfce-teal.png 2>/dev/null || true
        cp -f "$WP_SRC" /usr/share/backgrounds/xfce/xfce-blue.png 2>/dev/null || true
        cp -f "$WP_SRC" /usr/share/backgrounds/xfce/xfce-stripes.png 2>/dev/null || true
    fi

    # Perbarui start_desktop.sh di dalam container
    if [ -f "$SRC/scripts/start_desktop.sh" ]; then
        cp "$SRC/scripts/start_desktop.sh" /root/start_desktop.sh 2>/dev/null || true
        chmod +x /root/start_desktop.sh 2>/dev/null || true
    fi

    # Pasang script executables pendukung
    if [ -d "$SRC/bin" ]; then
        cp "$SRC/bin/"* /usr/local/bin/ 2>/dev/null || true
        chmod +x /usr/local/bin/* 2>/dev/null || true
        ln -sf /usr/local/bin/ubroid-switch-mode /usr/local/bin/switch-mode 2>/dev/null || true
    fi

    # Pasang icon
    if [ -d "$SRC/assets/icons" ]; then
        mkdir -p /usr/share/icons/hicolor/scalable/apps
        cp "$SRC"/assets/icons/*.svg /usr/share/icons/hicolor/scalable/apps/ 2>/dev/null || true
        gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
    fi

    # Pasang Python workspace jika belum ada
    mkdir -p /root/Python_Workspace
    if [ ! -f /root/Python_Workspace/welcome.py ]; then
        cat << "PYEOF" > /root/Python_Workspace/welcome.py
import platform, os
print("🚀 Python Mobile Studio Siap Digunakan!")
print(f"📦 Arsitektur: {platform.machine()} | OS: {platform.system()}")
PYEOF
    fi

    # Pasang paket keyboard onboard jika belum ada
    if ! command -v onboard >/dev/null 2>&1; then
        apt-get update -y >/dev/null 2>&1 || true
        apt-get install -y onboard dconf-cli >/dev/null 2>&1 || true
    fi

    # Simpan preferensi mode permanen
    echo "touch" > /etc/ubroid/mode
'

# 5. Salin ~/launch_ubuntu.sh terbaru jika ada
if [ -f "$REPO_DIR/scripts/launch_ubuntu.sh" ]; then
    cp "$REPO_DIR/scripts/launch_ubuntu.sh" "$HOME/launch_ubuntu.sh"
    chmod +x "$HOME/launch_ubuntu.sh"
fi

# 6. Perbarui ~/.bashrc Termux
if [ -f "$REPO_DIR/configs/bash/termux_bashrc" ]; then
    cp "$REPO_DIR/configs/bash/termux_bashrc" "$HOME/.bashrc"
fi

echo -e "\n${GREEN}==============================================================================${NC}"
echo -e "${GREEN}🎉 SUKSES! POCO F6 ANDA KINI MENGGUNAKAN UBUNTU TOUCH MOBILE EDITION!${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo -e "Fitur yang kini aktif secara permanen:"
echo -e " 1. 📱 ${YELLOW}Lomiri Vertical Launcher${NC} di sebelah kiri layar (ramah jempol)."
echo -e " 2. 👆 ${YELLOW}Single-Tap Navigation${NC} (cukup 1 ketukan jari untuk membuka aplikasi/file)."
echo -e " 3. 🔍 ${YELLOW}Skala UI 170 DPI${NC} (teks & ikon proporsional, pas di layar HP Poco F6)."
echo -e " 4. 🎨 ${YELLOW}Wallpaper Resmi Ubuntu Touch${NC} (aubergine warm, bebas wallpaper tikus)."
echo -e " 5. 📜 ${YELLOW}Touch Scrollbar 26px${NC} (mudah digeser nyaman dengan jari)."
echo -e " 6. ⌨️ ${YELLOW}Dual Keyboard Support${NC} (Gboard via swipe-up & Onboard auto-popup)."
echo -e " 7. 🐍 ${YELLOW}Python Mobile Studio${NC} tersemat di launcher kiri."
echo -e "\nKapan saja Anda ingin berganti mode dari Termux, cukup ketik:"
echo -e " - ${CYAN}touch-mode${NC}   : Kembali ke Ubuntu Touch Mobile"
echo -e " - ${CYAN}desktop-mode${NC} : Beralih ke Ubuntu Desktop klasik"
echo -e "\nCara Menjalankan Ubuntu:"
echo -e " - ${GREEN}ubuntu${NC}      : Mode CLI Cepat (Ringan, tetap multitasking dengan Android)"
echo -e " - ${YELLOW}ubuntu-os${NC}   : Mode Dedicated OS (Tinggalkan Android, 100% RAM & CPU)"
echo -e " - Buka dari ${PURPLE}APK Ubuntu Launcher${NC} di HomeScreen untuk Dedicated OS 1-ketuk!\n"
