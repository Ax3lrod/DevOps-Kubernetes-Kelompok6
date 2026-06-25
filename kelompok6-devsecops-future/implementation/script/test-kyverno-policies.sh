#!/bin/bash
# =============================================================================
# implementation/scripts/test-kyverno-policies.sh
# Dibuat oleh: Anggota 6 (QA & Policy Auditor)
#
# Menjalankan apply pada test-illegal-pod.yaml (berisi 3 pod ilegal + 1 legit).
# kubectl mengirim tiap objek sebagai request terpisah ke admission webhook,
# jadi log penolakan/persetujuan tiap pod tetap tercatat individual walau
# di-apply dalam satu file. Tidak butuh dependency tambahan (yq, dst).
#
# Cara pakai:
#   chmod +x implementation/scripts/test-kyverno-policies.sh
#   ./implementation/scripts/test-kyverno-policies.sh
# =============================================================================

set -uo pipefail

MANIFEST="implementation/kyverno/test-illegal-pod.yaml"
LOG_FILE="evaluation/kyverno-rejection-log.txt"

mkdir -p evaluation

{
  echo "=== Kyverno Policy Enforcement Test Log ==="
  echo "Tanggal: $(date)"
  echo "Manifest: $MANIFEST"
  echo ""
  echo "--- kubectl apply output ---"
} > "$LOG_FILE"

kubectl apply -f "$MANIFEST" 2>&1 | tee -a "$LOG_FILE"

echo ""
echo "=== Selesai. Log lengkap tersimpan di $LOG_FILE ==="
echo "Ekspektasi:"
echo "  illegal-root-pod      -> DITOLAK (require-non-root)"
echo "  illegal-no-limits-pod -> DITOLAK (require-resource-limits)"
echo "  illegal-registry-pod  -> DITOLAK (restrict-image-registry)"
echo "  legit-test-pod        -> DITERIMA (pod/legit-test-pod created)"

# Cleanup: hapus pod legit yang berhasil dibuat.
# Pod ilegal TIDAK PERNAH benar-benar tercipta di cluster (ditolak di level
# admission webhook sebelum disimpan ke etcd), jadi tidak ada yang perlu
# dihapus untuk ketiganya.
kubectl delete pod legit-test-pod --ignore-not-found
