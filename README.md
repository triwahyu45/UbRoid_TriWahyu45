# ⚡ UbRoid — Ubuntu 24.04 LTS (Noble Numbat) for Android

<p align="center">
  <img src="assets/screenshots/ubuntu_desktop_clean.png" alt="UbRoid Desktop Preview" width="95%" style="border-radius: 12px; box-shadow: 0 8px 30px rgba(0,0,0,0.5);">
</p>

<p align="center">
  <b>Nikmati pengalaman Desktop Ubuntu 24.04 LTS yang otentik, stabil, dan siap pakai langsung di tablet & ponsel Android Anda.</b><br>
  <i>Lengkap dengan dock kiri khas Ubuntu, wallpaper resmi Noble Numbat, scaling 1.75x proporsional, 0% flickering, dan launcher native 1-tap Android.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Ubuntu-24.04%20LTS%20Noble%20Numbat-E95420?style=for-the-badge&logo=ubuntu&logoColor=white" alt="Ubuntu Version">
  <img src="https://img.shields.io/badge/Architecture-ARM64%20%2F%20aarch64-0078D4?style=for-the-badge&logo=arm&logoColor=white" alt="Arch">
  <img src="https://img.shields.io/badge/Desktop-XFCE4%20Ubuntu%20Style-2C001E?style=for-the-badge&logo=xfce&logoColor=white" alt="Desktop">
  <img src="https://img.shields.io/badge/Tested%20Device-Redmi%20Pad%202-00F5D4?style=for-the-badge&logo=android&logoColor=black" alt="Device">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
</p>

---

## 🌟 Fitur Utama (Key Highlights)

- 🎨 **Tampilan Otentik Ubuntu Desktop**: Wallpaper resmi **Ubuntu Noble Numbat** ungu mascot (`warty-final-ubuntu.png`), tema Yaru-dark, dan font Ubuntu yang tajam.
- 🚀 **Dock Bawah Melayang & Live Tasklist**: Dock autohide melayang (mengambang di atas navigation gesture bar Android) dengan pemisah vertikal elegan, pinned apps, dan **indikator tab jendela aktif live** (seperti Terminator, Browser, File Manager) lengkap dengan highlight garis oranye Ubuntu.
- ⚡ **Status Bar Atas Lengkap & Jam Presisi di Tengah**: Panel atas 36px dengan jam otomatis presisi di tengah layar (dynamic spacer) serta 8 icon utilitas lengkap di sebelah kanan:
  1. 🪟 **Snap Layout Helper**: Pilihan tata letak split-screen & kuadran cepat.
  2. 🖥️ **Dock Toggle**: Tampilkan / sembunyikan dock dengan 1 klik.
  3. ⌨️ **On-screen Keyboard**: Toggle cepat keyboard virtual Onboard.
  4. 📶 **Wi-Fi Manager**: Status sinyal live & dialog koneksi Wi-Fi GTK3.
  5. ᛒ **Bluetooth Manager**: Status & dialog pengaturan Bluetooth.
  6. 🔊 **Volume Control**: Slider volume audio cepat via dialog GTK3.
  7. 🔋 **Live Battery Status**: Indikator baterai real-time menampilkan persentase teks, status charging (⚡), warna dinamis, dan dialog info baterai (suhu, voltase).
  8. ⏻ **Power Menu**: Dialog logout, restart, dan shutdown bersih.
- 🛠️ **Native Interceptor (`libnogap.c`)**: Interceptor C level GTK untuk meniadakan window resize gaps pada terminal, mengunci posisi floating dock di atas Android navigation bar, dan merapikan layout panel.
- 🛡️ **Anti-Freeze & Anti-LMK Protection**: Dilengkapi `ram-guardian` dan `perf-governor` otomatis untuk menjaga multitasking tetap lancar tanpa terhenti oleh sistem Android.
- 📱 **Launcher Native 1-Tap (`Ubuntu_Launcher.apk`)**: Cukup tap icon Ubuntu di homescreen Android Anda, sesi Ubuntu akan otomatis berjalan di background dan langsung membuka desktop tanpa perlu membuka terminal Termux manual.
- 📁 **Integrasi Penyimpanan Internal Android**: Akses langsung folder `/sdcard`, Download, dan foto tablet melalui shortcut **Android Storage** di file manager Thunar.

