# ==============================================================================
# UbRoid - 1-Click Wireless ADB Auto-Connector for POCO F6
# Connects to POCO F6 over Tailscale (100.116.82.70) or Local Wi-Fi instantly
# Repository: https://github.com/triwahyu45/UbRoid_TriWahyu45
# Author: Tri Wahyu Handoyo (triwahyu45)
# ==============================================================================

param (
    [string]$TargetIP = "100.116.82.70",
    [int]$Port = 5555
)

$target = "$TargetIP`:$Port"

Write-Host "==============================================================================" -ForegroundColor Magenta
Write-Host "UbRoid - Menyambungkan Wireless ADB ke POCO F6 ($target)..." -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Magenta

$adbPath = "C:\Users\hando\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) { $adbPath = $adbCmd.Source } else { $adbPath = "adb" }
}

# 1. Pastikan terhubung
$connectedDevice = & $adbPath devices | Select-String "$TargetIP.*device\b"
if (-not $connectedDevice) {
    Write-Host "-> Menghubungkan ke $target..." -ForegroundColor Yellow
    & $adbPath connect $target | Out-Null
}

# 2. Kunci port 5555 dan terapkan whitelist penghemat baterai Android
& $adbPath -s $target tcpip 5555 2>$null | Out-Null
Start-Sleep -Seconds 1.5
& $adbPath connect $target | Out-Null

$devices = & $adbPath devices | Select-String "$TargetIP.*device\b"
if ($devices) {
    # Whitelist Tailscale dan Termux dari Doze dan Background Killer HyperOS
    $shCmd = "dumpsys deviceidle whitelist +com.tailscale.ipn; dumpsys deviceidle whitelist +com.termux; dumpsys deviceidle whitelist +com.termux.x11; am set-standby-bucket com.tailscale.ipn active; am set-standby-bucket com.termux active; am set-standby-bucket com.termux.x11 active; cmd appops set com.tailscale.ipn RUN_IN_BACKGROUND allow; cmd appops set com.termux RUN_IN_BACKGROUND allow; cmd appops set com.tailscale.ipn 10008 allow; cmd appops set com.termux 10008 allow; settings put global adb_wifi_enabled 1;"
    & $adbPath -s $target shell $shCmd 2>$null | Out-Null

    $model = (& $adbPath -s $target shell "getprop ro.product.model" 2>$null)
    $market = (& $adbPath -s $target shell "getprop ro.product.marketname" 2>$null)
    $battLevel = (& $adbPath -s $target shell "dumpsys battery | grep 'level:' | cut -d: -f2" 2>$null)

    if ($model) { $model = $model.Trim() }
    if ($market) { $market = $market.Trim() }
    if ($battLevel) { $battLevel = $battLevel.Trim() }

    Write-Host ""
    Write-Host "SUKSES TERHUBUNG KE POCO F6!" -ForegroundColor Green
    Write-Host " - Perangkat : $market ($model)" -ForegroundColor White
    Write-Host " - Baterai   : $battLevel%" -ForegroundColor White
    Write-Host " - Endpoint  : $target (Static Port 5555 Locked)" -ForegroundColor White
    Write-Host ""
    Write-Host "Whitelist Doze dan Background Killer HyperOS aktif (Tailscale tetap hidup)." -ForegroundColor Cyan
    Write-Host "Wireless ADB kini standby dan dapat diakses kapan pun tanpa pairing ulang!" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Gagal menyambung ke $target." -ForegroundColor Red
    Write-Host "Pastikan aplikasi Tailscale di POCO F6 dalam status Connected." -ForegroundColor Yellow
}
