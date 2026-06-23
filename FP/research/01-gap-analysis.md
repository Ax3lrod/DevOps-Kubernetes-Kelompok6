# Gap Analysis Kelompok 6

Analisis ini mendokumentasikan transisi dari metode Push-based Deployment (Tradisional) menuju Secure GitOps (Cloud-Native). Perubahan ini dilakukan untuk menjawab gap nyata yang diidentifikasi dalam paper, memastikan implementasi bisa menyelesaikan tantangan operasional dan keamanan.

## 1. Gap Manajemen Konfigurasi (Configuration Drift)
*Shrestha & Ali (2024) Configuration Management in Kubernetes Environments: A GitOps Approach.*

*   **Identifikasi Masalah (Gap):**
    Penelitian Shrestha & Ali menunjukkan bahwa metode tradisional (push-based) memiliki kelemahan signifikan pada Remedy Time atau waktu pemulihan. Jika terjadi perubahan manual atau kesalahan konfigurasi di cluster (misal: replika diubah menjadi 0), sistem tradisional tidak dapat mendeteksinya secara otomatis hingga pipeline dijalankan ulang.
*   **Kondisi Lama (Imperative SSH):**
    Menggunakan perintah kubectl set image via SSH. Jika terjadi perbedaan konfigurasi (drift), sistem tidak otomatis memperbaikinya.
*   **Solusi & Justifikasi:**
    Implementasi ArgoCD dengan selfHeal: true. Hal ini menutup gap Remedy Time. Sesuai temuan Paper 1, pendekatan *pull-based* ArgoCD memberikan pemulihan instan (otomatis) saat terjadi deviasi konfigurasi, yang secara signifikan lebih cepat dan reliabel dibanding eksekusi manual via Ansible/SSH.

## 2. Gap Keamanan Runtime (*Policy-as-Code*)
*Sanghi et al. (2025) DevOps and Secure Cloud-Native Architectures for Finance.*

*   **Identifikasi Masalah (Gap):**
    Paper 2 menekankan bahwa arsitektur modern membutuhkan integrasi domain SECURE yang bekerja secara real-time. Gap yang sering terjadi adalah keamanan hanya diperiksa di awal (static scanning) namun diabaikan saat runtime, yang menyebabkan potensi pelanggaran kepatuhan.
*   **Kondisi Lama:**
    Keamanan bersifat pasif. Tidak ada sistem yang memblokir secara otomatis jika Jenkins men-deploy image dari registry yang tidak dikenal atau menjalankan container dengan hak akses root.
*   **Solusi & Justifikasi:**
    Implementasi Kyverno ClusterPolicies dengan mode Enforce. Ini adalah realisasi dari domain SECURE dalam model Triad Domains [Sanghi et al., 2025]. Kami menerapkan prinsip Shift-Left Security, di mana kebijakan Resource Limit, Non-Root User, dan Registry Restriction divalidasi di level runtime, mencegah insiden sebelum pod dijadwalkan.

## 3. Gap Integritas Rantai Pasok & Hak Akses (*Least Privilege*)
*Shrestha & Ali (2024) & Sanghi et al. (2025)*

*   **Identifikasi Masalah (Gap):**
    Pemberian hak akses luas (seperti SSH Key VPS) kepada server CI (Jenkins) menciptakan kerentanan keamanan yang besar. Jika Jenkins dikompromi, seluruh infrastruktur VPS terancam.
*   **Kondisi Lama:**
    Jenkins menyimpan vps-ssh credentials dan masuk ke shell VPS untuk menjalankan perintah kubectl. Ini melanggar prinsip Least Privilege, karena Jenkins memiliki akses penuh ke VPS, yang bisa disalahgunakan jika terjadi breach.
*   **Solusi & Justifikasi:**
    Transisi ke GitOps CD Pipeline. Jenkins kini hanya memiliki akses terbatas ke repository Git (github-token) untuk mengupdate tag image. Sesuai kontribusi Paper 2 mengenai arsitektur cloud-agnostic yang aman, pemisahan ini memastikan tidak ada entitas luar yang memiliki akses langsung ke "dalam" cluster, memperkuat postur keamanan rantai pasok software.

## 4. Gap Efisiensi & throughput Operasional
*Sanghi et al. (2025) DevOps and Secure Cloud-Native Architectures for Finance.*

*   **Identifikasi Masalah (Gap):** 
    Metode tradisional menciptakan hambatan (bottleneck) pada proses verifikasi manual, yang membatasi frekuensi rilis. Paper 2 mencatat bahwa otomatisasi penuh diperlukan untuk mencapai peningkatan frekuensi deployment hingga 400%.
*   **Kondisi Lama:** 
    Setiap deployment membutuhkan waktu tunggu SSH (timeout=120s) dan verifikasi manual, membatasi kecepatan tim dalam merilis fitur.
*   **Solusi:** 
    Dengan GitOps, lead time untuk perubahan konfigurasi dipangkas drastis. Hal ini memungkinkan High Throughput Deployment dan mengurangi Discovery Time hingga 70 detik lebih cepat (sesuai metrik Paper 1) karena sistem dipantau secara berkelanjutan oleh pengontrol sinkronisasi.

## 5. Kepatuhan Standar Industri (Compliance-by-Design)
*Sanghi et al. (2025) DevOps and Secure Cloud-Native Architectures for Finance.*

*   **Identifikasi Masalah (Gap):** 
    Institusi modern (terutama finansial) wajib memenuhi standar PCI-DSS atau GDPR. Tanpa Policy-as-Code yang keras, risiko compliance violations sangat tinggi.
*   **Solusi:** 
    Implementasi kebijakan require-non-root dan require-resource-limits pada Kyverno adalah manifestasi teknis untuk memenuhi audit kepatuhan infrastruktur. Kami berpindah dari "keamanan berbasis kepercayaan" ke "Compliance-by-Design", di mana pelanggaran kebijakan digagalkan secara otomatis di pintu masuk cluster (Admission Control).
---

## Ringkasan Perbandingan Berdasarkan Gap Riset

| Dimensi Analisis | Arsitektur Lama (Imperative) | Arsitektur Baru (Secure GitOps) | Justifikasi Riset |
| :--- | :--- | :--- | :--- |
| **Metode Sinkronisasi** | Push (via SSH Agent) | Pull (ArgoCD Reconciliation) | **Paper 1:** Optimalisasi *Discovery* & *Remedy Time*. |
| **Penanganan Drift** | Reaktif (Menunggu Pipeline) | Otomatis (selfHeal: true) | **Paper 1:** Efektivitas GitOps dalam drift management. |
| **Postur Keamanan** | Terbuka (Tanpa Runtime Policy) | Zero Trust Enforcement | **Paper 2:** Implementasi domain "SECURE" Triad Model. |
| **Validasi Kebijakan** | Manual/Checking Log | Policy-as-Code (Kyverno) | **Paper 2:** Menekan *Compliance Violations* hingga 0%. |
| **Hak Akses CI/CD** | *High Privilege* (SSH Root) | Least Privilege (Git Update Only) | **Paper 2:** Standarisasi keamanan cloud-native. |

Perubahan arsitektur dari Kelompok 6 secara langsung menjawab keterbatasan operasional yang diuraikan dalam Shrestha & Ali (2024) mengenai kecepatan pemulihan sistem, serta memenuhi standar keamanan infrastruktur modern yang diusulkan oleh Sanghi et al. (2025) melalui penerapan kebijakan yang ketat (Policy-as-Code) di level runtime.