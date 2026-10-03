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

exec dbus-launch --exit-with-session startxfce4
