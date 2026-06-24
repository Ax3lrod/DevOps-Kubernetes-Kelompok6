#!/bin/bash
# ====================================================================
# SIMULATE-DRIFT-LINUX.SH - Automated Configuration Drift Test for ArgoCD
# Berdasarkan Metodologi Riset Shrestha & Ali (OsloMet, 2024)
# (Versi translasi dari skrip PowerShell Fikri)
# ====================================================================

# Konfigurasi Sesuai Manifes Riil Kelompok 6
NAMESPACE="taskflow-prod"
DEPLOYMENT_NAME="taskflow-api"
TARGET_REPLICAS=2

# Warna untuk output terminal
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GRAY='\033[0;37m'
MAGENTA='\033[1;35m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${CYAN}========== STARTING CONFIGURATION DRIFT SIMULATION ==========${NC}"

# 1. PHASE INDUCTION: Memicu Drift Secara Sengaja (Menghapus Deployment)
echo -e "${YELLOW}[1/2] INDUCTION PHASE: Merusak manifes kluster langsung di runtime...${NC}"
echo -e "${GRAY}Mengeksekusi: sudo kubectl delete deployment/${DEPLOYMENT_NAME} -n ${NAMESPACE}${NC}"

sudo kubectl delete deployment/${DEPLOYMENT_NAME} -n ${NAMESPACE}

# Memulai Stopwatch
START_TIME=$(date +%s.%N)
echo -e "${MAGENTA}Stopwatch diaktifkan. Menunggu rekonsiliasi otomatis (Auto-Heal) dari ArgoCD...${NC}"

# 2. PHASE REMEDY: Pemantauan Auto-Healing Berbasis Detik
echo -e "\n${YELLOW}[2/2] REMEDY PHASE: Memantau proses pemulihan mandiri kluster...${NC}"
IS_HEALED=false

while [ "$IS_HEALED" = false ]; do
    sleep 0.5
    
    # Ambil jumlah replika yang berstatus Ready/Running saat ini lewat kubectl
    CURRENT_REPLICAS=$(sudo kubectl get deployment/${DEPLOYMENT_NAME} -n ${NAMESPACE} -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
    if [ -z "$CURRENT_REPLICAS" ]; then
        CURRENT_REPLICAS=0
    fi
    
    CURRENT_TIME=$(date +%s.%N)
    ELAPSED_INT=$(awk "BEGIN {printf \"%.0f\", $CURRENT_TIME - $START_TIME}")
    
    echo "Status Saat Ini: ${CURRENT_REPLICAS}/${TARGET_REPLICAS} Pod Ready... (Waktu berjalan: ${ELAPSED_INT} detik)"
    
    # Jika kluster berhasil kembali ke target replika asli (2), tandai sukses
    if [ "$CURRENT_REPLICAS" -eq "$TARGET_REPLICAS" ]; then
        IS_HEALED=true
        break
    fi
    
    # Batas aman jika ArgoCD tidak merespons (Timeout 3 menit)
    if [ "$ELAPSED_INT" -gt 180 ]; then
        echo -e "\n${RED}[ERROR] Skenario Gagal: ArgoCD tidak melakukan Auto-Heal hingga batas timeout!${NC}"
        exit 1
    fi
done

# 3. KESIMPULAN METRIK EVALUASI
END_TIME=$(date +%s.%N)
REMEDY_TIME=$(awk "BEGIN {printf \"%.3f\", $END_TIME - $START_TIME}")

echo -e "\n${GREEN}==========================================================${NC}"
echo -e "${GREEN}HASIL PENGUJIAN: Drift Teratasi Secara Otomatis (Self-Healed)!${NC}"
echo -e "${CYAN}Mean Time to Remediation (MTTR): ${REMEDY_TIME} Detik${NC}"
echo -e "${GREEN}==========================================================${NC}"
