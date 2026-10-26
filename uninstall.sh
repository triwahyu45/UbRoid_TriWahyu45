#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# UbRoid - 1-Command Complete Uninstaller & Rollback Script
# Repository: https://github.com/triwahyu45/UbRoid_TriWahyu45
# Author: Tri Wahyu Handoyo (triwahyu45 / DetronicsID)
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${RED}"
cat << "EOF"
  _   _ _     ____       _     _ 
 | | | | |__ |  _ \ ___ (_) __| |
 | | | | '_ \| |_) / _ \| |/ _` |
 | |_| | |_) |  _ < (_) | | (_| |
  \___/|_.__/|_| \_\___/|_|\__,_|
  🗑️  UbRoid Complete Uninstaller & Android System Rollback
EOF
echo -e "${NC}"

echo -e "${YELLOW}[!] PERINGATAN: Skrip ini akan menghapus container Ubuntu UbRoid,"
echo -e "    membersihkan Termux, dan mengembalikan semua setelan Android.${NC}\n"

# Konfirmasi jika dijalankan secara interaktif di terminal
if [ -t 0 ]; then
    read -p "Apakah Anda yakin ingin menghapus UbRoid sepenuhnya? (y/N): " -r CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}[*] Pembatalan penghapusan. Tidak ada file yang diubah.${NC}"
        exit 0
    fi
fi

echo -e "${CYAN}[1/5] Menghentikan seluruh proses X11, PulseAudio & PRoot...${NC}"
/system/bin/am force-stop com.termux.x11 2>/dev/null || true
pkill -9 -f "termux-x11" 2>/dev/null || true
pkill -9 -x "pulseaudio" 2>/dev/null || true
pkill -9 -f "proot" 2>/dev/null || true
pkill -9 -f "xfce" 2>/dev/null || true
pkill -9 -f "dbus" 2>/dev/null || true
rm -rf "$PREFIX/tmp/.X*" "$PREFIX/tmp/.X11-unix" /data/data/com.termux/files/usr/tmp/.X* /data/data/com.termux/files/usr/tmp/.X11-unix 2>/dev/null || true

echo -e "${CYAN}[2/5] Memulihkan seluruh aplikasi Android & pengaturan sistem (ADB Rollback)...${NC}"
# Pulihkan aplikasi Android yang mungkin di-suspend oleh linux-os-mode
if command -v adb >/dev/null 2>&1; then
    adb connect 127.0.0.1:5555 >/dev/null 2>&1 || true
    DEV=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1; exit}')
    if [ -n "$DEV" ]; then
        adb -s "$DEV" shell "
            for p in \$(pm list packages -3 2>/dev/null | sed 's/package://'); do
                pm unsuspend --user 0 \"\$p\" 2>/dev/null || true
                am set-standby-bucket \"\$p\" active 2>/dev/null || true
            done
            settings put global hide_gesture_line 0 2>/dev/null || true;
            settings put global policy_control null 2>/dev/null || true;
            settings put global heads_up_notifications_enabled 1 2>/dev/null || true;
            cmd notification set_dnd off 2>/dev/null || true;
            device_config put activity_manager max_cached_processes 32 2>/dev/null || true;
            settings put secure voice_interaction_service com.google.android.googlequicksearchbox/com.google.android.voiceinteraction.GsaVoiceInteractionService 2>/dev/null || true;
            am start -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null || true;
        " >/dev/null 2>&1 || true
    fi
fi
# Non-root fallback restore
/system/bin/sh -c "settings put global hide_gesture_line 0; settings put global policy_control null; settings put global heads_up_notifications_enabled 1; cmd notification set_dnd off" 2>/dev/null || true

echo -e "${CYAN}[3/5] Menghapus container Ubuntu dari proot-distro...${NC}"
if command -v proot-distro >/dev/null 2>&1; then
    if proot-distro list 2>/dev/null | grep -q "^ubuntu\b.*installed"; then
        proot-distro remove ubuntu || true
        echo -e "${GREEN}✓ Container 'ubuntu' berhasil dihapus.${NC}"
    fi
    if proot-distro list 2>/dev/null | grep -q "ubuntu:24.04.*installed"; then
        proot-distro remove ubuntu:24.04 || true
        echo -e "${GREEN}✓ Container 'ubuntu:24.04' berhasil dihapus.${NC}"
    fi
fi

echo -e "${CYAN}[4/5] Membersihkan file peluncur, skrip & repository...${NC}"
rm -f "$HOME/launch_ubuntu.sh"
rm -f "$HOME/install_ubuntu_desktop.sh" "$HOME/setup_ubuntu_env.sh" "$HOME/setup_ubuntu_theme.sh" "$HOME/fix.sh" "$HOME/run_fix.sh" "$HOME/apply_dpi.sh" 2>/dev/null || true
rm -rf "$HOME/UbRoid_TriWahyu45"

echo -e "${CYAN}[5/5] Mengembalikan konfigurasi ~/.bashrc Termux ke default...${NC}"
cat << 'EOF' > "$HOME/.bashrc"
# Default Termux .bashrc
export PS1='\[\033[1;32m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\$ '
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
EOF

# Lepaskan WakeLock Termux jika ada
termux-wake-unlock 2>/dev/null || true

echo -e "\n${GREEN}==============================================================================${NC}"
echo -e "${GREEN}✓ UBROID BERHASIL DIHAPUS SEPENUHNYA DARI PERANGKAT!${NC}"
echo -e "${GREEN}==============================================================================${NC}"
echo -e "Sistem Android dan Termux telah dikembalikan ke kondisi awal (rollback sukses)."
echo -e "Jika tidak dibutuhkan lagi, Anda dapat meng-uninstall aplikasi pendukung:"
echo -e " - ${YELLOW}Ubuntu Launcher${NC}"
echo -e " - ${YELLOW}Termux-X11${NC}"
echo -e "${GREEN}==============================================================================${NC}\n"
