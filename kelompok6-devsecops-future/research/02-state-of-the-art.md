# State of the Art: Pipeline DevSecOps & GitOps

*(Dokumen ini merupakan hasil kolaborasi. Bagian ini difokuskan pada GitOps dan Continuous Deployment, disusun oleh Anggota 2.)*

---

## Evolusi Configuration Management: Dari Imperatif ke Deklaratif

Pengelolaan konfigurasi infrastruktur telah berkembang melalui beberapa generasi. Tools tradisional seperti Ansible, Puppet, dan Chef menggunakan pendekatan **imperatif**: administrator menulis script/playbook yang memerintahkan *bagaimana* mencapai state yang diinginkan, lalu mengeksekusinya ke server target melalui SSH atau agent (Berton, 2023; Elradi, 2023). Pendekatan ini, meski efektif pada masanya, memiliki kelemahan fundamental ketika diterapkan pada environment cloud-native yang dinamis seperti Kubernetes.

## Keterbatasan Sistem Push-Based pada Pipeline Lama Kelompok Kami

Pada arsitektur CI/CD pipeline kelompok kami di tugas sebelumnya, Jenkins melakukan deployment ke kluster Kubernetes di VPS (`10.4.89.175`) menggunakan **pendekatan push-based**: Jenkins menyimpan kredensial SSH (`sshagent` dengan credential `vps-ssh`), lalu menjalankan `kubectl set image` dan `kubectl rollout status` secara remote melalui SSH tunnel ke user `kelompok6`. Ini adalah contoh klasik dari arsitektur push-based yang diidentifikasi oleh literatur sebagai memiliki beberapa *gap* kritis:

### 1. Security Risk — "God Mode" pada CI Server
Jenkins memegang SSH key dengan akses langsung ke kluster Kubernetes. Jika server Jenkins dikompromikan, penyerang mendapatkan akses penuh ke kluster produksi (Shamim, 2021). Farayola et al. (2023) menegaskan bahwa intervensi manual dan penyimpanan kredensial berlebihan meningkatkan risiko *misconfiguration* dan *security vulnerabilities*.

### 2. Configuration Drift yang Tidak Terdeteksi
Jika seseorang mengubah state kluster secara langsung (misalnya: `kubectl scale deployment taskflow-api --replicas=0` langsung di server), Jenkins **tidak memiliki mekanisme untuk mendeteksi** perbedaan antara state yang dideklarasikan dan state aktual. Drift ini akan tetap ada tanpa batas waktu sampai pipeline berikutnya dipicu secara manual. Gupta et al. (2022) mengidentifikasi masalah ini sebagai salah satu tantangan utama dalam *fast CI/CD cycles*.

### 3. Auditability yang Lemah
Perubahan via SSH langsung ke server tidak terekam dalam Git history. Tidak ada *audit trail* yang jelas tentang siapa mengubah apa dan kapan, membuat proses *rollback* dan *post-mortem analysis* menjadi sulit. Zeini et al. (2023) menyoroti pentingnya pendekatan keamanan terintegrasi untuk *Infrastructure as Code*.

## Pull-based GitOps (ArgoCD) sebagai State of the Art

GitOps, sebagai konsep, didefinisikan oleh Beetz & Harrer (2021) sebagai evolusi dari DevOps di mana Git berfungsi sebagai *single source of truth* untuk seluruh state infrastruktur dan aplikasi. Berbeda dari push-based, arsitektur GitOps menggunakan **operator di dalam kluster** yang secara aktif *menarik (pull)* dan mencocokkan state yang dideklarasikan di Git dengan state aktual kluster.

Eksperimen empiris oleh Shrestha & Ali (UCC 2024) membuktikan keunggulan konkret pendekatan ini melalui tiga skenario *configuration drift*:

### Keunggulan 1: Automated Remedy dengan Kecepatan Tinggi
Pada skenario *misconfiguration change* (replika diubah ke 0), ArgoCD melakukan pemulihan otomatis dengan *remedy time* yang **secara signifikan lebih cepat** dibanding Ansible yang membutuhkan eksekusi playbook manual. Pada skenario *dependency update*, GitOps menyelesaikan perbaikan dalam **30 detik** dibanding **~1.5 menit** untuk Ansible.

### Keunggulan 2: Reduced Attack Surface
Dengan GitOps, Jenkins cukup melakukan *build image → push ke registry → update tag di manifest Git repo*. ArgoCD yang berada **di dalam kluster** akan mendeteksi perubahan dan menarik konfigurasi baru secara mandiri. Jenkins **tidak lagi membutuhkan SSH key atau kubeconfig** untuk mengakses kluster — secara langsung menghilangkan *attack vector* terbesar pada pipeline lama kami.

### Keunggulan 3: Continuous Drift Detection & Self-Healing
ArgoCD bertindak sebagai *reconciliation loop* yang terus-menerus membandingkan state aktual kluster dengan state di Git. Jika terjadi *drift* — baik karena kesalahan manusia, serangan, atau kegagalan sistem — ArgoCD secara otomatis melakukan sinkronisasi ulang (*self-heal*). Ini menjawab gap kedua (drift tak terdeteksi) pada sistem lama kami secara fundamental.

