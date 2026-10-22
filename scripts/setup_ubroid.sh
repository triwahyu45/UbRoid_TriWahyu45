#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# UbRoid - Ubuntu 24.04 LTS (Noble Numbat) for Android
# One-Command Automated Setup Script
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

echo -e "${PURPLE}"
cat << "EOF"
  _   _ _     ____       _     _ 
 | | | | |__ |  _ \ ___ (_) __| |
 | | | | '_ \| |_) / _ \| |/ _` |
 | |_| | |_) |  _ < (_) | | (_| |
  \___/|_.__/|_| \_\___/|_|\__,_|
  ⚡ Ubuntu 24.04 LTS for Android Tablets & Phones
  🚀 Authentic Ubuntu Desktop • 0% Flickering • 1-Tap Launcher
EOF
echo -e "${NC}"

echo -e "${CYAN}[1/7] Menyiapkan environment Termux & dependencies...${NC}"
pkg update -y
pkg install -y proot-distro x11-repo pulseaudio wget git tar

# Pastikan permission external app diizinkan untuk 1-tap launcher APK
mkdir -p ~/.termux
if [ -f ~/.termux/termux.properties ]; then
    sed -i '/allow-external-apps/d' ~/.termux/termux.properties
fi
echo "allow-external-apps = true" >> ~/.termux/termux.properties
echo -e "${GREEN}✓ Termux properties dikonfigurasi (allow-external-apps = true)${NC}"

echo -e "${CYAN}[2/7] Mengunduh repository aset UbRoid...${NC}"
REPO_DIR="$HOME/UbRoid_TriWahyu45"
if [ -d "$REPO_DIR" ]; then
    echo "Memperbarui repository yang sudah ada..."
    cd "$REPO_DIR" && git pull || true
else
    git clone https://github.com/triwahyu45/UbRoid_TriWahyu45.git "$REPO_DIR"
fi

echo -e "${CYAN}[3/7] Memasang rootfs Ubuntu 24.04 (Noble Numbat)...${NC}"
if proot-distro list | grep -q "ubuntu (installed)"; then
    echo -e "${GREEN}✓ Rootfs Ubuntu sudah terpasang.${NC}"
else
    echo "Memasang Ubuntu via proot-distro..."
    proot-distro install ubuntu
fi

echo -e "${CYAN}[4/7] Memasang Desktop Environment XFCE, Firefox & Ubuntu Yaru Theme...${NC}"
proot-distro login ubuntu -- bash -c "
    export DEBIAN_FRONTEND=noninteractive
    cat << 'EOF' > /etc/apt/preferences.d/mozilla-firefox
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF
    apt update
    apt install -y software-properties-common
    add-apt-repository -y -P mozillateam/ppa
    apt update
    apt install -y xfce4 xfce4-terminal xfce4-appfinder dbus-x11 pulseaudio-utils \
                   yaru-theme-gtk yaru-theme-icon fonts-ubuntu synaptic sudo \
                   whiptail thunar-archive-plugin firefox gcc pkg-config libgtk-3-dev \
                   xdotool scrot python3-gi gir1.2-gtk-3.0 bc
"

echo -e "${CYAN}[5/7] Mengaplikasikan Tweaks, Wallpaper Resmi & Icon Ubuntu...${NC}"
# Pasang wallpaper resmi Noble Numbat
proot-distro login ubuntu -- bash -c "
    mkdir -p /usr/share/backgrounds
    cp '$REPO_DIR/assets/wallpapers/warty-final-ubuntu.png' /usr/share/backgrounds/warty-final-ubuntu.png
    cp '$REPO_DIR/assets/wallpapers/warty-final-ubuntu.png' /usr/share/backgrounds/noble-numbat.png 2>/dev/null || true
    cp '$REPO_DIR/assets/wallpapers/warty-final-ubuntu.png' /usr/share/backgrounds/jammy-jellyfish.png 2>/dev/null || true
    
    # Pasang vector icon
    mkdir -p /usr/share/icons/hicolor/scalable/apps
    mkdir -p /usr/share/icons/Yaru/scalable/apps
    cp "$REPO_DIR"/assets/icons/*.svg /usr/share/icons/hicolor/scalable/apps/ 2>/dev/null || true
    cp "$REPO_DIR"/assets/icons/*.svg /usr/share/icons/Yaru/scalable/apps/ 2>/dev/null || true
    gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
    gtk-update-icon-cache -f /usr/share/icons/Yaru 2>/dev/null || true
"

echo -e "${CYAN}[6/7] Memasang Konfigurasi Panel (Dock), Window Manager & GTK...${NC}"
proot-distro login ubuntu -- bash -c "
    mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml
    mkdir -p /root/.config/xfce4/panel
    mkdir -p /root/.config/gtk-3.0
    mkdir -p /root/Android_Storage

    cp '$REPO_DIR/configs/xfce4-panel.xml' /root/.config/xfce4/xfconf/xfce-perchannel-xml/
    cp '$REPO_DIR/configs/xfwm4.xml' /root/.config/xfce4/xfconf/xfce-perchannel-xml/
    cp '$REPO_DIR/configs/xsettings.xml' /root/.config/xfce4/xfconf/xfce-perchannel-xml/
    cp '$REPO_DIR/configs/xfce4-desktop.xml' /root/.config/xfce4/xfconf/xfce-perchannel-xml/
    cp '$REPO_DIR/configs/xfce4-settings-manager.xml' /root/.config/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true
    cp '$REPO_DIR/configs/thunar.xml' /root/.config/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true

    mkdir -p /etc/xdg/xfce4/xfconf/xfce-perchannel-xml
    cp '$REPO_DIR/configs/xfce4-panel.xml' /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/
    cp '$REPO_DIR/configs/xfwm4.xml' /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/
    cp '$REPO_DIR/configs/xsettings.xml' /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/
    cp '$REPO_DIR/configs/xfce4-desktop.xml' /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/
    cp '$REPO_DIR/configs/xfce4-settings-manager.xml' /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true

    chmod -x /etc/X11/Xsession.d/90gpg-agent 2>/dev/null || true

    cp '$REPO_DIR/configs/gtk.css' /root/.config/gtk-3.0/
    cp '$REPO_DIR/configs/bookmarks' /root/.config/gtk-3.0/ 2>/dev/null || true
    cp '$REPO_DIR/configs/.Xresources' /root/.Xresources 2>/dev/null || true
    cp -r '$REPO_DIR/configs/panel_launchers/'* /root/.config/xfce4/panel/ 2>/dev/null || true

    # Pasang autostart status bar daemon
    mkdir -p /root/.config/autostart /etc/xdg/autostart
    cp '$REPO_DIR/configs/autostart/'* /root/.config/autostart/ 2>/dev/null || true
    cp '$REPO_DIR/configs/autostart/'* /etc/xdg/autostart/ 2>/dev/null || true

    # Pasang utilitas, daemon baterai, dan helper scripts ke /usr/local/bin
    mkdir -p /usr/local/bin
    cp '$REPO_DIR/bin/'* /usr/local/bin/ 2>/dev/null || true
    chmod +x /usr/local/bin/* 2>/dev/null || true

    # Kompilasi native interceptor libnogap (dock floating, gapless window, centered clock)
    mkdir -p /usr/local/src /usr/local/lib
    cp '$REPO_DIR/src/libnogap.c' /usr/local/src/libnogap.c
    gcc -O2 -shared -fPIC /usr/local/src/libnogap.c -o /usr/local/lib/libnogap.so \$(pkg-config --cflags --libs gtk+-3.0) 2>/dev/null || true

    # Pasang wrapper xfce4-panel agar selalu memuat libnogap
    if [ -f /usr/bin/xfce4-panel.bin ]; then
        :
    elif [ -f /usr/bin/xfce4-panel ]; then
        mv /usr/bin/xfce4-panel /usr/bin/xfce4-panel.bin
        cat << 'WRAPPER_EOF' > /usr/bin/xfce4-panel
#!/bin/bash
export LD_PRELOAD=/usr/local/lib/libnogap.so\${LD_PRELOAD:+:\$LD_PRELOAD}
exec /usr/bin/xfce4-panel.bin "\$@"
WRAPPER_EOF
        chmod +x /usr/bin/xfce4-panel
    fi

    cp '$REPO_DIR/scripts/start_desktop.sh' /root/start_desktop.sh
    chmod +x /root/start_desktop.sh

    cp '$REPO_DIR/scripts/shutdown_ubuntu.sh' /usr/local/bin/shutdown-ubuntu
    chmod +x /usr/local/bin/shutdown-ubuntu
"

echo -e "${CYAN}[7/7] Menyiapkan Script Peluncur Termux (~/launch_ubuntu.sh)...${NC}"
cp "$REPO_DIR/scripts/launch_ubuntu.sh" "$HOME/launch_ubuntu.sh"
chmod +x "$HOME/launch_ubuntu.sh"

# Shortcut bashrc
if ! grep -q "launch_ubuntu.sh" "$HOME/.bashrc" 2>/dev/null; then
    echo "alias ubuntu='bash ~/launch_ubuntu.sh'" >> "$HOME/.bashrc"
fi

echo -e "\n${GREEN}==============================================================================${NC}"
echo -e "${GREEN}🎉 INSTALASI UBROID BERHASIL DISELESAIKAN!${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo -e "Untuk menjalankan Ubuntu Desktop:"
echo -e "1. Install APK pendukung dari folder: ${YELLOW}$REPO_DIR/apks/${NC}"
echo -e "   - ${CYAN}termux-x11.apk${NC} (X11 Display Server)"
echo -e "   - ${CYAN}Ubuntu_Launcher.apk${NC} (Peluncur 1-Tap dari Homescreen Android)"
echo -e "2. Jalankan perintah di Termux: ${YELLOW}ubuntu${NC} (atau klik icon aplikasi Ubuntu di Android)"
echo -e "${GREEN}==============================================================================${NC}\n"
