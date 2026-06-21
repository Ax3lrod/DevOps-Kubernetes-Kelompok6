# Refleksi Kelompok

**Anggota Kelompok:**
1. [Nama Anggota 1] - Project Lead & Evaluator
2. [Nama Anggota 2] - GitOps & K8s CD Specialist
3. [Andre] - Security Policy Specialist
4. [Nama Anggota 4] - CI Pipeline Specialist
5. [Nama Anggota 5] - Drift Tester & Automation
6. [Nama Anggota 6] - QA & Policy Auditor

---

## 1. Apa yang paling mengejutkan dari paper yang kamu baca — sesuatu yang berbeda dari asumsimu sebelumnya? Bagaimana temuan itu mengubah keputusan implementasimu?

*(Ditulis oleh Anggota 2 & Anggota 3)*

**Bagian Paper 1 (GitOps - Ditulis oleh Anggota 2):**
Hal yang paling mengejutkan dari paper "Configuration Management in Kubernetes Environments: A GitOps Approach" (Shrestha & Ali, 2024) adalah perbedaan drastis pada metrik "Remedy Time" antara pendekatan GitOps (ArgoCD) dibandingkan dengan eksekusi skrip imperatif tradisional (Ansible) saat menghadapi skenario *misconfiguration change* (misalnya mengubah *replica count* ke 0). Sebelum membaca paper ini, asumsi saya adalah fungsi utama GitOps hanyalah memudahkan deployment terpusat dari Git dan menghindari menyimpan kubeconfig di CI (Jenkins). Saya awalnya menganggap jika terjadi *drift*, sistem monitoring (seperti Prometheus) akan mengirim notifikasi ke SRE, lalu SRE akan *trigger* ulang deployment untuk memperbaikinya secara manual.

Namun, paper tersebut membuktikan bahwa berkat integrasi ArgoCD yang bertindak sebagai *continuous reconciliation loop*, waktu pemulihan (*remedy time*) sebuah insiden drift dapat dipangkas menjadi hanya hitungan detik tanpa intervensi manusia, jauh mengalahkan waktu bermenit-menit yang dibutuhkan metode *push* untuk sekadar mengeksekusi perbaikan. Temuan ini langsung mengubah keputusan arsitektur implementasi saya: saya yang semula hanya berencana mensetup ArgoCD untuk *sync* manual, kini secara eksplisit mewajibkan dan mengaktifkan fitur `selfHeal: true` pada manifest `application.yaml`. Selain itu, temuan ini meyakinkan kelompok kami untuk fokus mendemonstrasikan kapabilitas *auto-healing* instan ini sebagai metrik evaluasi utama pada sesi presentasi nanti, yang akan diuji secara otomatis oleh skrip dari Anggota 5.

**Bagian Paper 2 (Policy-as-Code - Ditulis oleh Anggota 3 / Andre):**

Hal yang paling mengejutkan dari paper "DevOps and Secure Cloud-Native Architectures for Finance" [Sanghi dkk., 2025] adalah betapa paper ini secara eksplisit menekankan bahwa **pipeline CI yang baik saja tidak cukup** untuk menjamin keamanan sistem — dan bahwa runtime enforcement bukan sekadar "nice to have", melainkan komponen **wajib** dari arsitektur DevSecOps yang matang.

Sebelum membaca paper ini, asumsi saya — dan mungkin banyak praktisi DevOps lainnya — adalah bahwa jika sebuah image sudah melewati static scanning (Trivy untuk vulnerability, SonarQube untuk kualitas kode), maka keamanannya sudah terjamin. Logikanya masuk akal: cegah masalah di hulu, sebelum container sempat berjalan. Namun, paper [Sanghi dkk., 2025] membuka perspektif yang jauh lebih kritis melalui model Triad mereka, khususnya domain **SECURE** yang menekankan *cross-layer Policy-as-Code*.

Masalah fundamental yang paper soroti adalah: **siapa yang menjaga pintu cluster setelah CI selesai?** Developer atau operator bisa saja melakukan `kubectl apply -f pod-tanpa-limit.yaml` langsung ke cluster, melewati seluruh pipeline CI beserta semua scannernya. Dalam skenario ini, tidak ada Trivy, tidak ada SonarQube — dan tidak ada yang mencegah pod tersebut berjalan dengan konfigurasi berbahaya (berjalan sebagai root, tanpa resource limits, menggunakan image dari registry tidak dikenal).

Temuan ini langsung mengubah keputusan implementasi saya secara fundamental: saya yang semula mempertimbangkan mode `Audit` untuk Kyverno — yang hanya *mencatat* pelanggaran tanpa memblokir — segera menyadari bahwa mode tersebut tidak memberikan perlindungan nyata. Mode Audit seperti memasang CCTV di dalam bank tapi membiarkan pintu brankas tidak terkunci. Itu mungkin berguna untuk forensik *setelah* insiden, tapi tidak mencegah insiden itu sendiri. Akhirnya saya memutuskan menggunakan `validationFailureAction: Enforce` pada semua tiga ClusterPolicy — memastikan setiap pod yang melanggar policy langsung ditolak di level API server dengan status `403 Forbidden`.

Keputusan ini juga memperkuat sinergi dengan implementasi Winduts (Anggota 2). ArgoCD menjaga *desired state* di layer Kubernetes manifests — jika seseorang mengubah replika secara manual, ArgoCD mengembalikannya dalam ~30 detik. Kyverno bekerja di layer sebelumnya: memastikan bahwa resource yang hendak dibuat dari awal sudah memenuhi standar keamanan, terlepas dari jalur deployment-nya. Kedua mekanisme ini saling **mengisi celah yang tidak bisa diisi oleh yang lain** — sebuah implementasi *defense in depth* yang langsung terinspirasi dari visi model Triad [Sanghi dkk., 2025].

Hasil eksperimen paper yang melaporkan *compliance violations* turun dari 5 ke **0 per kuartal** setelah implementasi framework ini semakin meyakinkan saya bahwa pendekatan berlapis (GitOps + Policy-as-Code) adalah yang tepat untuk kelompok kami, meskipun saya tetap mempertanyakan bagaimana paper mendefinisikan dan mengukur "violation" tersebut secara operasional.

---

## 2. Di mana implementasimu berbeda dari yang diusulkan paper, dan mengapa? Apakah karena keterbatasan waktu/resources, atau karena kamu tidak setuju dengan pendekatannya?

*(Ditulis oleh Anggota 4 & Anggota 5)*
*(Menunggu kontribusi penulisan dari Anggota 4 dan Anggota 5)*

---

## 3. Jika kamu punya waktu satu bulan penuh dan akses ke production cluster nyata, apa yang akan kamu lakukan berbeda atau tambahkan? Gunakan paper sebagai landasan argumenmu.

*(Ditulis oleh Anggota 1 & Anggota 6)*
*(Menunggu kontribusi penulisan dari Anggota 1 dan Anggota 6)*
