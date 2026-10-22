#!/data/data/com.termux/files/usr/bin/bash
export PATH=/data/data/com.termux/files/usr/bin:$PATH
export TMPDIR=/data/data/com.termux/files/usr/tmp

# 1. Bersihkan proses dan socket lama
/system/bin/am force-stop com.termux.x11 2>/dev/null
pkill -9 -f "termux-x11" 2>/dev/null
killall -9 termux-x11 2>/dev/null
pkill -9 -f "xfce" 2>/dev/null
pkill -9 -f "proot" 2>/dev/null
pkill -9 -f "dbus" 2>/dev/null
rm -rf $TMPDIR/.X* $TMPDIR/.X11-unix 2>/dev/null
sleep 0.3
mkdir -p $TMPDIR/.X11-unix
chmod 1777 $TMPDIR/.X11-unix

# 2. Set preferensi Termux-X11 instan non-blocking
/system/bin/am broadcast --user 0 -a com.termux.x11.CHANGE_PREFERENCE -p com.termux.x11 \
  --es fullscreen true \
  --es hideCutout true \
  --es showAdditionalKbd false \
  --es displayResolutionMode scaled \
  --es displayScale 175 \
  --es forceOrientation landscape 2>/dev/null

# 3. Jalankan Termux-X11 display server
termux-x11 :0 -ac &

# 4. Tunggu socket X0 siap
for i in $(seq 1 30); do
    if [ -S "$TMPDIR/.X11-unix/X0" ] || [ -e "$TMPDIR/.X11-unix/X0" ]; then
        break
    fi
    sleep 0.1
done

# 5. Munculkan Termux-X11 ke layar
/system/bin/am broadcast --user 0 -a com.termux.x11.CmdEntryPoint.ACTION_START -p com.termux.x11 2>/dev/null

# 6. Pastikan DNS resolver disiapkan
cat << "RESOLV" > $TMPDIR/resolv.conf
nameserver 8.8.8.8
RESOLV

# 7. Jalankan Desktop XFCE Ubuntu dengan Full Akses Android Storage (/sdcard)
proot-distro login ubuntu \
  --bind $TMPDIR/.X11-unix:/tmp/.X11-unix \
  --bind /data/data/com.termux/files/home:/root/termux_home \
  --bind /sdcard:/sdcard \
  --bind /sdcard:/root/Android_Storage \
  --bind /storage/emulated/0:/storage/emulated/0 \
  --bind $TMPDIR/resolv.conf:/etc/resolv.conf \
  -- bash /root/start_desktop.sh

# 8. Sesi Shutdown: Bersihkan seluruh proses
/system/bin/am force-stop com.termux.x11 2>/dev/null
pkill -9 -f "termux-x11" 2>/dev/null
killall -9 termux-x11 2>/dev/null
pkill -9 -f "xfce" 2>/dev/null
pkill -9 -f "dbus" 2>/dev/null
rm -rf $TMPDIR/.X* $TMPDIR/.X11-unix 2>/dev/null

# 9. Tutup layar Termux-X11
/system/bin/am broadcast --user 0 -a com.termux.x11.ACTION_STOP -p com.termux.x11 2>/dev/null
exit 0
