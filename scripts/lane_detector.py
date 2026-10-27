#!/usr/bin/env python3
# ==============================================================================
# UbRoid - Zero-Delay OpenCV Lane Detection with Native ADB Camera Stream
# Designed for Xiaomi POCO F6 (Android 16 HyperOS Floating Window)
# ZERO BLACK BORDER & ADAPTIVE ORIENTATION & LOW LATENCY
# ==============================================================================
import sys
import os
import socket
import subprocess
import time
import threading
import fcntl
import termios
import array
import cv2
import numpy as np

def get_android_orientation():
    """Deteksi orientasi fisik smartphone: 0 (portrait), 1 (landscape), 2 (reverse portrait), 3 (reverse landscape)."""
    try:
        out = subprocess.check_output(
            ["adb", "-s", "127.0.0.1:5555", "shell", "dumpsys display | grep -E 'mCurrentOrientation'"],
            stderr=subprocess.DEVNULL
        ).decode()
        for line in out.splitlines():
            if "mCurrentOrientation=" in line:
                return int(line.split("=")[1].strip())
    except Exception:
        pass
    return 0

def get_screen_resolution():
    """Dapatkan resolusi sebenarnya dari canvas Termux-X11 agar fit 100% tanpa tepi hitam."""
    try:
        out = subprocess.check_output("xrandr | grep -m1 'current' | awk -F, '{print $2}'", shell=True).decode()
        parts = out.replace('current', '').strip().split('x')
        return int(parts[0].strip()), int(parts[1].strip())
    except Exception:
        return 584, 1048

