# Refleksi Kelompok

**Anggota Kelompok:**

1. [Nama Anggota 1] - Project Lead & Evaluator
2. [Nama Anggota 2] - GitOps & K8s CD Specialist
3. [Andre] - Security Policy Specialist
4. [Nama Anggota 4] - CI Pipeline Specialist
5. [Fikri] - Drift Tester & Automation
6. [Nama Anggota 6] - QA & Policy Auditor

---

## 1. Apa yang paling mengejutkan dari paper yang kamu baca — sesuatu yang berbeda dari asumsimu sebelumnya? Bagaimana temuan itu mengubah keputusan implementasimu?

_(Ditulis oleh Anggota 2 & Anggota 3)_

**Bagian Paper 1 (GitOps - Ditulis oleh Anggota 2):**
Hal yang paling mengejutkan dari paper "Configuration Management in Kubernetes Environments: A GitOps Approach" (Shrestha & Ali, 2024) adalah perbedaan drastis pada metrik "Remedy Time" antara pendekatan GitOps (ArgoCD) dibandingkan dengan eksekusi skrip imperatif tradisional (Ansible) saat menghadapi skenario _misconfiguration change_ (misalnya mengubah _replica count_ ke 0). Sebelum membaca paper ini, asumsi saya adalah fungsi utama GitOps hanyalah memudahkan deployment terpusat dari Git dan menghindari menyimpan kubeconfig di CI (Jenkins). Saya awalnya menganggap jika terjadi _drift_, sistem monitoring (seperti Prometheus) akan mengirim notifikasi ke SRE, lalu SRE akan _trigger_ ulang deployment untuk memperbaikinya secara manual.

Namun, paper tersebut membuktikan bahwa berkat integrasi ArgoCD yang bertindak sebagai _continuous reconciliation loop_, waktu pemulihan (_remedy time_) sebuah insiden drift dapat dipangkas menjadi hanya hitungan detik tanpa intervensi manusia, jauh mengalahkan waktu bermenit-menit yang dibutuhkan metode _push_ untuk sekadar mengeksekusi perbaikan. Temuan ini langsung mengubah keputusan arsitektur implementasi saya: saya yang semula hanya berencana mensetup ArgoCD untuk _sync_ manual, kini secara eksplisit mewajibkan dan mengaktifkan fitur `selfHeal: true` pada manifest `application.yaml`. Selain itu, temuan ini meyakinkan kelompok kami untuk fokus mendemonstrasikan kapabilitas _auto-healing_ instan ini sebagai metrik evaluasi utama pada sesi presentasi nanti, yang akan diuji secara otomatis oleh skrip dari Anggota 5.

**Bagian Paper 2 (Policy-as-Code - Ditulis oleh Anggota 3 / Andre):**

Hal yang paling mengejutkan dari paper "DevOps and Secure Cloud-Native Architectures for Finance" [Sanghi dkk., 2025] adalah betapa paper ini secara eksplisit menekankan bahwa **pipeline CI yang baik saja tidak cukup** untuk menjamin keamanan sistem — dan bahwa runtime enforcement bukan sekadar "nice to have", melainkan komponen **wajib** dari arsitektur DevSecOps yang matang.

Sebelum membaca paper ini, asumsi saya — dan mungkin banyak praktisi DevOps lainnya — adalah bahwa jika sebuah image sudah melewati static scanning (Trivy untuk vulnerability, SonarQube untuk kualitas kode), maka keamanannya sudah terjamin. Logikanya masuk akal: cegah masalah di hulu, sebelum container sempat berjalan. Namun, paper [Sanghi dkk., 2025] membuka perspektif yang jauh lebih kritis melalui model Triad mereka, khususnya domain **SECURE** yang menekankan _cross-layer Policy-as-Code_.

Masalah fundamental yang paper soroti adalah: **siapa yang menjaga pintu cluster setelah CI selesai?** Developer atau operator bisa saja melakukan `kubectl apply -f pod-tanpa-limit.yaml` langsung ke cluster, melewati seluruh pipeline CI beserta semua scannernya. Dalam skenario ini, tidak ada Trivy, tidak ada SonarQube — dan tidak ada yang mencegah pod tersebut berjalan dengan konfigurasi berbahaya (berjalan sebagai root, tanpa resource limits, menggunakan image dari registry tidak dikenal).

Temuan ini langsung mengubah keputusan implementasi saya secara fundamental: saya yang semula mempertimbangkan mode `Audit` untuk Kyverno — yang hanya _mencatat_ pelanggaran tanpa memblokir — segera menyadari bahwa mode tersebut tidak memberikan perlindungan nyata. Mode Audit seperti memasang CCTV di dalam bank tapi membiarkan pintu brankas tidak terkunci. Itu mungkin berguna untuk forensik _setelah_ insiden, tapi tidak mencegah insiden itu sendiri. Akhirnya saya memutuskan menggunakan `validationFailureAction: Enforce` pada semua tiga ClusterPolicy — memastikan setiap pod yang melanggar policy langsung ditolak di level API server dengan status `403 Forbidden`.