### Keunggulan 4: Full Audit Trail via Git
Semua perubahan infrastruktur harus melalui commit di Git, memberikan rekam jejak lengkap dan memungkinkan *rollback* semudah `git revert`. Ini menegakkan prinsip *Infrastructure as Code* (IaC) secara konsisten.

---

## Referensi

- Beetz, F. & Harrer, S. (2021). GitOps: The Evolution of DevOps? *IEEE Software*. DOI: 10.1109/ms.2021.3119106
- Berton, L. (2023). Ansible for K8s Tasks. Apress. DOI: 10.1007/978-1-4842-9285-3_4
- Elradi, M.D. (2023). Ansible: A Reliable Tool for Automation. *Electrical and Computer Engineering Studies*, 2(1).
- Farayola, N.O.A. et al. (2023). Configuration Management in the Modern Era. *CS & IT Research Journal*, 4(2), 140–157.
- Gupta, S. et al. (2022). Prevalence of GitOps, DevOps in Fast CI/CD Cycles. *COM-IT-CON*, 1, 589–596.
- Shamim, S.I. (2021). Mitigating Security Attacks in Kubernetes Manifests. *ESEC/FSE*, 1243–1245.
- Shrestha, R. & Ali, A.A.N. (2024). Configuration Management in Kubernetes Environments: A GitOps Approach. *IEEE/ACM UCC 2024*. DOI: 10.1109/UCC63386.2024.00077
- Zeini, A. et al. (2023). Preliminary Investigation into a Security Approach for Infrastructure as Code. *ICICT*, 763–783.

---

---

# Policy-as-Code sebagai Komplemen GitOps: Keamanan di Layer Runtime

*(Bagian ini difokuskan pada Policy-as-Code dan Runtime Admission Control, disusun oleh Anggota 3 — Andre)*

---

## Keterbatasan Static Scanning di CI Pipeline

Pendekatan keamanan tradisional dalam pipeline DevOps berfokus pada *static scanning* di tahap *build time* — menggunakan tools seperti SonarQube (analisis kualitas kode), Trivy (vulnerability scanning pada container image), atau Snyk (dependency security). Meskipun pendekatan ini penting, ia memiliki beberapa kelemahan fundamental ketika digunakan sebagai **satu-satunya** mekanisme keamanan:

### 1. Hanya Menangkap Masalah yang Diketahui Saat Build
Static scanner hanya bisa mendeteksi *known vulnerabilities* pada saat image di-build. Jika sebuah CVE baru ditemukan setelah image sudah berada di cluster, static scanner tidak akan pernah tahu — dan pod yang sudah berjalan tidak akan diperiksa ulang secara otomatis.

### 2. Tidak Ada Enforcement di Runtime
Developer atau operator bisa saja melakukan `kubectl apply -f pod-berbahaya.yaml` **langsung ke cluster** tanpa melewati pipeline CI sama sekali. Dalam skenario ini, SonarQube dan Trivy tidak akan pernah dijalankan — dan tidak ada yang bisa mencegah pod tersebut berjalan. Ini adalah *bypass* yang sering luput dari perhatian.

### 3. Misconfiguration yang Lolos CI
Kesalahan konfigurasi manifest — seperti lupa mendefinisikan `resources.limits`, atau tidak menyetel `securityContext.runAsNonRoot: true` — tidak akan tertangkap oleh scanner vulnerability. Pod akan lulus CI, tapi berjalan dengan konfigurasi yang tidak aman di cluster.

### 4. Tidak Ada Audit Trail untuk Perubahan Runtime
Jika seseorang mengubah konfigurasi pod langsung di cluster (misalnya via `kubectl edit`), tidak ada log yang terintegrasi dengan sistem CI — perubahan tersebut tidak ter-review dan tidak ter-*audit* secara sistematis.

---

## Runtime Admission Control sebagai Komplemen

**Admission Controller** adalah mekanisme di dalam Kubernetes API server yang berfungsi sebagai *gatekeeper* — setiap permintaan untuk membuat atau mengubah resource (Pod, Deployment, ConfigMap, dll.) **wajib melewati** admission webhook sebelum diterima dan dijadwalkan. Tidak ada pengecualian: bahkan permintaan yang datang dari `kubectl apply` manual langsung oleh administrator pun harus melewati webhook ini.

**Kyverno** adalah implementasi admission controller berbasis *Policy-as-Code*:
- Kebijakan ditulis dalam format YAML — format yang sama dengan manifest Kubernetes lainnya
- Kebijakan bisa di-*version control* di Git (di-*review* via pull request, ter-audit via commit history)
- Tidak memerlukan bahasa pemrograman tambahan (berbeda dengan OPA yang menggunakan Rego)
- Mendukung dua mode: **Audit** (mencatat pelanggaran tanpa memblokir) dan **Enforce** (menolak request secara langsung)

---

## Tabel Perbandingan: Static Scanning vs Runtime Admission Control