class ADBCameraCapture:
    """Zero-delay native Android Camera Capture via ADB without any 3rd party apps."""
    def __init__(self, camera_id=0, width=640, height=480, fps=30):
        self.camera_id = camera_id
        self.width = width
        self.height = height
        self.fps = fps
        self.frame_size = width * height * 3
        self.running = True
        self.latest_frame = None
        self.ret = False
        self.lock = threading.Lock()

        print(f"[*] Menghubungkan ke Kamera {'Belakang' if camera_id==0 else 'Depan'} POCO F6 via ADB...")
        # 0. Bersihkan sesi lama jika ada di Android & container
        subprocess.call(["adb", "-s", "127.0.0.1:5555", "shell", "pkill -f scrcpy-server.jar 2>/dev/null || true"], stderr=subprocess.DEVNULL)
        subprocess.call(["pkill", "-9", "-f", "ffmpeg"], stderr=subprocess.DEVNULL)
        
        # 1. Pastikan scrcpy-server ada di Android /data/local/tmp
        subprocess.call(["adb", "-s", "127.0.0.1:5555", "shell", 
                         "cp -f /sdcard/Download/scrcpy-server.jar /data/local/tmp/scrcpy-server.jar && chmod 644 /data/local/tmp/scrcpy-server.jar"], 
                        stderr=subprocess.DEVNULL)
        
        # 2. Forward socket
        subprocess.call(["adb", "-s", "127.0.0.1:5555", "forward", "tcp:28200", "localabstract:scrcpy"], stderr=subprocess.DEVNULL)

        # 3. Jalankan server kamera native
        srv_cmd = f'adb -s 127.0.0.1:5555 shell "CLASSPATH=/data/local/tmp/scrcpy-server.jar app_process / com.genymobile.scrcpy.Server 3.1 video_source=camera camera_id={camera_id} camera_size={width}x{height} max_fps={fps} tunnel_forward=true control=false audio=false cleanup=false raw_stream=true"'
        self.srv_proc = subprocess.Popen(srv_cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(1.0)

        # 4. Hubungkan socket ke scrcpy-server
        self.sock = None
        for _ in range(20):
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                s.connect(('127.0.0.1', 28200))
                s.sendall(b'\x00') # Handshake
                self.sock = s
                break
            except Exception:
                time.sleep(0.2)

        if not self.sock:
            print("[-] Gagal menyambung ke socket scrcpy-server.")
            return

        # 5. Pipeline FFmpeg decoder (H.264 -> Raw BGR24)
        ff_cmd = [
            'ffmpeg', '-hide_banner', '-loglevel', 'error',
            '-f', 'h264', '-i', 'pipe:0',
            '-f', 'rawvideo', '-pix_fmt', 'bgr24', 'pipe:1'
        ]
        self.ff_proc = subprocess.Popen(ff_cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE)

        # Thread 1: Socket data -> FFmpeg stdin
        self.t_sock = threading.Thread(target=self._socket_pump, daemon=True)
        self.t_sock.start()

        # Thread 2: FFmpeg stdout -> latest_frame (Zero-Lag Purge Mechanism)
        self.t_grab = threading.Thread(target=self._frame_grabber, daemon=True)
        self.t_grab.start()

        # Tunggu frame pertama siap (ISP Android 16 butuh ~2-5 detik inisialisasi)
        for _ in range(120):
            if self.latest_frame is not None:
                break
            time.sleep(0.1)

        if self.latest_frame is not None:
            print("[+] Kamera Belakang terhubung aktif (Zero Latency Real-Time)!")
            self.ret = True
        else:
            print("[-] Gagal mendapatkan frame kamera setelah 12 detik.")

    def _socket_pump(self):
        try:
            while self.running:
                data = self.sock.recv(8192)
                if not data:
                    break
                self.ff_proc.stdin.write(data)
                self.ff_proc.stdin.flush()
        except Exception:
            pass

    def _frame_grabber(self):
        fd = self.ff_proc.stdout.fileno()
        q_buf = array.array('i', [0])
        while self.running:
            try:
                # Cek apakah buffer OS menumpuk frame lama (antrean lag)
                try:
                    fcntl.ioctl(fd, termios.FIONREAD, q_buf)
                    queued = q_buf[0]
                    if queued >= 2 * self.frame_size:
                        skip = (queued // self.frame_size - 1) * self.frame_size
                        self.ff_proc.stdout.read(skip)
                except Exception:
                    pass

                raw = self.ff_proc.stdout.read(self.frame_size)
                if len(raw) == self.frame_size:
                    frame = np.frombuffer(raw, dtype=np.uint8).reshape((self.height, self.width, 3))
                    with self.lock:
                        self.latest_frame = frame
                        self.ret = True
            except Exception:
                time.sleep(0.005)

    def isOpened(self):
        return self.ret

    def read(self):
        with self.lock:
            if self.latest_frame is not None:
                return True, self.latest_frame.copy()
        return False, None

    def release(self):
        self.running = False
        try: self.sock.close()
        except: pass
        try: self.ff_proc.terminate()
        except: pass
        try: self.srv_proc.terminate()
        except: pass


# ==============================================================================
# Helper Functions Algoritma Lane Tracking
# ==============================================================================
def pusat(c):
    M = cv2.moments(c)
    if M["m00"] == 0:
        return 0, 0
    return M["m10"] / M["m00"], M["m01"] / M["m00"]

def x_pada_y(c, y, toleransi=15):
    pts = c[:, 0, :]
    sel = pts[np.abs(pts[:, 1] - y) <= toleransi]
    return sel[:, 0].mean() if len(sel) else None

def fit(points, deg):
    ys, xs = points[:, 1], points[:, 0]
    c = np.polyfit(ys, xs, deg)
    return np.concatenate([np.zeros(3 - len(c)), c])

def haluskan(lama, baru, alpha=0.5):
    return baru if lama is None else alpha * baru + (1 - alpha) * lama

def tepi_dalam(c, ambil_max):
    pts = c[:, 0, :]
    ys_u = np.unique(pts[:, 1])
    xs = np.array([pts[pts[:, 1] == y, 0].max() if ambil_max
                   else pts[pts[:, 1] == y, 0].min() for y in ys_u])
    return np.column_stack([xs, ys_u]).astype(np.float64)

def tebal_rata(c):
    h = cv2.boundingRect(c)[3]
    return cv2.contourArea(c) / h if h else 0


# ==============================================================================
# Main Program
# ==============================================================================
def main():
    arg_input = sys.argv[1] if len(sys.argv) > 1 else "back"

    if arg_input in ["back", "belakang", "0", "cam", "camera"]:
        cap = ADBCameraCapture(camera_id=0, width=640, height=480)
    elif arg_input in ["front", "depan", "1"]:
        cap = ADBCameraCapture(camera_id=1, width=640, height=480)
    elif arg_input.isdigit():
        cap = cv2.VideoCapture(int(arg_input))
    else:
        print(f"[*] Membuka file video: {arg_input}")
        cap = cv2.VideoCapture(arg_input)

    if not cap.isOpened():
        print("[-] Gagal membuka sumber kamera/video.")
        sys.exit(1)

    # Deteksi rotasi awal dari orientasi fisik smartphone
    # Kamera belakang pada HP posisi tegak (Portrait = 0) butuh 90° CW agar gambar tegak
    orient_phone = get_android_orientation()
    rot_state = 1 if orient_phone == 0 else 0

    BIRU = (255, 0, 0)
    MERAH = (0, 0, 255)
    KUNING = (0, 255, 255)
    IJO = (0, 255, 0)
    WARNA_ROI = (255, 255, 0)
    WARNA_TITIK_HIJAU = (0, 255, 0)
    WARNA_TITIK_UNGU = (255, 0, 255)
    WARNA_GARIS_TITIK = (255, 255, 255)
    WARNA_GARIS_3_4 = (255, 0, 255)

    MIN_AREA_DASH = 15
    MIN_AREA_DASH_TRACK = 40
    GATE_DASH = 0.6
    MAX_LENGKUNG = 0.004
    LANGKAH_Y = 5
    ALPHA = 0.5
    PERSEN_TITIK = [0.0, 0.25, 0.5, 0.75, 1.0]

    MAX_HILANG = 10
    MAX_SALAH = 5
    MAX_TEBAL = 25

    mem_lebar = 200.0
    mem_lajur = 100.0
    coef_c = None
    coef_r = None
    coef_l = None
    hilang = 0
    salah = 0

    def reset_tracking():
        nonlocal coef_c, coef_r, coef_l, mem_lajur, hilang, salah
        coef_l = None
        coef_c = None
        coef_r = None
        mem_lajur = mem_lebar / 2
        hilang = 0
        salah = 0

    # Inisialisasi jendela pop-out yang mengisi 100% Floating Window
    screen_w, screen_h = get_screen_resolution()
    win_name = "UbRoid Lane Detector"
    cv2.namedWindow(win_name, cv2.WINDOW_NORMAL)
    cv2.moveWindow(win_name, 0, 0)
    cv2.resizeWindow(win_name, screen_w, screen_h)

    print(f"[*] Dashboard aktif (Resolusi Canvas: {screen_w}x{screen_h})!")
    print("[*] Pintasan keyboard: [r] Rotasi 90° | [q] Keluar.")
    fps_time = time.time()
    fps_counter = 0
    fps_display = 30.0
    frame_count = 0

    while True:
        ok, raw_frame = cap.read()
        if not ok or raw_frame is None:
            time.sleep(0.005)
            continue

        frame_count += 1
        # Sinkronkan ukuran canvas jika user mengubah ukuran jendela mengambang
        if frame_count % 45 == 0:
            sw, sh = get_screen_resolution()
            if sw != screen_w or sh != screen_h:
                screen_w, screen_h = sw, sh
                cv2.resizeWindow(win_name, screen_w, screen_h)

        # 1. Terapkan Rotasi Kamera
        if rot_state == 1:
            frame = cv2.rotate(raw_frame, cv2.ROTATE_90_CLOCKWISE)
        elif rot_state == 2:
            frame = cv2.rotate(raw_frame, cv2.ROTATE_180)
        elif rot_state == 3:
            frame = cv2.rotate(raw_frame, cv2.ROTATE_90_COUNTERCLOCKWISE)
        else:
            frame = raw_frame.copy()

        h_f, w_f = frame.shape[:2]

        # 2. Dinamis ROI sesuai orientasi (Portrait vs Landscape)
        if w_f < h_f:  # Mode Portrait (480x640)
            roi_x = int(0.04 * w_f)
            roi_w = int(0.92 * w_f)
            roi_y = int(0.48 * h_f)
            roi_h = int(0.44 * h_f)
        else:          # Mode Landscape (640x480)
            roi_x = 10
            roi_w = w_f - 20
            roi_y = int(0.40 * h_f)
            roi_h = int(0.45 * h_f)

        MIN_TINGGI_BORDER = 0.5 * roi_h
        X_3_4 = int(roi_w * 0.75)

        roi = frame[roi_y:roi_y + roi_h, roi_x:roi_x + roi_w]

        # 3. Preprocessing Citra
        gray = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
        blur = cv2.GaussianBlur(gray, (5, 5), 0)
        _, thresh = cv2.threshold(blur, 205, 255, cv2.THRESH_BINARY)

        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        kiri = kanan = None
        dashes = []
        tracking = coef_c is not None

        # 4. Deteksi & Klasifikasi Kontur
        if tracking:
            cand_kiri, cand_kanan = [], []
            for c in contours:
                area = cv2.contourArea(c)
                if area < MIN_AREA_DASH:
                    continue
                cx, cy = pusat(c)
                x, y, w, h = cv2.boundingRect(c)
                jarak = cx - float(np.polyval(coef_c, cy))
                nempel_samping = x <= 1 or x + w >= roi_w - 1

                if h >= MIN_TINGGI_BORDER or nempel_samping:
                    if tebal_rata(c) > MAX_TEBAL:
                        continue
                    if jarak < 0:
                        cand_kiri.append(c)
                    else:
                        cand_kanan.append(c)
                elif area >= MIN_AREA_DASH_TRACK and w < 0.15 * roi_w and abs(jarak) < GATE_DASH * mem_lajur:
                    dashes.append(c)

            if cand_kiri:
                kiri = max(cand_kiri, key=cv2.contourArea)
            if cand_kanan:
                kanan = max(cand_kanan, key=cv2.contourArea)

        else:
            borders, kandidat = [], []
            for c in contours:
                h = cv2.boundingRect(c)[3]
                if h >= MIN_TINGGI_BORDER:
                    if tebal_rata(c) <= MAX_TEBAL:
                        borders.append(c)
                elif cv2.contourArea(c) >= MIN_AREA_DASH:
                    kandidat.append(c)

            borders = sorted(borders, key=cv2.contourArea, reverse=True)[:2]
            if len(borders) == 2:
                kiri, kanan = sorted(borders, key=lambda c: pusat(c)[0])
                lebar_now = pusat(kanan)[0] - pusat(kiri)[0]
                if lebar_now > 0.2 * roi_w:
                    mem_lebar = lebar_now
                    mem_lajur = mem_lebar / 2
                    for d in kandidat:
                        cx, cy = pusat(d)
                        xl_c = x_pada_y(kiri, cy)
                        xr_c = x_pada_y(kanan, cy)
                        if xl_c is not None and xr_c is not None and xl_c < cx < xr_c:
                            dashes.append(d)
                else:
                    kiri = kanan = None

        if kiri is not None:
            cv2.drawContours(roi, [kiri], -1, BIRU, cv2.FILLED)
        if kanan is not None:
            cv2.drawContours(roi, [kanan], -1, MERAH, cv2.FILLED)

        # 5. Fit Garis Dash & Garis Pinggir
        if len(dashes) >= 2:
            pts = np.vstack([d[:, 0, :] for d in dashes]).astype(np.float64)
            deg = 2 if len(dashes) >= 4 else 1
            cf = fit(pts, deg)
            if abs(cf[0]) > MAX_LENGKUNG:
                cf = fit(pts, 1)
            coef_c = haluskan(coef_c, cf, ALPHA)

        if kanan is not None and len(kanan) >= 3:
            coef_r = haluskan(coef_r, fit(tepi_dalam(kanan, False), 2), ALPHA)
        if kiri is not None and len(kiri) >= 3:
            coef_l = haluskan(coef_l, fit(tepi_dalam(kiri, True), 2), ALPHA)

        ys = np.arange(0, roi_h + 1, LANGKAH_Y, dtype=np.float64)
        xg = None

        if coef_c is not None:
            xc = np.polyval(coef_c, ys)
            xl = None
            if kiri is not None and coef_l is not None:
                xl = np.polyval(coef_l, ys)

            if len(dashes) < 2 and xl is not None:
                xc = xl + mem_lajur

            xr = None
            if kanan is not None and coef_r is not None:
                xr_kurva = np.polyval(coef_r, ys)
                lajur_now = float(np.mean(xr_kurva - xc))
                if lajur_now > 5:
                    xr = xr_kurva
                    mem_lajur = haluskan(mem_lajur, lajur_now, ALPHA)
            if xr is None:
                xr = (xl + 2 * mem_lajur) if xl is not None else (xc + mem_lajur)

            cv2.polylines(roi, [np.column_stack([xc, ys]).astype(np.int32)], False, KUNING, 2)
            xg = (xc + xr) / 2
            cv2.polylines(roi, [np.column_stack([xg, ys]).astype(np.int32)], False, IJO, 2)

        # 6. Auto Reset & Validasi
        if tracking and coef_c is not None:
            if len(dashes) < 2 or (kiri is None and kanan is None):
                hilang += 1
            else:
                hilang = 0

            if kiri is not None and kanan is not None:
                ym = roi_h // 2
                xl_m = x_pada_y(kiri, ym)
                xr_m = x_pada_y(kanan, ym)
                xc_m = float(np.polyval(coef_c, ym))
                if xl_m is not None and xr_m is not None and not (xl_m < xc_m < xr_m):
                    salah += 1
                else:
                    salah = 0
            else:
                salah = 0

            xc_tengah = float(np.polyval(coef_c, roi_h // 2))
            if not (-0.2 * roi_w < xc_tengah < 1.2 * roi_w):
                salah = MAX_SALAH

            if hilang >= MAX_HILANG or salah >= MAX_SALAH:
                reset_tracking()

        cv2.line(roi, (X_3_4, 0), (X_3_4, roi_h), WARNA_GARIS_3_4, 2)

        # 7. 5 Titik Vektor
        if xg is not None:
            for p in PERSEN_TITIK:
                y_t = int(p * (roi_h - 1))
                idx = int(round(p * (len(ys) - 1)))
                x_h = int(xg[idx])

                cv2.line(roi, (x_h, y_t), (X_3_4, y_t), WARNA_GARIS_TITIK, 1)
                cv2.circle(roi, (x_h, y_t), 4, WARNA_TITIK_HIJAU, -1)
                cv2.circle(roi, (X_3_4, y_t), 4, WARNA_TITIK_UNGU, -1)

        # Kotak ROI
        cv2.rectangle(frame, (roi_x, roi_y), (roi_x + roi_w, roi_y + roi_h), WARNA_ROI, 2)

        # FPS calculation
        fps_counter += 1
        now = time.time()
        if now - fps_time >= 0.5:
            fps_display = fps_counter / (now - fps_time)
            fps_counter = 0
            fps_time = now

        # HUD Informasi di atas frame
        rot_names = ["0° (Landscape)", "90° (Portrait)", "180°", "270°"]
        status_txt = "TRACKING" if coef_c is not None else "SEARCHING"
        status_col = (0, 255, 0) if coef_c is not None else (0, 255, 255)

        cv2.putText(frame, f"FPS: {fps_display:.1f} | Status: {status_txt}", (15, 25), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.55, status_col, 2)
        cv2.putText(frame, f"Rotasi: {rot_names[rot_state]} [R]", (15, 50), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)

        # 8. Satukan View Menjadi Single Unified Dashboard (Zero Black Border)
        thresh_bgr = cv2.cvtColor(thresh, cv2.COLOR_GRAY2BGR)
        diag_h = int(h_f * 0.35)
        thresh_resized = cv2.resize(thresh_bgr, (w_f, diag_h))
        cv2.putText(thresh_resized, "Binary Threshold (ROI Contours)", (10, 20),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 255, 255), 1)
        cv2.putText(thresh_resized, "Pintasan: [R] Putar Layar | [Q] Keluar", (10, diag_h - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.4, (200, 200, 200), 1)

        dashboard = np.vstack([frame, thresh_resized])
        
        # Fit tepat ke ukuran canvas floating window (0 tepi hitam)
        display_frame = cv2.resize(dashboard, (screen_w, screen_h), interpolation=cv2.INTER_LINEAR)
        cv2.imshow(win_name, display_frame)

        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break
        elif key == ord('r'):
            rot_state = (rot_state + 1) % 4
            reset_tracking()
            print(f"[*] Rotasi diubah ke: {rot_names[rot_state]}")

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
