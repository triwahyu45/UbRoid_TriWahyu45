# Project Rules: UbRoid Synchronization Guidelines

## Core Commitment
Setiap kali ada perubahan, penyesuaian, perbaikan bug, atau penambahan fitur pada sistem Ubuntu ini—termasuk namun tidak terbatas pada:
1. **GUI & Desktop Customization:**
   - Panel XFCE (Panel 1 Top Bar, Panel 2 Bottom Dock) di `/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml`
   - Shortcut / Launcher `.desktop` di `/root/.config/xfce4/panel/`
   - Styling GTK3 di `/root/.config/gtk-3.0/gtk.css`
   - Window manager di `/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml`
   - Tema & DPI di `/root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml`
   - Wallpaper & icon desktop di `/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml`
2. **Native Interceptors & C Hooks:**
   - `/usr/local/src/libnogap.c` (geometry hints, dynamic spacer, dock positioning, arrow suppression)
3. **Scripts & Daemons:**
   - `/usr/local/bin/status-bar-daemon`, `dialog-*`, `status-*`
   - `/usr/local/bin/snap-layout`, `snap-edge-watcher`, `toggle-dock`, `toggle-keyboard`
   - `/usr/local/bin/linux-os-mode`, `ram-guardian`, `perf-governor`, `clean-ram`, `open-trash`
   - `/root/start_desktop.sh`, `/root/restart_panel.sh`
4. **Autostart Services:**
   - `/root/.config/autostart/status-bar-daemon.desktop`

---

## Automatic GitHub Synchronization Rule
**WAJIB**: Setelah melakukan perubahan atau pengujian pada komponen-komponen di atas, agen harus menjalankan sinkronisasi ke repositori GitHub resmi:
```bash
/usr/local/bin/sync-ubroid "<deskripsi singkat perubahan>"
```

### Aturan Keamanan & Privasi (Privacy Protection)
Script `/usr/local/bin/sync-ubroid` secara otomatis menyaring data sensitif, namun agen harus selalu memastikan:
- Tidak ada token API, password, SSH private key, atau file history yang dimasukkan ke repositori.
- Menggunakan placeholder IP generik (`192.168.1.100` / `-`) dan nama perangkat generik (`Android Device`).
- Repositori GitHub: `https://github.com/triwahyu45/UbRoid_TriWahyu45` (Branch `main`).
