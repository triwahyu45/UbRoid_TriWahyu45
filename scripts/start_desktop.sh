#!/bin/bash
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
export PULSE_LATENCY_MSEC=60
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_TYPE=x11
export LANG=C.UTF-8
export MOZ_USE_XINPUT2=1
export LP_NUM_THREADS=8
export VBLANK_MODE=0
export GALLIUM_DRIVER=llvmpipe
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLSL_VERSION_OVERRIDE=460
export GDK_CORE_DEVICE_EVENTS=1
export MALLOC_ARENA_MAX=2
export MALLOC_TRIM_THRESHOLD_=131072
export MALLOC_MMAP_THRESHOLD_=131072

if [ ! -f /etc/resolv.conf ] || ! grep -q "100.100.100.100" /etc/resolv.conf 2>/dev/null; then
    cat << "RESOLV" > /etc/resolv.conf
nameserver 100.100.100.100
nameserver 10.11.12.57
nameserver 10.100.1.3
nameserver 1.1.1.1
nameserver 8.8.8.8
options timeout:2 attempts:2
RESOLV
fi

# Prevent gpg-agent / ssh-agent / gnome-keyring / portal bloat in PRoot (saves ~10 process slots)
chmod -x /etc/X11/Xsession.d/90gpg-agent 2>/dev/null || true
pkill -9 -f "[g]pg-agent" 2>/dev/null || true
pkill -9 -f "[s]sh-agent" 2>/dev/null || true
pkill -9 -f "[g]nome-keyring" 2>/dev/null || true

# Enter Dedicated Linux OS Mode only if requested (from APK or --dedicated flag)
# CLI mode ('ubuntu' or 'u') defaults to Lightweight Co-existence Mode (keeps Android multitasking & notifications active)
if [ "$UBROID_DEDICATED_OS" = "1" ]; then
    chmod +x /usr/local/bin/linux-os-mode 2>/dev/null || true
    /usr/local/bin/linux-os-mode enter 2>/dev/null || true
fi

