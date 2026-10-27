#!/usr/bin/env python3
import sys
import os
import cv2
import numpy as np

# Sumber kamera atau video
# Pengguna bisa panggil: cv-popout /root/lane_detector.py [video_atau_kamera]
video_source = 2
if len(sys.argv) > 1:
    arg = sys.argv[1]
    if arg.isdigit():
        video_source = int(arg)
    else:
        video_source = arg

print(f"[*] Membuka sumber video: {video_source}")
cap = cv2.VideoCapture(video_source)

# Jika kamera 2 gagal, coba otomatis fallback ke index 0 atau video test jika ada
if not cap.isOpened() and isinstance(video_source, int):
    print(f"[-] Kamera index {video_source} tidak dapat dibuka, mencoba index 0...")
    cap = cv2.VideoCapture(0)

if not cap.isOpened():
    print("[-] Kamera tidak bisa dibuka.")
    print("    Tip: Anda bisa menjalankan dengan video rekaman: cv-popout /root/lane_detector.py /sdcard/Download/video.mp4")
    print("    Atau gunakan stream lokal ADB: cv-popout /root/lane_detector.py http://127.0.0.1:8080/video")
    raise SystemExit

cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

roi_x, roi_y, roi_w, roi_h = 10, 190, 620, 200

BIRU = (255, 0, 0)    # BGR
MERAH = (0, 0, 255)
KUNING = (0, 255, 255)
IJO = (0, 255, 0)
WARNA_ROI = (255, 255, 0)

MIN_TINGGI_BORDER = 0.5 * roi_h
MIN_AREA_DASH = 15      # area minimal kontur biar dianggap kandidat
MIN_AREA_DASH_TRACK = 40  # area minimal dash saat mode tracking (turunin ke 25-30 kalau dash kecil gak kebaca)
GATE_DASH = 0.6         # jarak maksimal dash ke kurva kuning (kali mem_lajur)
MAX_LENGKUNG = 0.004    # batas koefisien kuadrat kurva kuning, lebih dari ini dipaksa lurus
LANGKAH_Y = 5
ALPHA = 0.5

PERSEN_TITIK = [0.0, 0.25, 0.5, 0.75, 1.0]
WARNA_TITIK_HIJAU = (0, 255, 0)
WARNA_TITIK_UNGU = (255, 0, 255)
WARNA_GARIS_TITIK = (255, 255, 255)
WARNA_GARIS_3_4 = (255, 0, 255)
X_3_4 = int(roi_w * 0.75)

MAX_HILANG = 10   # frame berturut-turut tanpa dash / tanpa garis pinggir -> reset
MAX_SALAH = 5     # frame berturut-turut kuning tidak di antara biru & merah -> reset
MAX_TEBAL = 25   # tebal rata-rata maksimal garis pinggir (pixel), di atas ini dianggap noise

# ingatan
mem_kiri = roi_w * 0.25
mem_kanan = roi_w * 0.75
mem_lebar = mem_kanan - mem_kiri
mem_lajur = mem_lebar / 2
coef_c = None   # kurva kuning x = f(y)
coef_r = None   # kurva merah
coef_l = None   # kurva biru
hilang = 0
salah = 0


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


def haluskan(lama, baru):
    return baru if lama is None else ALPHA * baru + (1 - ALPHA) * lama


def reset_tracking():
    global coef_c, coef_r, coef_l, mem_lajur, hilang, salah
    coef_l = None
    coef_c = None
    coef_r = None
    mem_lajur = mem_lebar / 2
    hilang = 0
    salah = 0


def tepi_dalam(c, ambil_max):
    """Ambil tepi dalam kontur: x terbesar per y (biru) atau x terkecil per y (merah)."""
    pts = c[:, 0, :]
    ys_u = np.unique(pts[:, 1])
    xs = np.array([pts[pts[:, 1] == y, 0].max() if ambil_max
                   else pts[pts[:, 1] == y, 0].min() for y in ys_u])
    return np.column_stack([xs, ys_u]).astype(np.float64)


def ukuran(c):
    x, y, w, h = cv2.boundingRect(c)      # kotak pembungkus
    area = cv2.contourArea(c)             # luas dalam pixel
    tebal = area / h if h else 0          # tebal rata-rata per baris (horizontal)
    return w, h, area, tebal


def tebal_rata(c):
    h = cv2.boundingRect(c)[3]
    return cv2.contourArea(c) / h if h else 0


print("[*] Algoritma Lane Tracking aktif. Tekan 'q' di jendela video untuk keluar.")

