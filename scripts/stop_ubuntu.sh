#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# UbRoid - Stop Ubuntu & Restore Android Environment
# Repository: https://github.com/triwahyu45/UbRoid_TriWahyu45
# Author: Tri Wahyu Handoyo (DetronicsID)
# ==============================================================================

echo -e "\033[1;33m[*] Menghentikan sesi Ubuntu & memulihkan mode Android...\033[0m"

# 1. Pulihkan konfigurasi Android
if command -v adb >/dev/null 2>&1; then
    adb connect 127.0.0.1:5555 >/dev/null 2>&1 || true
    dev=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1; exit}')
    if [ -n "$dev" ]; then
        adb -s "$dev" shell "
            settings put global hide_gesture_line 0;
            settings put global policy_control null;
            settings put global heads_up_notifications_enabled 1;
            cmd notification set_dnd off;
            device_config put activity_manager max_cached_processes 32;
            for p in \$(pm list packages -3 2>/dev/null | sed 's/package://'); do
                pm unsuspend --user 0 \"\$p\" 2>/dev/null || true
                am set-standby-bucket \"\$p\" active 2>/dev/null || true
            done
        " >/dev/null 2>&1 || true
    fi
fi
/system/bin/sh -c "settings put global hide_gesture_line 0; settings put global policy_control null; settings put global heads_up_notifications_enabled 1; cmd notification set_dnd off" >/dev/null 2>&1 || true

# 2. Hentikan aplikasi Termux-X11, PulseAudio, dan proses PRoot/XFCE
/system/bin/am force-stop com.termux.x11 2>/dev/null || true
pkill -9 -f "termux-x11" 2>/dev/null || true
killall -9 termux-x11 2>/dev/null || true
pkill -9 -x "pulseaudio" 2>/dev/null || true
pkill -9 -f "xfce" 2>/dev/null || true
pkill -9 -f "proot" 2>/dev/null || true
pkill -9 -f "dbus" 2>/dev/null || true
rm -rf /data/data/com.termux/files/usr/tmp/.X* /data/data/com.termux/files/usr/tmp/.X11-unix 2>/dev/null || true

# 3. Lepas WakeLock & kirim ACTION_STOP ke Termux-X11
termux-wake-unlock 2>/dev/null || true
/system/bin/am broadcast --user 0 -a com.termux.x11.ACTION_STOP -p com.termux.x11 2>/dev/null || true

echo -e "\033[1;32m[✓] Ubuntu berhasil dihentikan. Mode Android telah dipulihkan ke normal.\033[0m"
