# Reading Notes: Paper 1

**Judul Paper**: Configuration Management in Kubernetes Environments: A GitOps Approach
**Penulis**: Raju Shrestha, Ali Abdi Nur Ali
**Afiliasi**: Department of Computer Science, Oslo Metropolitan University (OsloMet), Oslo, Norway
**Tahun Publikasi**: 2024
**Venue Publikasi**: 2024 IEEE/ACM 17th International Conference on Utility and Cloud Computing (UCC 2024)
**DOI**: 10.1109/UCC63386.2024.00077

---

## 1. Klaim Utama dan Metodologi

**Klaim Utama:** Paper ini mengklaim bahwa pendekatan GitOps menggunakan metodologi pull-based (ArgoCD) lebih efektif dalam mengelola *configuration drift* di environment Kubernetes dibandingkan dengan metode push-based tradisional (Ansible), khususnya dalam aspek waktu *induction*, *discovery*, dan *remedy* dari konfigurasi yang menyimpang.

**Metodologi:** Penulis membuktikan klaim ini melalui eksperimen empiris komparatif. Mereka menyiapkan dua environment Kubernetes paralel yang identik (masing-masing 1 controller node + 1 worker node, VM 2 vCPU, 4 GB RAM, 10 GB storage) — satu menggunakan GitOps (ArgoCD) dan satu menggunakan Ansible. Kedua environment menjalankan aplikasi *car dealer* berbasis microservice (React front-end + C# backend API). Evaluasi dilakukan melalui tiga skenario *configuration drift*:

1. **Misconfiguration change** — mengubah *replica count* ke 0 secara manual sehingga aplikasi berhenti
2. **Network configuration drift** — mengubah konfigurasi jaringan langsung di VM tanpa memperbarui file konfigurasi
3. **Application dependency update** — mengubah dependensi dari Newtonsoft.json ke System.Text.json

Untuk setiap skenario, tiga metrik waktu diukur:
- **Induction time**: waktu yang dibutuhkan untuk memperkenalkan drift
- **Discovery time**: interval dari terjadinya drift hingga terdeteksi oleh Prometheus
- **Remedy time**: waktu dari deteksi hingga perbaikan berhasil diterapkan

---

## 2. Temuan Kunci untuk Implementasi

### Skenario 1 — Misconfiguration Change (Replika → 0):
- **Induction time** GitOps lebih singkat karena perubahan dilakukan langsung melalui Git repository, sedangkan Ansible membutuhkan modifikasi manual pada VM.
- **Discovery time** GitOps **~70 detik lebih cepat** dari Ansible berkat integrasi yang lebih efisien dengan CI/CD pipeline dan Prometheus.
- **Remedy time** menunjukkan **perbedaan paling signifikan**: GitOps menggunakan *automated rollback* melalui ArgoCD untuk memulihkan state secara instan, sementara Ansible harus mengeksekusi playbook secara manual — lebih lambat dan rawan kesalahan manusia.

### Skenario 2 — Network Configuration Drift:
- Kedua pendekatan menunjukkan performa **sebanding**: induction time sama-sama 20 detik, discovery time keduanya ~8 menit, remedy time keduanya 24 detik. Ini karena network drift membutuhkan intervensi manual di kedua sistem.

### Skenario 3 — Application Dependency Update:
- **Induction time** GitOps: **29 detik** vs Ansible: **1 menit 35 detik** (GitOps ~3.3x lebih cepat).
- **Discovery time** sebanding, GitOps sedikit unggul ~70 detik (dalam varians normal monitoring 2 menit).
- **Remedy time** GitOps: **30 detik** vs Ansible: **~1 menit 30 detik** (~3x lebih cepat) berkat proses rollback satu klik di ArgoCD.

### Implikasi Langsung untuk Implementasi Kelompok:
- Kita **wajib mengaktifkan `selfHeal: true`** pada ArgoCD Application manifest agar *automated remedy* berjalan tanpa intervensi manual — ini fitur kunci yang membedakan GitOps dari push-based.
- Pipeline CI (Jenkins) cukup melakukan **build + push image + update tag di Git config repo**. Jenkins **tidak boleh lagi memegang kredensial SSH ke kluster** (menghilangkan stage `sshagent` di Jenkinsfile lama).
- Skenario *misconfiguration change* (replika → 0) adalah kandidat pengujian drift yang paling tepat untuk kita replikasi, karena menunjukkan gap terbesar antara GitOps vs tradisional pada metrik *remedy time*.

---

## 3. Asumsi atau Keterbatasan

Sesuai yang diakui penulis di bagian *Discussion* (Section VI), penelitian ini memiliki beberapa keterbatasan:

1. **Hanya dua metode** yang dibandingkan: GitOps (ArgoCD) vs Ansible. Tidak mencakup tool configuration management lain seperti Puppet, Chef, atau Flux.
2. **Hanya tiga skenario** drift yang diuji, sehingga membatasi komprehensivitas evaluasi.
3. **Arsitektur microservice** yang digunakan mungkin tidak merepresentasikan setup monolitik atau arsitektur lain.
4. **Konfigurasi, versi, dan dependensi spesifik** yang digunakan dalam eksperimen mungkin mempengaruhi generalisasi hasil.
5. Paper **tidak mengevaluasi metrik** seperti *system reliability*, *consistency*, *resource utilization*, dan *security* — hanya fokus pada metrik waktu.

---

## 4. Satu Hal yang Diragukan / Dipertanyakan

Paper ini sangat menekankan keunggulan *auto-healing* ArgoCD, namun saya mempertanyakan implikasinya pada skenario **emergency response** di production. Misalnya: jika tim SRE perlu melakukan tindakan darurat langsung di kluster (misalnya mengkarantina pod yang terinfeksi malware dengan mengubah replika ke 0), ArgoCD dengan `selfHeal: true` akan **segera mengembalikan pod tersebut** ke state normal sesuai Git — artinya pod berbahaya akan aktif kembali. SRE harus ingat untuk mem-*pause* sync ArgoCD terlebih dahulu sebelum melakukan *hotfix* darurat, sebuah langkah tambahan yang bisa terlupakan di tengah tekanan insiden. Paper tidak membahas mekanisme *break-glass* atau *escape hatch* untuk skenario seperti ini.
