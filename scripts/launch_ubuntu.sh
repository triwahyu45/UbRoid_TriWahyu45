#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# UbRoid - Ubuntu 24.04 LTS Launcher for Android
# Repository: https://github.com/triwahyu45/UbRoid_TriWahyu45
# Author: Tri Wahyu Handoyo (triwahyu45)
# ==============================================================================

export PATH=/data/data/com.termux/files/usr/bin:$PATH
export TMPDIR=/data/data/com.termux/files/usr/tmp
mkdir -p "$TMPDIR"

# Kunci port Wireless ADB 5555 agar selalu standby untuk PC/Tailscale
/system/bin/setprop service.adb.tcp.port 5555 2>/dev/null || true

# 1. Deteksi container Ubuntu (ubuntu atau ubuntu:24.04)
UBUNTU_CONTAINER="ubuntu"
if ! proot-distro list 2>/dev/null | grep -q "^ubuntu\b.*installed"; then
    if proot-distro list 2>/dev/null | grep -q "ubuntu:24.04.*installed"; then
        UBUNTU_CONTAINER="ubuntu:24.04"
    fi
fi

# Mode Selection:
# - Default CLI ('ubuntu' / 'u'): Co-existence / Lightweight Mode (Android apps & notifications remain active)
# - APK / Dedicated ('ubuntu --dedicated' / 'ubuntu --os'): Dedicated Linux OS Mode (leaves Android, suspends apps, DND on)
UBROID_DEDICATED_OS=0
for arg in "$@"; do
    case "$arg" in
        --dedicated|--os|--leave-android|--apk|-d)
            UBROID_DEDICATED_OS=1
            ;;
        --coexist|--light|-c)
            UBROID_DEDICATED_OS=0
            ;;
    esac
done
if [ "$UBROID_LAUNCH_SOURCE" = "apk" ] || [ "$UBROID_LAUNCHER_APK" = "1" ]; then
    UBROID_DEDICATED_OS=1
fi
export UBROID_DEDICATED_OS

restore_android_mode() {
    # 1. Kembalikan mode Android hanya jika sebelumnya masuk ke mode Dedicated OS
    if [ "$UBROID_DEDICATED_OS" = "1" ]; then
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
                    settings put secure voice_interaction_service com.google.android.googlequicksearchbox/com.google.android.voiceinteraction.GsaVoiceInteractionService;
                    for p in \$(pm list packages -3 2>/dev/null | sed 's/package://'); do
                        pm unsuspend --user 0 \"\$p\" 2>/dev/null || true
                        am set-standby-bucket \"\$p\" active 2>/dev/null || true
                    done
                " >/dev/null 2>&1 || true
            fi
        fi
        /system/bin/sh -c "settings put global hide_gesture_line 0; settings put global policy_control null; settings put global heads_up_notifications_enabled 1; cmd notification set_dnd off" >/dev/null 2>&1 || true
    fi

    # 2. Matikan X11, PulseAudio, dan daemon Linux
    /system/bin/am force-stop com.termux.x11 2>/dev/null
    pkill -9 -f "termux-x11" 2>/dev/null
    killall -9 termux-x11 2>/dev/null
    pkill -9 -x "pulseaudio" 2>/dev/null
    pkill -9 -f "xfce" 2>/dev/null
    pkill -9 -f "dbus" 2>/dev/null
    rm -rf $TMPDIR/.X* $TMPDIR/.X11-unix 2>/dev/null

    # 3. Lepas WakeLock & tutup jendela Termux-X11
    termux-wake-unlock 2>/dev/null || true
    /system/bin/am broadcast --user 0 -a com.termux.x11.ACTION_STOP -p com.termux.x11 2>/dev/null
}

trap restore_android_mode EXIT INT TERM