while True:
    ok, frame = cap.read()
    if not ok:
        print("Gagal membaca frame atau video selesai.")
        break

    # Pastikan ukuran frame minimal seukuran ROI
    h_f, w_f = frame.shape[:2]
    if h_f < roi_y + roi_h or w_f < roi_x + roi_w:
        frame = cv2.resize(frame, (640, 480))

    roi = frame[roi_y:roi_y + roi_h, roi_x:roi_x + roi_w]

    gray = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (5, 5), 0)
    _, thresh = cv2.threshold(blur, 205, 255, cv2.THRESH_BINARY)

    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    kiri = kanan = None
    dashes = []
    tracking = coef_c is not None   # mode frame ini

    if tracking:
        # ===== kuning sudah dikenal: klasifikasi kontur pakai kurva kuning =====
        cand_kiri, cand_kanan = [], []

        for c in contours:
            area = cv2.contourArea(c)
            if area < MIN_AREA_DASH:
                continue
            cx, cy = pusat(c)
            x, y, w, h = cv2.boundingRect(c)
            jarak = cx - float(np.polyval(coef_c, cy))
            nempel_samping = x <= 1 or x + w >= roi_w - 1

            if h >= MIN_TINGGI_BORDER or nempel_samping:    # garis pinggir
                if tebal_rata(c) > MAX_TEBAL:               # terlalu tebal = noise
                    continue
                if jarak < 0:
                    cand_kiri.append(c)
                else:
                    cand_kanan.append(c)
            elif area >= MIN_AREA_DASH_TRACK and w < 0.15 * roi_w \
                    and abs(jarak) < GATE_DASH * mem_lajur:
                dashes.append(c)                             # dash

        if cand_kiri:
            kiri = max(cand_kiri, key=cv2.contourArea)
        if cand_kanan:
            kanan = max(cand_kanan, key=cv2.contourArea)

    else:
        # ===== belum ada kuning: cari dari awal =====
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

    # --- dash dianggap satu garis utuh ---
    if len(dashes) >= 2:
        pts = np.vstack([d[:, 0, :] for d in dashes]).astype(np.float64)
        deg = 2 if len(dashes) >= 4 else 1
        cf = fit(pts, deg)
        if abs(cf[0]) > MAX_LENGKUNG:     # terlalu melengkung -> paksa lurus
            cf = fit(pts, 1)
        coef_c = haluskan(coef_c, cf)

    # --- garis pinggir jadi kurva utuh (pakai tepi dalam saja) ---
    if kanan is not None and len(kanan) >= 3:
        coef_r = haluskan(coef_r, fit(tepi_dalam(kanan, False), 2))
    if kiri is not None and len(kiri) >= 3:
        coef_l = haluskan(coef_l, fit(tepi_dalam(kiri, True), 2))

    ys = np.arange(0, roi_h + 1, LANGKAH_Y, dtype=np.float64)
    xg = None

    if coef_c is not None:
        xc = np.polyval(coef_c, ys)

        xl = None
        if kiri is not None and coef_l is not None:
            xl = np.polyval(coef_l, ys)

        # dash hilang: kuning ikut biru (cadangan)
        if len(dashes) < 2 and xl is not None:
            xc = xl + mem_lajur

        xr = None
        if kanan is not None and coef_r is not None:
            xr_kurva = np.polyval(coef_r, ys)
            lajur_now = float(np.mean(xr_kurva - xc))
            if lajur_now > 5:
                xr = xr_kurva
                mem_lajur = haluskan(mem_lajur, lajur_now)
        if xr is None:
            # merah hilang: pakai biru kalau ada, bukan kuning
            xr = (xl + 2 * mem_lajur) if xl is not None else (xc + mem_lajur)

        cv2.polylines(roi, [np.column_stack([xc, ys]).astype(np.int32)], False, KUNING, 2)

        xg = (xc + xr) / 2
        cv2.polylines(roi, [np.column_stack([xg, ys]).astype(np.int32)], False, IJO, 2)

    # ===== AUTO RESET: cek apakah tracking masih layak dipercaya =====
    if tracking and coef_c is not None:
        # (1) dash / garis pinggir hilang terus
        if len(dashes) < 2 or (kiri is None and kanan is None):
            hilang += 1
        else:
            hilang = 0

        # (2) kuning harus ada di antara biru dan merah
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

        # kurva kuning keluar jauh dari ROI = jelas nyasar
        xc_tengah = float(np.polyval(coef_c, roi_h // 2))
        if not (-0.2 * roi_w < xc_tengah < 1.2 * roi_w):
            salah = MAX_SALAH

        if hilang >= MAX_HILANG or salah >= MAX_SALAH:
            reset_tracking()

    # garis vertikal tegak lurus di 3/4 lebar ROI
    cv2.line(roi, (X_3_4, 0), (X_3_4, roi_h), WARNA_GARIS_3_4, 2)

    # 5 titik vektor: hijau (kurva tengah) & ungu (garis 3/4) di y yang sama
    titik_hijau = []
    titik_ungu = []
    if xg is not None:
        for p in PERSEN_TITIK:
            y_t = int(p * (roi_h - 1))
            idx = int(round(p * (len(ys) - 1)))
            x_h = int(xg[idx])

            titik_hijau.append((x_h, y_t))
            titik_ungu.append((X_3_4, y_t))

            cv2.line(roi, (x_h, y_t), (X_3_4, y_t), WARNA_GARIS_TITIK, 1)
            cv2.circle(roi, (x_h, y_t), 5, WARNA_TITIK_HIJAU, -1)
            cv2.circle(roi, (X_3_4, y_t), 5, WARNA_TITIK_UNGU, -1)

    cv2.rectangle(frame,
                  (roi_x, roi_y),
                  (roi_x + roi_w, roi_y + roi_h),
                  WARNA_ROI, 2)
    cv2.putText(frame, "ROI", (roi_x, roi_y - 8),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, WARNA_ROI, 2)

    cv2.imshow("frame", frame)
    cv2.imshow("thresh", thresh)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
