# Insiden 2 — Rolling Update Tanpa Downtime

## Deskripsi
Simulasi pembaruan aplikasi (update) ke versi baru tanpa menyebabkan gangguan layanan (zero downtime). Fitur ini membuktikan bahwa insiden penghentian layanan selama 8 menit saat deployment tidak akan terulang kembali.

## Strategi Deployment
Menggunakan strategi `RollingUpdate` dengan parameter:
- `maxSurge: 1`: Kubernetes diizinkan membuat 1 Pod ekstra sebelum mematikan Pod lama.
- `maxUnavailable: 0`: Kubernetes tidak boleh mematikan Pod lama sebelum Pod baru siap melayani trafik.

## Langkah-langkah
1. Menjalankan monitor request loop untuk memantau ketersediaan layanan.
2. Mengubah teks respons pada `deployment.yaml` dari versi `v1` ke `v2`.
3. Menerapkan perubahan: `kubectl apply -f kubernetes/deployment.yaml -n taskflow-prod`.
4. Memantau status rollout: `kubectl rollout status deployment/taskflow-api -n taskflow-prod`.

## Hasil Observasi
Selama proses transisi dari v1 ke v2:
- **Status HTTP:** Konsisten pada `200 OK`.
- **Error/Downtime:** 0 detik (Tidak ada kegagalan koneksi).
- **Transisi Konten:** Berhasil berubah dari "Halo dari TaskFlow v1!" menjadi "Halo dari TaskFlow v2! Update Berhasil!".

## Kesimpulan
Dengan konfigurasi `strategy: RollingUpdate` dan `maxUnavailable: 0`, pembaruan aplikasi dapat dilakukan kapan saja (bahkan di jam sibuk) tanpa mengganggu pengguna, karena layanan selalu tersedia selama proses pembaruan berlangsung.
