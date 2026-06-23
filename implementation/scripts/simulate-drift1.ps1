# ====================================================================
# SIMULATE-DRIFT.PS1 - Automated Configuration Drift Test for ArgoCD
# Berdasarkan Metodologi Riset Shrestha & Ali (OsloMet, 2024)
# ====================================================================

# Konfigurasi Sesuai Manifes Riil Kelompok 6
$Namespace = "taskflow-prod"
$DeploymentName = "taskflow-api"
$TargetReplicas = 2 

Write-Host "========== STARTING CONFIGURATION DRIFT SIMULATION ==========" -ForegroundColor Cyan

# 1. PHASE INDUCTION: Memicu Drift Secara Sengaja (Menghapus Deployment)
Write-Host "[1/2] INDUCTION PHASE: Merusak manifes kluster langsung di runtime..." -ForegroundColor Yellow
Write-Host "Mengeksekusi: kubectl delete deployment/$DeploymentName -n $Namespace" -ForegroundColor Gray

# Mengeksekusi penghapusan sesuai skenario eksperimen riil VPS kelompok
& kubectl delete deployment/$DeploymentName -n $Namespace

# Memulai Stopwatch untuk mengukur Remedy Time (MTTR) secara empiris
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "Stopwatch diaktifkan. Menunggu rekonsiliasi otomatis (Auto-Heal) dari ArgoCD..." -ForegroundColor Magenta

# 2. PHASE REMEDY: Pemantauan Auto-Healing Berbasis Detik
Write-Host "`n[2/2] REMEDY PHASE: Memantau proses pemulihan mandiri kluster..." -ForegroundColor Yellow
$IsHealed = $false

while (-not $IsHealed) {
    Start-Sleep -Seconds 2
    
    # Ambil jumlah replika yang berstatus Ready/Running saat ini lewat kubectl
    $CurrentReplicas = (& kubectl get deployment/$DeploymentName -n $Namespace -o jsonpath='{.status.readyReplicas}')
    if ([string]::IsNullOrEmpty($CurrentReplicas)) { $CurrentReplicas = 0 }
    
    Write-Host "Status Saat Ini: $CurrentReplicas/$TargetReplicas Pod Ready... (Waktu berjalan: $($Stopwatch.Elapsed.Seconds) detik)"
    
    # Jika kluster berhasil kembali ke target replika asli (2), tandai sukses
    if ([int]$CurrentReplicas -eq $TargetReplicas) {
        $IsHealed = $true
    }
    
    # Batas aman jika ArgoCD tidak merespons (Timeout 3 menit)
    if ($Stopwatch.Elapsed.TotalSeconds -gt 180) {
        Write-Host "`n[ERROR] Skenario Gagal: ArgoCD tidak melakukan Auto-Heal hingga batas timeout!" -ForegroundColor Red
        $Stopwatch.Stop()
        exit
    }
}

# 3. KESIMPULAN METRIK EVALUASI
$Stopwatch.Stop()
$RemedyTime = $Stopwatch.Elapsed.TotalSeconds

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "HASIL PENGUJIAN: Drift Teratasi Secara Otomatis (Self-Healed)!" -ForegroundColor Green
Write-Host "Mean Time to Remediation (MTTR): $RemedyTime Detik" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Green