# Insiden 1 — Self-Healing

## Deskripsi
Simulasi self-healing dengan menghapus salah satu Pod dan mengamati respon Kubernetes untuk membuktikan bahwa sistem dapat pulih secara otomatis tanpa intervensi manual.

## Langkah-langkah
1. Pantau pod secara real-time: `kubectl get pods -n taskflow-prod -w`
2. Identifikasi pod yang berjalan (terdapat 2 replika).
3. Hapus salah satu pod secara manual: `kubectl delete pod taskflow-api-74cbdfbdd6-4xfq4 -n taskflow-prod`
4. Amati proses terminasi dan pembuatan pod baru.

## Hasil Observasi
Berdasarkan log terminal:
- **Pod yang dihapus:** `taskflow-api-74cbdfbdd6-4xfq4`
- **Waktu mulai terminasi:** T+0s
- **Pod baru dibuat (`6v752`):** T+0s (Status: Pending)
- **Pod baru siap (`Running`):** T+10s

**Total Waktu Recovery: 10 Detik.**

## Kesimpulan
Insiden 1 (downtime 6 jam) tidak akan terulang kembali karena Kubernetes mendeteksi ketidaksesuaian jumlah replika secara instan dan melakukan recovery dalam waktu kurang dari 1 menit.