# 2. Bersihkan proses dan socket lama
/system/bin/am force-stop com.termux.x11 2>/dev/null
pkill -9 -f "termux-x11" 2>/dev/null
killall -9 termux-x11 2>/dev/null
pkill -9 -x "pulseaudio" 2>/dev/null
pkill -9 -f "xfce" 2>/dev/null
pkill -9 -f "proot" 2>/dev/null
pkill -9 -f "dbus" 2>/dev/null
rm -rf $TMPDIR/.X* $TMPDIR/.X11-unix 2>/dev/null
sleep 0.3
mkdir -p $TMPDIR/.X11-unix
chmod 1777 $TMPDIR/.X11-unix

# 3. Aktifkan WakeLock & Audio Server PulseAudio (OpenSL ES Speaker Bridge)
termux-wake-lock 2>/dev/null || true
if [ -x "/data/data/com.termux/files/usr/bin/pulseaudio" ]; then
    env -i HOME=/data/data/com.termux/files/home PREFIX=/data/data/com.termux/files/usr PATH=/data/data/com.termux/files/usr/bin:/system/bin TMPDIR=/data/data/com.termux/files/usr/tmp \
        /data/data/com.termux/files/usr/bin/pulseaudio --start \
        --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
        --exit-idle-time=-1 2>/dev/null || true
fi

# 4. Deteksi Densitas Layar & Skala Otomatis (Dynamic Resolution & Scale for Phones & Tablets)
DENSITY=$(/system/bin/dumpsys display 2>/dev/null | grep -o 'density [0-9]*' | head -n1 | awk '{print $2}')
if [ -z "$DENSITY" ] || [ "$DENSITY" -le 0 ] 2>/dev/null; then
    DENSITY=240
fi
SCALE=$(( (DENSITY * 100) / 160 ))
if [ "$SCALE" -lt 120 ]; then
    SCALE=120
elif [ "$SCALE" -gt 320 ]; then
    SCALE=320
fi

# 5. Deteksi Orientasi Layar (Ubuntu Touch = PORTRAIT vertikal khas HP smartphone, Desktop = LANDSCAPE)
TARGET_ORIENTATION="portrait"
ROOTFS_MODE_FILE="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/$UBUNTU_CONTAINER/etc/ubroid/mode"
UBROID_MODE="touch"
if [ -f "$ROOTFS_MODE_FILE" ]; then
    UBROID_MODE=$(cat "$ROOTFS_MODE_FILE" 2>/dev/null | tr -d '[:space:]')
fi
if [ "$UBROID_MODE" = "desktop" ]; then
    TARGET_ORIENTATION="landscape"
fi

for arg in "$@"; do
    case "$arg" in
        --portrait|-p)
            TARGET_ORIENTATION="portrait"
            ;;
        --landscape|-l)
            TARGET_ORIENTATION="landscape"
            ;;
        --sensor|-s)
            TARGET_ORIENTATION="sensor"
            ;;
    esac
done

# Optimalisasi Skala Tampilan Khusus Smartphone Portrait (POCO F6)
if [ "$TARGET_ORIENTATION" = "portrait" ] && [ "$SCALE" -gt 240 ]; then
    SCALE=220
fi

# 6. Set preferensi Termux-X11 ke Mode Dedicated Linux OS + Native Direct Touch
/system/bin/am broadcast --user 0 -a com.termux.x11.CHANGE_PREFERENCE -p com.termux.x11 \
  --es fullscreen true \
  --es hideCutout true \
  --es screenIdleTimeout "Never (keep screen on)" \
  --es PIP false \
  --es dexMetaKeyCapture true \
  --es filterOutWinkey true \
  --es showAdditionalKbd false \
  --es displayResolutionMode scaled \
  --es displayScale $SCALE \
  --es forceOrientation "$TARGET_ORIENTATION" \
  --es touchMode "Direct touch" \
  --es swipeUpAction "toggle soft keyboard" \
  --es backButtonAction "toggle soft keyboard" \
  --es swipeDownAction "toggle additional key bar" \
  --es notificationButton0Action "toggle soft keyboard" \
  --es volumeUpAction "no action" \
  --es volumeDownAction "no action" \
  --es mediaKeysAction "send media action" 2>/dev/null

