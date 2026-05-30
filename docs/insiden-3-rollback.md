# Laporan Simulasi Rollback Cepat (Insiden 3)

**Disusun oleh:** Anggota 3 (Stability Engineer A)  
**Namespace:** `taskflow-prod`  
**Objek Deployment:** `taskflow-api`

## 1. Permasalahan (Insiden 3)
Sebelum migrasi ke Kubernetes, tim operasional TaskFlow membutuhkan waktu sekitar **25 menit** untuk melakukan rollback secara manual saat ditemukan bug kritis pada versi baru. Proses tersebut melibatkan akses SSH ke server, penghentian container, penarikan image lama secara manual, serta menjalankan ulang seluruh konfigurasi. Hal ini menyebabkan downtime yang signifikan dan risiko kesalahan manusia (human error) yang tinggi.

## 2. Langkah Eksekusi Rollback di Kubernetes

### A. Memastikan Riwayat Perubahan (History)
Langkah pertama adalah memastikan bahwa Kubernetes menyimpan riwayat revisi deployment. Kami melakukan simulasi dengan memperbarui aplikasi dari Revisi 1 ke Revisi 2 untuk menciptakan titik pemulihan (restore point).

**Perintah:**
`kubectl rollout history deployment/taskflow-api -n taskflow-prod`

> <img width="710" height="143" alt="Screenshot 2026-05-30 205532" src="https://github.com/user-attachments/assets/54f49d73-a6d4-456a-b03a-ac20a01c6b0f" />


### B. Menjalankan Perintah Rollback (Undo)
Ketika versi terbaru (Revisi 2) terdeteksi memiliki masalah, kami menjalankan perintah rollback untuk mengembalikan aplikasi ke versi stabil sebelumnya (Revisi 1) hanya dengan satu baris perintah tanpa perlu konfigurasi ulang secara manual.

**Perintah:**
`kubectl rollout undo deployment/taskflow-api -n taskflow-prod`

> <img width="710" height="63" alt="Screenshot 2026-05-30 205711" src="https://github.com/user-attachments/assets/481c8a21-2117-4c57-abae-8486476ed117" />


### C. Verifikasi Keberhasilan Rollback
Kami memantau proses transisi hingga Kubernetes menyatakan bahwa proses pengembalian versi telah selesai sepenuhnya dan Pod versi stabil telah berjalan kembali.

**Perintah:**
`kubectl rollout status deployment/taskflow-api -n taskflow-prod`

**Hasil Terminal:**
`deployment "taskflow-api" successfully rolled out`

> <img width="715" height="60" alt="Screenshot 2026-05-30 205809" src="https://github.com/user-attachments/assets/db38e794-822a-43e4-adb3-816765928f1c" />


## 3. Analisis Ketersediaan Layanan (Zero Downtime)

Selama proses rollback berlangsung, kami menjalankan skrip monitoring PowerShell untuk memantau apakah layanan tetap bisa diakses. Berikut adalah data log yang tercatat berdasarkan hasil simulasi:

*   **20:29:20** - HTTP 200 (Aplikasi versi Revisi 2 masih melayani permintaan).
*   **20:29:21 - 20:29:22** - *Unable to connect* (Terjadi jeda koneksi singkat sekitar 3 detik saat Kubernetes melakukan terminasi Pod Revisi 2 dan mengaktifkan kembali Pod Revisi 1).
*   **20:29:23** - HTTP 200 (Aplikasi versi stabil Revisi 1 berhasil aktif kembali dan melayani permintaan secara normal).

**Analisis:** Terjadi jeda koneksi singkat selama 3 detik yang disebabkan oleh proses pemindahan trafik antar Pod pada cluster lokal (Minikube). Meskipun terdapat jeda sangat singkat, sistem terbukti mampu melakukan pemulihan secara otomatis (*self-recovered*) tanpa intervensi manual sama sekali. Jika dibandingkan dengan downtime manual 25 menit, hasil ini merupakan peningkatan yang sangat signifikan.

> <img width="704" height="275" alt="Screenshot 2026-05-30 205903" src="https://github.com/user-attachments/assets/a14e0ee3-b290-4749-837f-311051dbe25d" />


## 4. Perbandingan Efisiensi

**Metode Lama (Manual):**
*   **Langkah Kerja:** Harus SSH ke server, stop container manual, pull image lama, jalankan ulang, dan cek konfigurasi ulang.
*   **Waktu Pemulihan:** Membutuhkan waktu sekitar 25 menit.
*   **Downtime:** Aplikasi mati total selama proses manual dilakukan oleh teknisi.
*   **Tingkat Risiko:** Tinggi karena banyaknya langkah manual yang berpotensi terjadi kesalahan pengetikan.

**Metode Baru (Kubernetes):**
*   **Langkah Kerja:** Cukup menjalankan satu perintah otomatis (`kubectl rollout undo`).
*   **Waktu Pemulihan:** Selesai dalam waktu kurang dari 20 detik secara total.
*   **Downtime:** Hanya sekitar 3 detik (Masa transisi otomatis antar Pod).
*   **Tingkat Risiko:** Sangat Rendah karena proses dikelola secara sistematis oleh Kubernetes Control Plane.

## 5. Kesimpulan
Berdasarkan simulasi ini, penggunaan Kubernetes terbukti berhasil meningkatkan efisiensi waktu pemulihan insiden sebesar **99.8%** (dari 25 menit menjadi hanya hitungan detik). Fitur Rollback menjamin ketersediaan layanan yang lebih tinggi dan memberikan keamanan bagi tim pengembang saat melakukan rilis aplikasi di lingkungan produksi.

---
