#!/bin/bash
# ==============================================================================
# UbRoid - Graceful Shutdown Script
# ==============================================================================

echo "Mematikan Desktop Ubuntu & Kembali ke Android..."
xfce4-session-logout --logout --fast 2>/dev/null || true
sleep 0.5
pkill -9 -f xfce4-session 2>/dev/null || true
pkill -9 -f xfce4-panel 2>/dev/null || true
pkill -9 -f xfwm4 2>/dev/null || true
pkill -9 -f xfsettingsd 2>/dev/null || true
