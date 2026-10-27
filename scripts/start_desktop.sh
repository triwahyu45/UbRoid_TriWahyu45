#!/bin/bash
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
export PULSE_LATENCY_MSEC=60
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_TYPE=x11
export LANG=C.UTF-8
export MOZ_USE_XINPUT2=1
export NO_AT_BRIDGE=1
export LP_NUM_THREADS=4
export VBLANK_MODE=0
export MALLOC_ARENA_MAX=2
export MALLOC_TRIM_THRESHOLD_=131072
export MALLOC_MMAP_THRESHOLD_=131072

cat << "RESOLV" > /etc/resolv.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
options timeout:1 attempts:2 single-request-reopen
RESOLV

# Prevent gpg-agent / ssh-agent / gnome-keyring / portal bloat in PRoot (saves ~10 process slots)
chmod -x /etc/X11/Xsession.d/90gpg-agent 2>/dev/null || true
pkill -9 -f "[g]pg-agent" 2>/dev/null || true
pkill -9 -f "[s]sh-agent" 2>/dev/null || true
pkill -9 -f "[g]nome-keyring" 2>/dev/null || true

# Enter Dedicated Linux OS Mode & start PulseAudio Android bridge
chmod +x /usr/local/bin/linux-os-mode 2>/dev/null || true
/usr/local/bin/linux-os-mode enter

# Initialize user D-Bus session bus
eval $(dbus-launch --sh-syntax)
export DBUS_SESSION_BUS_ADDRESS
export DBUS_SESSION_BUS_PID
dbus-update-activation-environment --all 2>/dev/null || true

xrdb -merge /root/.Xresources 2>/dev/null || true
xsetroot -cursor_name left_ptr 2>/dev/null || true
rm -rf /root/.cache/sessions/* 2>/dev/null || true

# Lightweight Compositing: Enable ARGB transparency for clean rounded dock corners
# while disabling expensive frame/dock shadows, blur, and move opacity to eliminate drag lag
xfconf-query -c xfwm4 -p /general/use_compositing -s true 2>/dev/null || true
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


# Start Auto Performance Governor & Multi-Core Affinity Enforcer
pkill -f "/usr/local/bin/perf-governor" 2>/dev/null || true
/usr/local/bin/perf-governor &
PERF_GOV_PID=$!

# Start Proactive RAM Guardian Daemon (Anti-LMK / Anti-Freeze)
pkill -f "/usr/local/bin/ram-guardian" 2>/dev/null || true
/usr/local/bin/ram-guardian &
RAM_GUARDIAN_PID=$!

cleanup_on_exit() {
    kill "$BOUNDS_LIMITER_PID" 2>/dev/null || true
    pkill -f "/usr/local/bin/window-bounds-limiter" 2>/dev/null || true
    kill "$PERF_GOV_PID" 2>/dev/null || true
    pkill -f "/usr/local/bin/perf-governor" 2>/dev/null || true
    kill "$RAM_GUARDIAN_PID" 2>/dev/null || true
    pkill -f "/usr/local/bin/ram-guardian" 2>/dev/null || true
    /usr/local/bin/linux-os-mode exit 2>/dev/null || true
}
trap cleanup_on_exit EXIT INT TERM HUP

export LD_PRELOAD=/usr/local/lib/libnogap.so
startxfce4
unset LD_PRELOAD

cleanup_on_exit
