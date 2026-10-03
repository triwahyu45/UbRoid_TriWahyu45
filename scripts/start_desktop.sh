#!/bin/bash
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_TYPE=x11
export LANG=C.UTF-8

cat << "RESOLV" > /etc/resolv.conf
nameserver 100.100.100.100
nameserver 10.11.12.57
nameserver 10.100.1.3
nameserver 8.8.8.8
RESOLV

mkdir -p /run/dbus
rm -f /run/dbus/pid
dbus-daemon --system --fork 2>/dev/null

xrdb -merge /root/.Xresources 2>/dev/null
xsetroot -cursor_name left_ptr 2>/dev/null
rm -rf /root/.cache/sessions/* 2>/dev/null

/usr/sbin/sshd 2>/dev/null || true

# Ensure top panel stays elevated above left dock
(
  for i in $(seq 1 10); do
    sleep 1
    for id in $(xdotool search --class xfce4-panel 2>/dev/null); do
      geo=$(xwininfo -id $id 2>/dev/null | grep -o "[0-9]*x[0-9]*+[0-9]*+[0-9]*")
      if echo "$geo" | grep -q "x3[0-2]+0+0"; then
        xdotool windowraise $id 2>/dev/null
      fi
    done
  done
) &

exec dbus-launch --exit-with-session startxfce4
