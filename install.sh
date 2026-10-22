#!/bin/bash
# ==============================================================================
# UbRoid GUI & System Installer (PRoot / In-Ubuntu mode)
# Repository: https://github.com/triwahyu45/UbRoid_TriWahyu45
# Author: Tri Wahyu Handoyo (triwahyu45)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== MEMASANG / MEMPERBARUI UBROID DESKTOP ENVIRONMENT ==="

# 1. Pastikan dependencies terpasang
apt-get update -y
apt-get install -y \
    xfce4 xfce4-panel xfwm4 xfce4-settings xfce4-terminal \
    yaru-theme-gtk yaru-theme-icon fonts-ubuntu \
    libgtk-3-dev gcc pkg-config xdotool scrot python3-gi \
    gir1.2-gtk-3.0 pulseaudio-utils dbus-x11 bc

# 2. Pasang wallpaper & icon resmi
mkdir -p /usr/share/backgrounds
cp "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/warty-final-ubuntu.png 2>/dev/null || true
cp "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/noble-numbat.png 2>/dev/null || true
cp "$SCRIPT_DIR/assets/wallpapers/warty-final-ubuntu.png" /usr/share/backgrounds/jammy-jellyfish.png 2>/dev/null || true

mkdir -p /usr/share/icons/hicolor/scalable/apps /usr/share/icons/Yaru/scalable/apps
cp "$SCRIPT_DIR"/assets/icons/*.svg /usr/share/icons/hicolor/scalable/apps/ 2>/dev/null || true
cp "$SCRIPT_DIR"/assets/icons/*.svg /usr/share/icons/Yaru/scalable/apps/ 2>/dev/null || true
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
gtk-update-icon-cache -f /usr/share/icons/Yaru 2>/dev/null || true

# 3. Pasang konfigurasi XFCE, GTK, Panel, dan Launchers
mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml
mkdir -p /root/.config/xfce4/panel
mkdir -p /root/.config/gtk-3.0
mkdir -p /root/.config/autostart
mkdir -p /etc/xdg/xfce4/xfconf/xfce-perchannel-xml
mkdir -p /etc/xdg/autostart

cp "$SCRIPT_DIR/configs/xfce4-panel.xml" /root/.config/xfce4/xfconf/xfce-perchannel-xml/
cp "$SCRIPT_DIR/configs/xfwm4.xml" /root/.config/xfce4/xfconf/xfce-perchannel-xml/
cp "$SCRIPT_DIR/configs/xsettings.xml" /root/.config/xfce4/xfconf/xfce-perchannel-xml/
cp "$SCRIPT_DIR/configs/xfce4-desktop.xml" /root/.config/xfce4/xfconf/xfce-perchannel-xml/
cp "$SCRIPT_DIR/configs/xfce4-settings-manager.xml" /root/.config/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true
cp "$SCRIPT_DIR/configs/thunar.xml" /root/.config/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true

cp "$SCRIPT_DIR/configs/xfce4-panel.xml" /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/
cp "$SCRIPT_DIR/configs/xfwm4.xml" /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/
cp "$SCRIPT_DIR/configs/xsettings.xml" /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/
cp "$SCRIPT_DIR/configs/xfce4-desktop.xml" /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/
cp "$SCRIPT_DIR/configs/xfce4-settings-manager.xml" /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true

cp "$SCRIPT_DIR/configs/gtk.css" /root/.config/gtk-3.0/
cp "$SCRIPT_DIR/configs/bookmarks" /root/.config/gtk-3.0/ 2>/dev/null || true
cp "$SCRIPT_DIR/configs/.Xresources" /root/.Xresources 2>/dev/null || true
cp -r "$SCRIPT_DIR/configs/panel_launchers/"* /root/.config/xfce4/panel/ 2>/dev/null || true

# 4. Pasang autostart
cp "$SCRIPT_DIR/configs/autostart/"* /root/.config/autostart/ 2>/dev/null || true
cp "$SCRIPT_DIR/configs/autostart/"* /etc/xdg/autostart/ 2>/dev/null || true

# 5. Pasang script executables ke /usr/local/bin
mkdir -p /usr/local/bin
cp "$SCRIPT_DIR/bin/"* /usr/local/bin/ 2>/dev/null || true
chmod +x /usr/local/bin/* 2>/dev/null || true

# 6. Kompilasi libnogap.so
mkdir -p /usr/local/src /usr/local/lib
cp "$SCRIPT_DIR/src/libnogap.c" /usr/local/src/libnogap.c
gcc -O2 -shared -fPIC /usr/local/src/libnogap.c -o /usr/local/lib/libnogap.so $(pkg-config --cflags --libs gtk+-3.0) 2>/dev/null || true

# 7. Wrapper xfce4-panel
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

cp "$SCRIPT_DIR/scripts/start_desktop.sh" /root/start_desktop.sh
chmod +x /root/start_desktop.sh
cp "$SCRIPT_DIR/scripts/shutdown_ubuntu.sh" /usr/local/bin/shutdown-ubuntu
chmod +x /usr/local/bin/shutdown-ubuntu

# 8. Restart panel jika desktop sedang aktif
if pgrep -x xfce4-panel >/dev/null 2>&1 || pgrep -f xfce4-panel.bin >/dev/null 2>&1; then
    /usr/local/bin/restart_panel.sh 2>/dev/null || true
fi

echo "✓ UbRoid Desktop Environment berhasil dipasang dan dikonfigurasi!"
