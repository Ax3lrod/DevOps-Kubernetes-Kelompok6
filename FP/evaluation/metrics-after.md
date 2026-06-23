# Metrics After Enhancement (Pasca-Peningkatan GitOps & PaC)

Dokumen ini mencatat hasil pengukuran empiris kinerja keandalan infrastruktur Kelompok 6 setelah mengintegrasikan ArgoCD (Deployment Intelligence) dan Kyverno (Policy-as-Code) pada kluster K3s VPS baru (`10.4.89.242`).

## 📊 1. Pengukuran Waktu Pemulihan Otomatis (ArgoCD Auto-Healing)

Pengujian dilakukan secara otomatis menggunakan skrip automasi `simulate-drift1.ps1` dengan menyimulasikan skenario _Misconfiguration Change_ (penghapusan objek deployment `taskflow-api` pada namespace `taskflow-prod` secara langsung di runtime cluster menggunakan perintah `kubectl delete`).

| Metrik Evaluasi                               | Nilai Pasca-Peningkatan Riil | Keterangan Operasional Sistem                                                        |
| :-------------------------------------------- | :--------------------------- | :----------------------------------------------------------------------------------- |
| **Waktu Deteksi Drift (Discovery Time)**      | Instan (< 2 Detik)           | Kontroler ArgoCD mendeteksi deviasi manifest secara real-time.                       |
| **Waktu Rekonsiliasi Otomatis (Remedy Time)** | **4.234 Detik**              | Durasi dari penghapusan objek hingga kontainer baru kembali berstatus `Running 1/1`. |
| **Intervensi Operator (Human Action)**        | 0% (Tanpa Sentuhan Manusia)  | Pemulihan murni dieksekusi secara otomatis oleh internal kontroler cluster.          |

## 🛡️ 2. Pengukuran Kepatuhan Runtime (Kyverno Policy Enforcement)

Berdasarkan verifikasi audit bersama Anggota 3, pengujian dilakukan dengan mencoba menyisipkan 3 jenis manifes kontainer berbahaya (_illegal workloads_) secara langsung ke cluster produksi:

| Skenario Pod Ilegal                                       | Ekspektasi Keamanan   | Hasil Pengujian Riil                                                           | Status           |
| :-------------------------------------------------------- | :-------------------- | :----------------------------------------------------------------------------- | :--------------- |
| Deploy dengan Privilese Root User                         | Ditolak oleh Cluster  | `admission webhook denied request: Pod dilarang berjalan sebagai root`         | **100% BLOCKED** |
| Deploy tanpa Batasan CPU/Memori                           | Ditolak oleh Cluster  | `validation error: Container wajib mendefinisikan resources.requests & limits` | **100% BLOCKED** |
| Tarik Image dari Registry Asing (`ubuntu:latest`)         | Ditolak oleh Cluster  | `validation error: Image hanya boleh dari registry terpercaya (fikriau/*)`     | **100% BLOCKED** |
| Deploy Manifest Resmi (`fikriau/taskflow-api-k8s:stable`) | Diterima oleh Cluster | `pod/test-legit created`                                                       | **100% ALLOWED** |

### 🔍 Kesimpulan Evaluasi Kuantitatif

Implementasi _automated reconciliation loop_ berbasis GitOps terbukti berhasil memangkas durasi kelumpuhan sistem (_Mean Time to Remediation_) secara drastis dari yang semula membutuhkan waktu respons operasional manual sebesar **31.906 detik** turun menjadi hanya **4.234 detik**. Hasil pengujian ini memvalidasi keunggulan performa otomasi pemulihan mandiri (_self-healing_) yang diulas pada literatur utama kelompok kami.