---

## 📦 Isi Folder Repository

```
UbRoid_TriWahyu45/
├── install.sh                     # Installer otomatis 1-klik (dijalankan di dalam PRoot Ubuntu)
├── bin/                           # Daemon & helper scripts (/usr/local/bin)
│   ├── status-bar-daemon          # Daemon live baterai & icon status
│   ├── dialog-battery             # Dialog pop-up status baterai GTK3
│   ├── dialog-wifi                # Dialog Wi-Fi GTK3
│   ├── dialog-bluetooth           # Dialog Bluetooth GTK3
│   ├── dialog-volume              # Dialog Volume slider GTK3
│   ├── snap-layout                # Menu snap layout jendela
│   ├── ram-guardian               # Anti-LMK memory guardian
│   └── perf-governor              # Pengatur performa & multi-core affinity
├── src/                           # Native C hooks
│   ├── libnogap.c                 # Hook geometry window, floating dock, & arrow suppression
│   └── Makefile                   # Build script libnogap.so
├── configs/                       # Konfigurasi desktop siap pakai
│   ├── xfce4-panel.xml            # Top Bar & Floating Dock
│   ├── xfwm4.xml                  # Window Manager anti-glitch
│   ├── xsettings.xml              # Scaling DPI & Tema Yaru-dark
│   ├── xfce4-desktop.xml          # Background wallpaper Ubuntu ungu
│   ├── gtk.css                    # Styling dock & active window tabs
│   ├── autostart/                 # Autostart status-bar-daemon
│   └── panel_launchers/           # Shortcut launchers & icon dock
├── scripts/
│   ├── setup_ubroid.sh            # Script instalasi lengkap dari Termux
│   ├── launch_ubuntu.sh           # Peluncur sesi Termux -> Termux-X11
│   ├── start_desktop.sh           # Inisialisasi sesi desktop di PRoot
│   └── shutdown_ubuntu.sh         # Skrip mematikan sesi dengan bersih
├── apks/                          # APK pendukung siap install
│   ├── Ubuntu_Launcher.apk        # Peluncur 1-Tap native Android
│   ├── termux-app.apk             # Termux base build teruji
│   └── termux-x11.apk             # Display server X11 untuk Android
└── assets/
    ├── wallpapers/                # Wallpaper resmi Ubuntu Noble Numbat
    ├── icons/                     # Vector icons resmi Firefox & Chrome
    └── screenshots/               # Screenshot preview desktop, top bar, & dock
```

---

## 🚀 Cara Instalasi Cepat (Otomatis 1 Baris)

### Langkah 1: Pasang APK Pendukung
Download dan pasang ketiga APK dari folder [`apks/`](apks/):
1. [`termux-app.apk`](apks/termux-app.apk)
2. [`termux-x11.apk`](apks/termux-x11.apk)
3. [`Ubuntu_Launcher.apk`](apks/Ubuntu_Launcher.apk)

### Langkah 2: Jalankan Script Instalasi di Termux
Buka aplikasi **Termux**, salin dan tempel perintah berikut:

```bash
curl -sL https://raw.githubusercontent.com/triwahyu45/UbRoid_TriWahyu45/main/scripts/setup_ubroid.sh | bash
```

Script akan otomatis:
- Memperbarui paket Termux & memasang `proot-distro`, `x11-repo`, `pulseaudio`.
- Mengunduh dan memasang container **Ubuntu 24.04 LTS (Noble Numbat)**.
- Memasang XFCE4, tema Yaru-dark, font Ubuntu, dan dependensi desktop.
- Mengaplikasikan wallpaper ungu resmi, icon vektor resolusi tinggi, konfigurasi dock kiri, dan pengaturan anti-flickering.
- Menyiapkan izin aplikasi eksternal agar launcher APK berfungsi secara instan.

