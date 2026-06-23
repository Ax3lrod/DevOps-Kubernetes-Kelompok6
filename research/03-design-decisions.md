# Justifikasi Desain Teknis — GitOps Architecture (Anggota 5)

## 1. Pemilihan Arsitektur Pull-Based Deployment (ArgoCD)

Kami memutuskan untuk mengadopsi pendekatan _Pull-Based GitOps_ menggunakan **ArgoCD** di dalam kluster K3s VPS Kelompok 6, menggantikan arsitektur _Push-Based CD_ lama yang mengandalkan koneksi agen SSH langsung dari Jenkins ke VPS.

### A. Landasan Teoretis Berbasis Literatur Ilmiah

[cite_start]Keputusan desain ini merujuk langsung pada argumen dan hasil eksperimen dari **Paper 1 (Shrestha & Ali, 2024)** mengenai manajemen _configuration drift_ di lingkungan Kubernetes.

- [cite_start]**Eliminasi Akses Imperatif & SSH:** Shrestha & Ali (2024) menekankan bahwa alat manajemen konfigurasi tradisional (seperti Ansible) bersifat _imperative_ dan membutuhkan akses SSH persisten ke setiap node[cite: 276, 280, 506]. [cite_start]Hal ini menimbulkan risiko _credential exposure_ dan kesalahan manual[cite: 282, 287]. [cite_start]Dengan GitOps, manifestasi bersifat _declarative_ dan disimpan di dalam repositori Git sebagai _Single Source of Truth_[cite: 290, 291].
- [cite_start]**Keunggulan Siklus Rekonsiliasi Otomatis:** Paper 1 membuktikan secara empiris bahwa dalam skenario _misconfiguration change_ (misalnya jumlah replika diubah secara ilegal menjadi 0), fitur _automated rollback_ dan sinkronisasi otomatis GitOps secara signifikan mengungguli eksekusi skrip tradisional dalam hal efisiensi waktu pemulihan (_remedy time_)[cite: 265, 267, 426, 439].

### B. Validasi Berdasarkan Hasil Eksperimen Riil Kluster

Justifikasi teoretis di atas berhasil kami buktikan secara valid melalui pengujian otomatis menggunakan skrip `simulate-drift1.ps1` pada kluster VPS kami:

1. **Sistem Tradisional (Baseline):** Pemulihan manual (meniru cara lama via Jenkins/SSH) membutuhkan total waktu Mean Time to Remediation (MTTR) sebesar **31.906 detik**, di mana sistem mengalami _downtime_ yang lama karena menunggu intervensi operator manusia untuk menyadari eror dan memicu _apply_ ulang.
2. **Sistem GitOps Modern (ArgoCD):** Ketika objek deployment `taskflow-api` dihapus secara total dari runtime kluster, kontroler ArgoCD mendeteksi deviasi tersebut secara instan dan mengeksekusi _autonomous healing_ hanya dalam waktu **4.234 detik** tanpa ada intervensi manusia (_zero human intervention_).

## 2. Penyelarasan dengan Keamanan Runtime (Triad Domain)

[cite_start]Keputusan operasional untuk memasang kontroler GitOps yang memiliki kapabilitas _auto-healing_ ini juga diselaraskan dengan model multi-layer yang diusulkan oleh **Paper 2 (Sanghi et al., 2025)**[cite: 19, 52].

[cite_start]Dalam domain _Operations_ pada struktur Triad DevSecOps, sistem dituntut tidak hanya mampu melakukan orkestrasi, tetapi harus memiliki mekanisme pencegahan manipulasi status infrastruktur secara real-time (_automated rollback & resilience enhancement_) demi menjaga kedaulatan dan stabilitas layanan[cite: 55, 56, 194]. [cite_start]Kombinasi antara rekonsiliasi state dari ArgoCD dan runtime control dari Kyverno (yang dikerjakan oleh Anggota 3) mewujudkan arsitektur pertahanan berlapis (_layered defense_) yang kokoh sesuai dengan karakteristik sistem cloud-native modern[cite: 49].
