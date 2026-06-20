# Refleksi Kelompok

**Anggota Kelompok:**
1. [Nama Anggota 1] - Project Lead & Evaluator
2. [Nama Anggota 2] - GitOps & K8s CD Specialist
3. [Nama Anggota 3] - Security Policy Specialist
4. [Nama Anggota 4] - CI Pipeline Specialist
5. [Nama Anggota 5] - Drift Tester & Automation
6. [Nama Anggota 6] - QA & Policy Auditor

---

## 1. Apa yang paling mengejutkan dari paper yang kamu baca — sesuatu yang berbeda dari asumsimu sebelumnya? Bagaimana temuan itu mengubah keputusan implementasimu?

*(Ditulis oleh Anggota 2 & Anggota 3)*

**Bagian Paper 1 (GitOps - Ditulis oleh Anggota 2):**
Hal yang paling mengejutkan dari paper "Configuration Management in Kubernetes Environments: A GitOps Approach" (Shrestha & Ali, 2024) adalah perbedaan drastis pada metrik "Remedy Time" antara pendekatan GitOps (ArgoCD) dibandingkan dengan eksekusi skrip imperatif tradisional (Ansible) saat menghadapi skenario *misconfiguration change* (misalnya mengubah *replica count* ke 0). Sebelum membaca paper ini, asumsi saya adalah fungsi utama GitOps hanyalah memudahkan deployment terpusat dari Git dan menghindari menyimpan kubeconfig di CI (Jenkins). Saya awalnya menganggap jika terjadi *drift*, sistem monitoring (seperti Prometheus) akan mengirim notifikasi ke SRE, lalu SRE akan *trigger* ulang deployment untuk memperbaikinya secara manual.

Namun, paper tersebut membuktikan bahwa berkat integrasi ArgoCD yang bertindak sebagai *continuous reconciliation loop*, waktu pemulihan (*remedy time*) sebuah insiden drift dapat dipangkas menjadi hanya hitungan detik tanpa intervensi manusia, jauh mengalahkan waktu bermenit-menit yang dibutuhkan metode *push* untuk sekadar mengeksekusi perbaikan. Temuan ini langsung mengubah keputusan arsitektur implementasi saya: saya yang semula hanya berencana mensetup ArgoCD untuk *sync* manual, kini secara eksplisit mewajibkan dan mengaktifkan fitur `selfHeal: true` pada manifest `application.yaml`. Selain itu, temuan ini meyakinkan kelompok kami untuk fokus mendemonstrasikan kapabilitas *auto-healing* instan ini sebagai metrik evaluasi utama pada sesi presentasi nanti, yang akan diuji secara otomatis oleh skrip dari Anggota 5.

**Bagian Paper 2 (Policy-as-Code - Ditulis oleh Anggota 3):**
*(Menunggu kontribusi penulisan refleksi dari Anggota 3 terkait paper Kyverno/Policy-as-Code)*

---

## 2. Di mana implementasimu berbeda dari yang diusulkan paper, dan mengapa? Apakah karena keterbatasan waktu/resources, atau karena kamu tidak setuju dengan pendekatannya?

*(Ditulis oleh Anggota 4 & Anggota 5)*
*(Menunggu kontribusi penulisan dari Anggota 4 dan Anggota 5)*

---

## 3. Jika kamu punya waktu satu bulan penuh dan akses ke production cluster nyata, apa yang akan kamu lakukan berbeda atau tambahkan? Gunakan paper sebagai landasan argumenmu.

*(Ditulis oleh Anggota 1 & Anggota 6)*
*(Menunggu kontribusi penulisan dari Anggota 1 dan Anggota 6)*
