#!/bin/bash
export DISPLAY=:0
export LD_PRELOAD=/usr/local/lib/libnogap.so
PID=$(pgrep -n xfce4-session 2>/dev/null || true)
if [ -n "$PID" ]; then
    for v in $(tr '\0' '\n' < /proc/$PID/environ | grep -E '^(DBUS_SESSION_BUS_ADDRESS|XAUTHORITY)='); do
        export "$v"
    done
fi

# Close all existing error windows
for id in $(xdotool search --name "Failed" 2>/dev/null); do
    xdotool windowclose $id 2>/dev/null || true
done
for id in $(xdotool search --name "Settings" 2>/dev/null); do
    xdotool windowclose $id 2>/dev/null || true
done

# Apply live xfwm4 and settings-manager properties
xfconf-query -c xfwm4 -p /general/tile_on_move -s true 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/snap_width -s 32 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/box_move -s false 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/box_resize -s false 2>/dev/null || true
xfconf-query -c xfce4-settings-manager -p /last/window-width -s 920 2>/dev/null || true
xfconf-query -c xfce4-settings-manager -p /last/window-height -s 620 2>/dev/null || true

# Kill panel and restart cleanly
pkill -9 -f "xfce4-panel.bin" 2>/dev/null || true
pkill -9 -x xfce4-panel 2>/dev/null || true
sleep 0.8
DISPLAY=:0 nohup xfce4-panel >/dev/null 2>&1 &
sleep 1

# Raise top panel above dock
for id in $(xdotool search --class xfce4-panel 2>/dev/null); do
    geo=$(xwininfo -id $id 2>/dev/null | grep -o "[0-9]*x[0-9]*+[0-9]*+[0-9]*")
    if echo "$geo" | grep -qE "x3[0-9]\+0\+0"; then
        xdotool windowraise $id 2>/dev/null
    fi
done

echo "PANEL AND XFWM4 RESTARTED CLEANLY"