### Langkah 3: Menjalankan Ubuntu Desktop
Anda dapat menjalankan Ubuntu dengan salah satu cara berikut:
- **Cara 1 (Paling Mudah)**: Klik icon aplikasi **Ubuntu** di homescreen Android Anda.
- **Cara 2 (Lewat Terminal)**: Buka Termux, lalu ketik `ubuntu` dan tekan Enter.

---

## 🛠️ Panduan Instalasi Manual (Step-by-Step)

Jika ingin melakukan instalasi secara manual langkah demi langkah:

### 1. Persiapan Termux & Dependencies
```bash
pkg update -y
pkg install -y proot-distro x11-repo pulseaudio wget git
mkdir -p ~/.termux
echo "allow-external-apps = true" >> ~/.termux/termux.properties
```

### 2. Pasang Rootfs Ubuntu
```bash
proot-distro install ubuntu
```

### 3. Masuk ke Ubuntu & Pasang Desktop
```bash
proot-distro login ubuntu
apt update
apt install -y xfce4 xfce4-terminal xfce4-appfinder dbus-x11 pulseaudio-utils \
               yaru-theme-gtk yaru-theme-icon fonts-ubuntu synaptic sudo
exit
```

### 4. Salin Konfigurasi & Script Peluncur
Clone repository ini ke Termux:
```bash
git clone https://github.com/triwahyu45/UbRoid_TriWahyu45.git ~/UbRoid_TriWahyu45
bash ~/UbRoid_TriWahyu45/scripts/setup_ubroid.sh
```

---

## ⚙️ Tweak & Tips Penggunaan

### 1. Mengubah Skala Layar (Display Scale)
Secara default, skala disetel ke **1.75x (`displayScale 175`)** yang sangat pas untuk layar tablet resolusi 2K (seperti Redmi Pad 2, Mi Pad, Samsung Tab). Jika Anda ingin mengubahnya:
- Buka file `~/launch_ubuntu.sh` di Termux.
- Ubah baris `--es displayScale 175` menjadi nilai yang diinginkan (misal `150` untuk 1.5x atau `200` untuk 2.0x).
- Di dalam Ubuntu, Anda juga dapat menyetel DPI di file `/root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml` pada properti `DPI`.

### 2. Mematikan Sesi Secara Bersih
- Klik icon **Shutdown / Power** di panel kanan atas, atau
- Klik shortcut merah di desktop, atau ketik perintah `shutdown-ubuntu` di terminal.
- Sesi X11 dan PRoot akan ditutup secara aman tanpa meninggalkan proses menggantung di latar belakang.

### 3. Izin Akses File Tablet (Storage)
UbRoid otomatis me-mount direktori Android `/sdcard` ke `/root/Android_Storage`. Untuk memastikan Termux memiliki izin storage:
```bash
termux-setup-storage
```
Tekan **Allow** / **Izinkan** pada jendela pop-up Android.

### 4. Mencegah Termux Dimatikan oleh Sistem (Battery Saver)
Agar performa maksimal dan sesi tidak terputus saat berpindah aplikasi:
- Buka **Settings Android** -> **Apps** -> **Termux** & **Termux-X11**.
- Set **Battery Saver** ke **No Restrictions** (Tanpa Pembatasan).

---

## 👨‍💻 Author & Pengembang

Dikembangkan dan dirawat dengan teliti oleh:
- **Tri Wahyu Handoyo**
- GitHub: [@triwahyu45](https://github.com/triwahyu45)
- Email: [handoyotriwahyu@gmail.com](mailto:handoyotriwahyu@gmail.com)
- Portofolio: [triwahyu45.github.io/Portofolio](https://triwahyu45.github.io/Portofolio/)

---

## 📄 Lisensi

Proyek ini dirilis di bawah lisensi [MIT License](LICENSE). Bebas digunakan, dimodifikasi, dan didistribusikan kembali untuk keperluan pribadi maupun pendidikan.
