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

- 🎨 **Tampilan Otentik Ubuntu GNOME**: Menggunakan wallpaper resmi **Ubuntu Noble Numbat** ungu mascot (`warty-final-ubuntu.png`), dock vertikal hitam di sisi kiri, dan panel atas dengan jam 1 baris yang rapi.
- ⚡ **Bebas Glitch & Kedipan Hitam (0% Flickering)**: Window compositing dioptimalkan secara khusus (`use_compositing = false`) sehingga jendela **Settings**, terminal, browser, dan dialog tidak mengalami kedipan hitam atau stutter.
- 🔍 **Scaling Proporsional 1.75x**: Dikonfigurasi langsung pada level display Termux-X11 (`displayScale: 175`, `DPI: 168`), membuat seluruh font, ikon, dan tombol nyaman disentuh tanpa font raksasa yang merusak layout.
- 📱 **Launcher Native 1-Tap (`Ubuntu_Launcher.apk`)**: Cukup tap icon Ubuntu di homescreen Android Anda, sesi Ubuntu akan otomatis berjalan di background dan langsung membuka desktop tanpa perlu membuka terminal Termux manual.
- 📁 **Integrasi Penyimpanan Internal Android**: Akses langsung folder `/sdcard`, Download, dan foto tablet melalui shortcut **Android Storage** di file manager Thunar.
- 🛍️ **App Center / Manajemen Aplikasi Grafis**: Pasang dan hapus aplikasi Linux langsung melalui GUI tanpa perlu mengetik perintah terminal yang rumit.

---

## 📦 Isi Folder Repository

```
UbRoid_TriWahyu45/
├── apks/                          # APK pendukung siap install
│   ├── Ubuntu_Launcher.apk        # Peluncur 1-Tap native Android
│   ├── termux-app.apk             # Termux base build teruji
│   └── termux-x11.apk             # Display server X11 untuk Android
├── configs/                       # Konfigurasi siap pakai
│   ├── xfce4-panel.xml            # Konfigurasi Dock Kiri & Top Bar
│   ├── xfwm4.xml                  # Window Manager anti-glitch
│   ├── xsettings.xml              # Scaling DPI 168 & Tema Yaru-dark
│   ├── xfce4-desktop.xml          # Background wallpaper Ubuntu ungu
│   ├── gtk.css                    # Styling semi-transparan dock & bar
│   └── panel_launchers/           # Shortcut aplikasi di dock
├── scripts/
│   ├── setup_ubroid.sh            # Script instalasi otomatis 1 baris
│   ├── launch_ubuntu.sh           # Peluncur sesi Termux -> Termux-X11
│   ├── start_desktop.sh           # Inisialisasi sesi desktop di PRoot
│   └── shutdown_ubuntu.sh         # Skrip mematikan sesi dengan bersih
└── assets/
    ├── wallpapers/                # Wallpaper resmi Ubuntu Noble Numbat
    ├── icons/                     # Vector icons resmi Firefox & Chrome
    └── screenshots/               # Tangkapan layar desktop
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