# Pre-seed konfigurasi profil touch sebelum DBus / xfconfd aktif
pkill -9 -x xfconfd 2>/dev/null || true
if [ -d "/sdcard/Download/ubroid_touch" ]; then
    mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml /root/.config/gtk-3.0 2>/dev/null || true
    cp -f /sdcard/Download/ubroid_touch/*.xml /root/.config/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true
    cp -f /sdcard/Download/ubroid_touch/*.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true
    cp -f /sdcard/Download/ubroid_touch/gtk.css /root/.config/gtk-3.0/gtk.css 2>/dev/null || true
fi

# Initialize user D-Bus session bus
eval $(dbus-launch --sh-syntax)
export DBUS_SESSION_BUS_ADDRESS
export DBUS_SESSION_BUS_PID
dbus-update-activation-environment --all 2>/dev/null || true

xrdb -merge /root/.Xresources 2>/dev/null || true
xsetroot -cursor_name left_ptr 2>/dev/null || true
rm -rf /root/.cache/sessions/* 2>/dev/null || true

# Safe Inset Bezel & Floating Rounded Dock via xfconf-query
xfconf-query -c xfce4-panel -p /panels/panel-1/length -t uint -s 100 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/size -t uint -s 35 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/icon-size -t uint -s 20 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/position -s "p=6;x=0;y=0" 2>/dev/null || true

xfconf-query -c xfce4-panel -p /panels/panel-2/length -t uint -s 84 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-2/size -t uint -s 54 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-2/icon-size -t uint -s 34 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-2/length-adjust -s false 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-2/position -s "p=10;x=0;y=0" 2>/dev/null || true

# Matikan software compositing di PRoot agar UI 60 FPS instan tanpa lag
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/show_dock_shadow -s false 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/show_frame_shadow -s false 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/show_popup_shadow -s false 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/move_opacity -s 100 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/resize_opacity -s 100 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/vblank_mode -s off 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/unredirect_overlays -s true 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/snap_resist -s true 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/snap_to_border -s true 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/snap_width -s 48 2>/dev/null || true

# Window Bounds Limiter disabled (causes X11 connection storm & input freezing)
# /usr/local/bin/window-bounds-limiter &


# Prevent unnecessary applets from crashing PRoot process table
chmod -x /etc/xdg/autostart/nm-applet.desktop /etc/xdg/autostart/print-applet.desktop 2>/dev/null || true
pkill -9 -f "nm-applet" 2>/dev/null || true
pkill -9 -f "system-config-printer" 2>/dev/null || true
pkill -f "/usr/local/bin/perf-governor" 2>/dev/null || true
pkill -f "/usr/local/bin/ram-guardian" 2>/dev/null || true

cleanup_on_exit() {
    pkill -9 -x onboard 2>/dev/null || true
    if [ "$UBROID_DEDICATED_OS" = "1" ]; then
        /usr/local/bin/linux-os-mode exit 2>/dev/null || true
    fi
}
trap cleanup_on_exit EXIT INT TERM HUP

# Anti-Rat Wallpaper Enforcement (Eliminate XFCE teal mouse fallback completely)
if [ -f "/sdcard/Download/ubuntu-touch-default.png" ]; then
    mkdir -p /usr/share/backgrounds/xfce /usr/share/xfce4/backdrops 2>/dev/null || true
    cp -f "/sdcard/Download/ubuntu-touch-default.png" /usr/share/backgrounds/ubuntu-touch-default.png 2>/dev/null || true
    cp -f "/sdcard/Download/ubuntu-touch-default.png" /usr/share/backgrounds/warty-final-ubuntu.png 2>/dev/null || true
    cp -f "/sdcard/Download/ubuntu-touch-default.png" /usr/share/backgrounds/noble-numbat.png 2>/dev/null || true
    cp -f "/sdcard/Download/ubuntu-touch-default.png" /usr/share/backgrounds/xfce/xfce-teal.png 2>/dev/null || true
    cp -f "/sdcard/Download/ubuntu-touch-default.png" /usr/share/backgrounds/xfce/xfce-blue.png 2>/dev/null || true
    cp -f "/sdcard/Download/ubuntu-touch-default.png" /usr/share/backgrounds/xfce/xfce-stripes.png 2>/dev/null || true
    find /usr/share/backgrounds -type f -name "*.png" -exec cp -f "/sdcard/Download/ubuntu-touch-default.png" {} \; 2>/dev/null || true
    find /usr/share/xfce4 -type f -name "*.png" -exec cp -f "/sdcard/Download/ubuntu-touch-default.png" {} \; 2>/dev/null || true
fi

UBUNTU_WP="/usr/share/backgrounds/ubuntu-noble-crowned-portrait.png"
[ ! -f "$UBUNTU_WP" ] && UBUNTU_WP="/usr/share/backgrounds/warty-final-ubuntu.png"
[ ! -f "$UBUNTU_WP" ] && UBUNTU_WP="/usr/share/backgrounds/ubuntu-touch-default.png"

# Ensure all desktop launchers are marked trusted in GIO/XFCE
chmod +x /root/Desktop/*.desktop 2>/dev/null || true
for f in /root/Desktop/*.desktop; do
    [ -f "$f" ] && gio set "$f" metadata::trusted true 2>/dev/null || true
done

# Sinkronisasi file script penting langsung ke Termux & PRoot
mkdir -p /etc/ubroid 2>/dev/null || true
echo "touch" > /etc/ubroid/mode 2>/dev/null || true

if [ -f "/sdcard/Download/linux-os-mode" ]; then
    cp -f "/sdcard/Download/linux-os-mode" /usr/local/bin/linux-os-mode 2>/dev/null || true
    chmod +x /usr/local/bin/linux-os-mode 2>/dev/null || true
fi

if [ -f "/sdcard/Download/toggle-keyboard" ]; then
    cp -f "/sdcard/Download/toggle-keyboard" /usr/local/bin/toggle-keyboard 2>/dev/null || true
    chmod +x /usr/local/bin/toggle-keyboard 2>/dev/null || true
fi

if [ -f "/sdcard/Download/toggle-gboard" ]; then
    cp -f "/sdcard/Download/toggle-gboard" /usr/local/bin/toggle-gboard 2>/dev/null || true
    chmod +x /usr/local/bin/toggle-gboard 2>/dev/null || true
fi

if [ -f "/sdcard/Download/status-bar-daemon" ]; then
    cp -f "/sdcard/Download/status-bar-daemon" /usr/local/bin/status-bar-daemon 2>/dev/null || true
    chmod +x /usr/local/bin/status-bar-daemon 2>/dev/null || true
fi

if [ -f "/sdcard/Download/smart-launch" ]; then
    cp -f "/sdcard/Download/smart-launch" /usr/local/bin/smart-launch 2>/dev/null || true
    chmod +x /usr/local/bin/smart-launch 2>/dev/null || true
fi

if [ -d "/root/termux_home" ] && [ -f "/sdcard/Download/launch_ubuntu.sh" ]; then
    cp -f "/sdcard/Download/launch_ubuntu.sh" "/root/termux_home/launch_ubuntu.sh" 2>/dev/null || true
    chmod +x "/root/termux_home/launch_ubuntu.sh" 2>/dev/null || true
fi

# Sinkronisasi profil touch terbaru jika ada di /sdcard/Download/ubroid_touch
if [ -d "/sdcard/Download/ubroid_touch" ]; then
    mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml /root/.config/gtk-3.0 /root/.config/xfce4/panel 2>/dev/null || true
    cp -f /sdcard/Download/ubroid_touch/*.xml /root/.config/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true
    cp -f /sdcard/Download/ubroid_touch/*.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/ 2>/dev/null || true
    cp -f /sdcard/Download/ubroid_touch/gtk.css /root/.config/gtk-3.0/gtk.css 2>/dev/null || true
    cp -rf /sdcard/Download/ubroid_touch/panel_launchers/* /root/.config/xfce4/panel/ 2>/dev/null || true
fi

# Pastikan DPI tajam dan proporsional untuk smartphone (125 DPI, Ubuntu 10)
xfconf-query -c xsettings -p /Xft/DPI -s 125 2>/dev/null || true
xfconf-query -c xsettings -p /Xfce/LastCustomDPI -s 125 2>/dev/null || true
xfconf-query -c xsettings -p /Gtk/FontName -s "Ubuntu 10" 2>/dev/null || true
xfconf-query -c xsettings -p /Gtk/MonospaceFontName -s "Ubuntu Mono 10" 2>/dev/null || true
xfconf-query -c xsettings -p /Gtk/CursorThemeSize -s 28 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/title_font -s "Ubuntu Bold 10" 2>/dev/null || true

# Anti-Pop Out Keyboard: Matikan total onboard & auto-popup
pkill -9 -x onboard 2>/dev/null || true
pkill -9 -f "onboard" 2>/dev/null || true
gsettings set org.onboard auto-show false 2>/dev/null || true
dconf write /org/onboard/auto-show false 2>/dev/null || true

# Optimasi Mobile UI Ubuntu Touch (Maximized windows khas Android/Lomiri & Bersihkan Desktop)
xfconf-query -c xfwm4 -p /general/placement_mode -s "maximized" 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/borderless_maximize -s true 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/title_alignment -s "center" 2>/dev/null || true
xfconf-query -c xfce4-desktop -p /desktop-icons/style -s 0 2>/dev/null || true

# Asynchronously enforce Ubuntu wallpaper on all monitors once XFCE starts
(
    sleep 1.2
    xfconf-query -c xfce4-desktop -p /desktop-icons/style -s 0 2>/dev/null || true
    for prop in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep 'last-image'); do
        xfconf-query -c xfce4-desktop -p "$prop" -s "$UBUNTU_WP" 2>/dev/null || true
    done
    for mon in monitorbuiltin monitor0 monitorscreen monitordefault monitorVirtual-0 monitorVirtual-1 monitorVirtual-2; do
        xfconf-query -c xfce4-desktop -p "/backdrop/screen0/$mon/workspace0/last-image" -s "$UBUNTU_WP" 2>/dev/null || true
        xfconf-query -c xfce4-desktop -p "/backdrop/screen0/$mon/workspace0/image-style" -s 5 2>/dev/null || true
    done
    for m in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep 'image-style'); do
        xfconf-query -c xfce4-desktop -p "$m" -s 5 2>/dev/null || true
    done

    # Safe Inset Bezel & Floating Rounded Dock via xfconf-query
    xfconf-query -c xfce4-panel -p /panels/panel-1/length -t uint -s 100 2>/dev/null || true
    xfconf-query -c xfce4-panel -p /panels/panel-1/size -t uint -s 35 2>/dev/null || true
    xfconf-query -c xfce4-panel -p /panels/panel-1/icon-size -t uint -s 20 2>/dev/null || true
    xfconf-query -c xfce4-panel -p /panels/panel-1/position -s "p=6;x=0;y=0" 2>/dev/null || true

    xfconf-query -c xfce4-panel -p /panels/panel-2/length -t uint -s 84 2>/dev/null || true
    xfconf-query -c xfce4-panel -p /panels/panel-2/size -t uint -s 54 2>/dev/null || true
    xfconf-query -c xfce4-panel -p /panels/panel-2/icon-size -t uint -s 34 2>/dev/null || true
    xfconf-query -c xfce4-panel -p /panels/panel-2/length-adjust -s false 2>/dev/null || true
    xfconf-query -c xfce4-panel -p /panels/panel-2/position -s "p=10;x=0;y=0" 2>/dev/null || true
    xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
    echo "gboard" > /etc/ubroid/keyboard_pref 2>/dev/null || true
) &

export LD_PRELOAD=/usr/local/lib/libnogap.so
startxfce4
unset LD_PRELOAD

cleanup_on_exit
