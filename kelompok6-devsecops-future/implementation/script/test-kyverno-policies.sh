#!/bin/bash
# =============================================================================
# kelompok6-devsecops-future/implementation/script/test-kyverno-policies.sh
# Dibuat oleh: Anggota 6 (QA & Policy Auditor)
#
# Menjalankan apply pada test-illegal-pod.yaml (berisi skenario ilegal + legit).
# =============================================================================

set -uo pipefail

MANIFEST="kelompok6-devsecops-future/implementation/kyverno/test-illegal-pod.yaml"
LOG_FILE="kelompok6-devsecops-future/evaluation/kyverno-rejection-log.txt"

mkdir -p kelompok6-devsecops-future/evaluation

{
  echo "=== Kyverno Policy Enforcement Test Log ==="
  echo "Tanggal: $(date)"
  echo "Manifest: $MANIFEST"
  echo ""
  echo "--- kubectl apply output ---"
} > "$LOG_FILE"

sudo kubectl apply -f "$MANIFEST" 2>&1 | tee -a "$LOG_FILE"

echo ""
echo "=== Selesai. Log lengkap tersimpan di $LOG_FILE ==="
echo "Ekspektasi Hasil:"
echo "  [Pod] test-illegal-pod-root-user          -> 🛑 DITOLAK (require-non-root)"
echo "  [Pod] test-illegal-pod-no-limits          -> 🛑 DITOLAK (require-resource-limits)"
echo "  [Pod] test-illegal-pod-untrusted-registry -> 🛑 DITOLAK (restrict-image-registry)"
echo "  [Pod] test-compliant-pod                  -> ✅ DITERIMA (created)"
echo "  [Deploy] test-illegal-deployment-root     -> 🛑 DITOLAK (require-non-root)"
echo "  [Deploy] test-compliant-deployment        -> ✅ DITERIMA (created)"
echo ""

# Cleanup: hapus resource legit yang berhasil dibuat agar tidak menuh-menuhin kluster.
# Resource ilegal TIDAK PERNAH tercipta di cluster, jadi tidak perlu dihapus.
echo "Membersihkan resource uji coba yang legit..."
sudo kubectl delete pod test-compliant-pod -n taskflow-prod --ignore-not-found
sudo kubectl delete deployment test-compliant-deployment -n taskflow-prod --ignore-not-found
echo "Cleanup selesai!"