Keputusan ini juga memperkuat sinergi dengan implementasi Winduts (Anggota 2). ArgoCD menjaga _desired state_ di layer Kubernetes manifests — jika seseorang mengubah replika secara manual, ArgoCD mengembalikannya dalam ~30 detik. Kyverno bekerja di layer sebelumnya: memastikan bahwa resource yang hendak dibuat dari awal sudah memenuhi standar keamanan, terlepas dari jalur deployment-nya. Kedua mekanisme ini saling **mengisi celah yang tidak bisa diisi oleh yang lain** — sebuah implementasi _defense in depth_ yang langsung terinspirasi dari visi model Triad [Sanghi dkk., 2025].

Hasil eksperimen paper yang melaporkan _compliance violations_ turun dari 5 ke **0 per kuartal** setelah implementasi framework ini semakin meyakinkan saya bahwa pendekatan berlapis (GitOps + Policy-as-Code) adalah yang tepat untuk kelompok kami, meskipun saya tetap mempertanyakan bagaimana paper mendefinisikan dan mengukur "violation" tersebut secara operasional.

---

## 2. Di mana implementasimu berbeda dari yang diusulkan paper, dan mengapa? Apakah karena keterbatasan waktu/resources, atau karena kamu tidak setuju dengan pendekatannya?

_(Ditulis oleh Anggota 4 & Anggota 5)_

**Bagian Drift Testing & Automation (Ditulis oleh Anggota 5 / Fikri):**

Dalam konteks pengujian komparatif dan pembuktian keandalan sistem, implementasi riil yang kami lakukan di atas kluster K3s VPS Kelompok 6 memiliki perbedaan operasional yang cukup signifikan jika disandingkan dengan metodologi eksperimen ideal yang dipaparkan dalam Paper 1 (Shrestha & Ali, 2024). Pada Paper 1, proses evaluasi configuration drift dan penghitungan Remedy Time (MTTR) diasumsikan berjalan pada infrastruktur berskala industri dengan ketersediaan kapasitas komputasi yang melimpah dan lingkungan monitoring terisolasi. Dalam kondisi teoretis tersebut, interval waktu pengecekan (polling interval) sinkronisasi data dapat diatur sekerap mungkin tanpa berisiko menurunkan stabilitas kinerja kluster secara keseluruhan.

Namun, pada realitas praktisnya, kelompok kami menghadapi keterbatasan sumber daya komputasi yang nyata karena harus menjalankan seluruh komponen, mulai dari beban kerja aplikasi TaskFlow, kontroler ArgoCD, hingga admission webhook Kyverno, di atas server VPS lokal dengan spesifikasi yang sangat terbatas. Tantangan teknis utama yang saya hadapi selaku pembuat skrip otomatisasi `simulate-drift1.ps1` adalah menyiasati pengaturan interval rekonsiliasi bawaan (default resync timeout) milik ArgoCD yang secara standar membutuhkan waktu hingga 180 detik (3 menit) untuk memindai perubahan status manifes di repositori GitHub. Jika kami membiarkan pengaturan standar ini berjalan sesuai teori paper, siklus tunggu pemulihan otomatis pada sesi live demo berdurasi 20 menit di depan dosen akan menjadi sangat tidak efisien dan menghabiskan sisa waktu presentasi kelompok.

Untuk mengatasi hambatan tersebut, kami terpaksa mengambil pendekatan kompromi dengan memodifikasi konfigurasi internal kontroler ArgoCD (pada ConfigMap `argocd-cm`) agar melakukan polling secara jauh lebih agresif. Hasilnya, skrip otomatisasi yang saya jalankan berhasil mencatat waktu pemulihan otomatis (Remedy Time) yang sangat instan, yaitu sebesar 4.234 detik setelah objek deployment dihancurkan secara sengaja. Perbedaan taktis ini membuktikan bahwa penerapan teori akademis di dunia nyata tidak selalu dapat ditelan mentah-mentah; engineer harus mampu melakukan penyesuaian konfigurasi yang relevan demi menyelaraskan kesenjangan antara tuntutan skenario uji dengan keterbatasan infrastruktur yang tersedia di lapangan.

---

## 3. Jika kamu punya waktu satu bulan penuh dan akses ke production cluster nyata, apa yang akan kamu lakukan berbeda atau tambahkan? Gunakan paper sebagai landasan argumenmu.

_(Ditulis oleh Anggota 1 & Anggota 6)_
_(Menunggu kontribusi penulisan dari Anggota 1 dan Anggota 6)_
