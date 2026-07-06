# Justifikasi Desain Teknis — GitOps Architecture (Anggota 5)

## 1. Pemilihan Arsitektur Pull-Based Deployment (ArgoCD)

Kami memutuskan untuk mengadopsi pendekatan _Pull-Based GitOps_ menggunakan **ArgoCD** di dalam kluster K3s VPS Kelompok 6. Langkah ini diambil guna menggantikan arsitektur _Push-Based CD_ lama yang mengandalkan koneksi agen SSH langsung dari Jenkins ke VPS.

### A. Landasan Teoretis Berbasis Literatur Ilmiah

Keputusan desain ini merujuk langsung pada argumen dan hasil eksperimen dari **Shrestha & Ali (2024)** mengenai manajemen _configuration drift_ di lingkungan Kubernetes.

- **Eliminasi Akses Imperatif & SSH:** Shrestha & Ali (2024) menekankan bahwa alat manajemen konfigurasi tradisional (seperti Ansible) bersifat _imperative_ dan membutuhkan akses SSH persisten ke setiap node. Ketergantungan ini berpotensi menimbulkan risiko kebocoran kredensial (_credential exposure_) serta kesalahan manual operasional (_human error_). Dengan GitOps, seluruh manifestasi bersifat _declarative_ dan disimpan di dalam repositori Git sebagai _Single Source of Truth_.
- **Keunggulan Siklus Rekonsiliasi Otomatis:** Eksperimen dari Shrestha & Ali (2024) membuktikan secara empiris bahwa dalam skenario _misconfiguration change_ (seperti jumlah replika diubah secara ilegal menjadi 0), fitur _automated rollback_ dan sinkronisasi otomatis GitOps secara signifikan mengungguli eksekusi skrip tradisional dalam hal efisiensi waktu pemulihan (_remedy time_).

### B. Validasi Berdasarkan Hasil Eksperimen Riil Kluster

Justifikasi teoretis di atas berhasil kami buktikan secara valid melalui pengujian otomatis menggunakan skrip `simulate-drift1.ps1` pada kluster VPS kami:

1. **Sistem Tradisional (Baseline):** Pemulihan manual (meniru cara lama via Jenkins/SSH) membutuhkan total waktu Mean Time to Remediation (MTTR) sebesar **31.581 detik**. Pada kondisi ini, sistem mengalami _downtime_ yang lama karena harus menunggu intervensi operator manusia untuk menyadari eror dan memicu _apply_ ulang.
2. **Sistem GitOps Modern (ArgoCD):** Ketika objek deployment `taskflow-api` dihapus secara total dari runtime kluster, kontroler ArgoCD mendeteksi deviasi tersebut secara instan dan mengeksekusi _autonomous healing_ hanya dalam waktu **2.038 detik** tanpa ada intervensi manusia (_zero human intervention_).

## 2. Penyelarasan dengan Keamanan Runtime (Triad Domain)

Keputusan operasional untuk memasang kontroler GitOps yang memiliki kapabilitas _auto-healing_ ini juga diselaraskan dengan model multi-layer yang diusulkan oleh **Sanghi et al. (2025)**.

Dalam domain _Operations_ pada struktur Triad DevSecOps, sistem dituntut tidak hanya mampu melakukan orkestrasi, tetapi harus memiliki mekanisme pencegahan manipulasi status infrastruktur secara real-time (_automated rollback & resilience enhancement_) demi menjaga kedaulatan dan stabilitas layanan.

Kombinasi antara rekonsiliasi kondisi (_state_) dari ArgoCD dan kontrol runtime (_runtime control_) dari Kyverno (yang dikerjakan oleh Anggota 3) berhasil mewujudkan arsitektur pertahanan berlapis (_layered defense_) yang kokoh sesuai dengan karakteristik sistem cloud-native modern.



Design Decisions
---
Policy-as-Code: Justifikasi Pemilihan Kyverno
(Ditulis oleh Anggota 6 — QA & Policy Auditor)

1. Masalah yang Ingin Diselesaikan
Sebagaimana dibahas Anggota 3 di `research/02-state-of-the-art.md`, static scanning
di CI pipeline (SonarQube, Trivy) hanya menangkap known vulnerabilities pada
saat image dibangun. Setelah image lolos scan, tidak ada lagi mekanisme yang
mencegah operator/developer melakukan `kubectl apply` secara langsung ke cluster
dengan konfigurasi yang berbahaya — misalnya container yang berjalan sebagai
root, tanpa resource limits, atau memakai image dari registry yang tidak
terverifikasi. Gap inilah yang melatari pemilihan admission controller sebagai
lapisan keamanan tambahan di runtime.

2. Kaitan dengan Model Triad (Paper 2)
Paper 2 [Sanghi et al., 2025] mengusulkan model Triad yang salah satu domainnya
adalah SECURE, dengan penekanan pada cross-layer Policy-as-Code — bahwa
keamanan tidak boleh berhenti di tahap CI, melainkan harus ditegakkan kembali
di setiap layer arsitektur, termasuk saat eksekusi di cluster. Pertanyaan kunci
yang diajukan paper tersebut — "siapa yang menjaga pintu cluster setelah CI
selesai?" — menjadi dasar argumen kelompok kami untuk mengadopsi Kyverno
sebagai implementasi konkret dari prinsip tersebut.

3. Mengapa Kyverno (bukan alternatif lain seperti OPA Gatekeeper)
Pertimbangan	Kyverno
Bahasa policy	YAML native — sama dengan manifest Kubernetes lain, tidak perlu belajar bahasa baru (Rego pada OPA)
Kurva belajar tim	Lebih cepat diadopsi karena seluruh anggota sudah familiar dengan sintaks YAML K8s
Instalasi	Cukup via Helm chart resmi (`helm install kyverno kyverno/kyverno`), minim konfigurasi tambahan
Mode operasi	Mendukung `Audit` (hanya mencatat) dan `Enforce` (memblokir aktif) — fleksibel untuk rollout bertahap

4. Mengapa Mode `Enforce`, Bukan `Audit`
Tim sengaja mengatur `validationFailureAction: Enforce` pada ketiga policy
(`require-non-root`, `require-resource-limits`, `restrict-image-registry`)
alih-alih `Audit`. Keputusan ini didasarkan pada prinsip fail-closed: untuk
sebuah simulasi yang merepresentasikan sistem finansial (sesuai konteks Paper 2),
membiarkan konfigurasi berbahaya berjalan dulu lalu baru "diaudit" dianggap
terlalu beresiko. Trade-off-nya adalah deployment yang salah akan langsung gagal
total (bukan warning), sehingga developer dipaksa memperbaiki manifest sebelum
bisa deploy — sejalan dengan prinsip shift-left security namun diperketat
hingga ke titik eksekusi.

5. Validasi Empiris
Keputusan desain di atas diverifikasi melalui pengujian pada
`evaluation/metrics-after.md`: ketiga skenario pelanggaran (root user, tanpa
resource limits, registry asing) berhasil ditolak 100% oleh admission webhook,
sementara Pod yang patuh tetap dapat di-deploy tanpa halangan — membuktikan
bahwa policy tidak menghasilkan false positive yang akan mengganggu operasional
normal tim.