| Aspek | Static Scanning (CI — Trivy/SonarQube) | Runtime Admission Control (Kyverno) |
|---|---|---|
| **Waktu eksekusi** | *Build time* (sebelum deploy) | *Deploy time* (saat `kubectl apply` ke cluster) |
| **Yang bisa dicegah** | Vulnerability di image dan dependency | Misconfiguration di manifest (no limits, root user, dll.) |
| **Bisa dibypass?** | Ya — jika deploy langsung tanpa melewati CI | Tidak — **semua** request melewati webhook, tanpa pengecualian |
| **Audit trail** | Log pipeline CI saja | Kyverno Policy Report + Kubernetes Event log |
| **Format kebijakan** | Tool-specific (Trivy config, SonarQube rules) | YAML native Kubernetes — bisa di-*version control* |
| **Perlindungan terhadap supply chain attack** | Parsial — hanya image yang di-scan saat build | Penuh — image registry restriction di-enforce saat deploy |
| **Remediation** | Manual — developer harus perbaiki dan rebuild | Otomatis — request ditolak, error message eksplisit |

---

## Tabel Perbandingan: Push-Based (SSH) vs Pull-Based (GitOps/ArgoCD) dari Perspektif Keamanan

Sebagai konteks tambahan dari perspektif Security Specialist, pendekatan GitOps juga menghilangkan beberapa *attack surface* yang ada di push-based:

| Aspek | Push-Based (Ansible/SSH) | Pull-Based (GitOps/ArgoCD) |
|---|---|---|
| **Trigger deploy** | Operator *run* playbook manual | ArgoCD *polling* Git otomatis |
| **Drift detection** | Tidak ada | *Continuous* — ArgoCD membandingkan state setiap siklus |
| **Remediation** | Manual, bisa 5–10 menit | Otomatis, ~30 detik [Shrestha & Ali, 2024] |
| **Audit trail** | Log Jenkins saja | Git *commit history* lengkap |
| **Kredensial ke cluster** | SSH key tersimpan di Jenkins | Tidak ada — ArgoCD yang *pull* dari dalam cluster |

---

## Mengapa `validationFailureAction: Enforce` (Bukan `Audit`)

Kyverno mendukung dua mode validasi:

- **Mode `Audit`**: Kyverno mencatat pelanggaran ke dalam *Policy Report*, namun **tidak memblokir** deployment. Pod tetap berjalan meski melanggar policy. Mode ini berguna untuk fase *discovery* — memahami seberapa banyak pelanggaran yang ada sebelum memutuskan untuk menegakkan.

- **Mode `Enforce`**: Kyverno **menolak request secara langsung** dengan status `403 Forbidden`. Pod yang melanggar policy tidak akan pernah sampai ke tahap *scheduling* — ditolak di level API server.

Kelompok kami menggunakan `Enforce` dengan alasan:

1. **Prinsip Zero Trust** [Sanghi et al., 2025]: Tidak ada entitas yang otomatis dipercaya. Setiap deployment — baik dari pipeline CI maupun `kubectl apply` manual — harus melewati validasi tanpa pengecualian.

2. **Demonstrasi yang bermakna**: Mode `Audit` tidak memberikan perlindungan nyata — ini seperti CCTV yang merekam perampokan tapi tidak ada pintu yang terkunci. Untuk keperluan evaluasi kelompok, kami perlu membuktikan bahwa policy **benar-benar memblokir**, bukan sekadar mencatat.

3. **Konsistensi dengan deployment.yaml**: Manifest milik Winduts (Anggota 2) sudah memiliki semua field yang diperlukan (`runAsNonRoot: true`, `resources.limits`, dll.), sehingga pod legitimate **tidak akan terpengaruh** oleh mode Enforce — hanya pod ilegal yang akan ditolak.

---

## Keterkaitan dengan Model Triad [Sanghi et al., 2025]

Paper [Sanghi et al., 2025] menempatkan Policy-as-Code di domain **SECURE** sebagai komponen *cross-layer enforcement* yang bekerja lintas infrastruktur, CI/CD pipeline, dan API gateway. Implementasi Kyverno kelompok kami adalah realisasi konkret dari kontribusi B paper tersebut:

> *"Implementing cross-layer Policy-as-Code uniformly across infrastructure, CI/CD pipelines, and API gateways"*

Dalam konteks kelompok kami, Kyverno beroperasi di **titik pertemuan antara domain DEVELOP dan OPERATE** — ia memvalidasi semua resource yang hendak dijalankan, apapun asalnya (dari Jenkins pipeline Fio maupun dari ArgoCD sync Winduts). Ini adalah implementasi prinsip Zero Trust di layer Kubernetes admission: tidak ada yang lolos tanpa verifikasi.

---

## Referensi Tambahan (Bagian Policy-as-Code)

- Sanghi, Sudhakaran, Koganti, Ryali (2025). DevOps and Secure Cloud-Native Architectures for Finance. *ICSIT 2025*. https://ieeexplore.ieee.org/document/11294986
- Shrestha, R. & Ali, A.A.N. (2024). Configuration Management in Kubernetes Environments: A GitOps Approach. *IEEE/ACM UCC 2024*. DOI: 10.1109/UCC63386.2024.00077
