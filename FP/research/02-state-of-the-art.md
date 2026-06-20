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