# 6. Jalankan Termux-X11 display server
termux-x11 :0 -ac &

# 7. Tunggu socket X0 siap
for i in $(seq 1 30); do
    if [ -S "$TMPDIR/.X11-unix/X0" ] || [ -e "$TMPDIR/.X11-unix/X0" ]; then
        break
    fi
    sleep 0.1
done

# 8. Munculkan Termux-X11 ke layar
/system/bin/am broadcast --user 0 -a com.termux.x11.CmdEntryPoint.ACTION_START -p com.termux.x11 2>/dev/null
/system/bin/am start -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null || true

# 9. Pastikan DNS resolver disiapkan (Multi-tier Android Network DNS + Fallback)
DNS_LIST=()
# Prioritaskan Tailscale MagicDNS & DNS kampus/internal jika terhubung (Anti-blokir eduroam UNY port 53)
DNS_LIST+=("100.100.100.100" "10.11.12.57" "10.100.1.3")
for prop in net.dns1 net.dns2 net.dns3 net.dns4 net.wlan0.dns1 net.wlan0.dns2 net.rmnet_data0.dns1; do
    d=$(getprop "$prop" 2>/dev/null)
    [ -n "$d" ] && DNS_LIST+=("$d")
done
GW=$(ip route show 2>/dev/null | awk '/default/ {print $3}' | head -n1)
[ -n "$GW" ] && DNS_LIST+=("$GW")
for d in $(/system/bin/dumpsys connectivity 2>/dev/null | grep -o 'DnsAddresses: \[ [^]]* \]' | tr -d '[]/' | tr ',' ' '); do
    [ "$d" != "DnsAddresses:" ] && DNS_LIST+=("$d")
done
DNS_LIST+=("8.8.8.8" "1.1.1.1" "8.8.4.4" "9.9.9.9")

> "$TMPDIR/resolv.conf"
for d in "${DNS_LIST[@]}"; do
    if ! grep -q "nameserver $d" "$TMPDIR/resolv.conf" 2>/dev/null; then
        echo "nameserver $d" >> "$TMPDIR/resolv.conf"
    fi
done

# 10. Siapkan Binding Direktori yang Aman & Fleksibel (Anti-Crash jika /sdcard tidak ada)
PROOT_BINDS=()
[ -d "$TMPDIR/.X11-unix" ] && PROOT_BINDS+=(--bind "$TMPDIR/.X11-unix:/tmp/.X11-unix")
[ -d "/data/data/com.termux/files/home" ] && PROOT_BINDS+=(--bind "/data/data/com.termux/files/home:/root/termux_home")
[ -f "$TMPDIR/resolv.conf" ] && PROOT_BINDS+=(--bind "$TMPDIR/resolv.conf:/etc/resolv.conf")

# Deteksi Penyimpanan Android yang Benar-Benar Ada di HP
STORAGE_TARGET=""
if [ -d "/sdcard" ] && [ -r "/sdcard" ]; then
    STORAGE_TARGET="/sdcard"
elif [ -d "/storage/emulated/0" ] && [ -r "/storage/emulated/0" ]; then
    STORAGE_TARGET="/storage/emulated/0"
elif [ -d "$HOME/storage/shared" ] && [ -r "$HOME/storage/shared" ]; then
    STORAGE_TARGET="$HOME/storage/shared"
fi

if [ -n "$STORAGE_TARGET" ]; then
    PROOT_BINDS+=(--bind "$STORAGE_TARGET:/root/Android_Storage")
fi

# 11. Jalankan Desktop XFCE Ubuntu dengan Dynamic Storage Binding
proot-distro login "$UBUNTU_CONTAINER" "${PROOT_BINDS[@]}" -- env UBROID_DEDICATED_OS="$UBROID_DEDICATED_OS" bash /root/start_desktop.sh
