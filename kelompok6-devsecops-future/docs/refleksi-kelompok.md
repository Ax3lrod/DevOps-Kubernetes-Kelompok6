# Refleksi Kelompok

**Anggota Kelompok:**

1. [Aryasatya Alaauddin] - Project Lead & Evaluator
2. [Harwinda] - GitOps & K8s CD Specialist
3. [Andre] - Security Policy Specialist
4. [Fiorenza Adelia Nalle] - CI Pipeline Specialist
5. [Fikri] - Drift Tester & Automation
6. [Kris] - QA & Policy Auditor

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

Implementasi infrastruktur Kubernetes dan penegakan kebijakan keamanan dalam proyek kami mengalami sejumlah penyederhanaan yang cukup signifikan jika dibandingkan dengan model ideal pada kedua paper. Paper 1 (Shrestha & Ali, 2024) mengusulkan integrasi monitoring stack yang kompleks seperti Prometheus dan Grafana untuk mendukung observabilitas drift secara real-time, sementara Paper 2 (Sanghi et al., 2025) memperkenalkan pendekatan keamanan tingkat lanjut berbasis AI-driven anomaly detection dan blockchain dalam konteks Zero Trust. Dalam implementasi kami, komponen-komponen tersebut tidak digunakan dan digantikan dengan pendekatan yang lebih ringan (Lean Kubernetes). Keputusan ini terutama dipengaruhi oleh keterbatasan sumber daya RAM pada VPS K3s yang digunakan serta pertimbangan efisiensi waktu pengembangan. Menjalankan monitoring stack maupun komponen berbasis AI berpotensi menimbulkan risiko Out-of-Memory (OOM) yang dapat mengganggu stabilitas seluruh sistem TaskFlow. Sebagai alternatif, kami mengandalkan mekanisme deteksi internal ArgoCD melalui status OutOfSync serta penerapan Policy-as-Code (PaC) menggunakan Kyverno yang bersifat lebih ringan dan deterministik. Dengan pendekatan ini, prinsip utama GitOps dan keamanan runtime tetap dapat dipertahankan tanpa harus mengadopsi kompleksitas penuh seperti yang diusulkan dalam literatur.

Dari sisi orkestrasi pipeline, implementasi Jenkins yang kami gunakan juga memiliki perbedaan dibandingkan skenario otomatisasi yang diasumsikan dalam kedua paper. Paper 1 dan Paper 2 umumnya mengasumsikan penggunaan mekanisme otomatis seperti ArgoCD Image Updater yang dapat mendeteksi perubahan image di registry dan memperbarui manifest tanpa intervensi CI. Namun, dalam implementasi ini, Jenkins masih kami desain untuk secara eksplisit melakukan proses pembaruan manifest melalui tahapan modifikasi file, dan push kembali ke Git repository. Pendekatan ini dipilih bukan untuk menolak otomatisasi penuh, melainkan untuk menyeimbangkan antara otomatisasi dan kebutuhan transparansi sistem. Dengan setiap perubahan versi image direpresentasikan sebagai commit di Git, kami memperoleh jejak audit yang jelas dalam bentuk commit SHA. Hal ini memudahkan proses pelacakan, rollback, serta debugging apabila terjadi kegagalan deployment, khususnya dalam konteks pengembangan akademik yang membutuhkan visibilitas tinggi terhadap setiap perubahan sistem.

**Bagian Drift Testing & Automation:**

Dalam konteks pengujian komparatif dan pembuktian keandalan sistem, implementasi riil yang kami lakukan di atas kluster K3s VPS Kelompok 6 memiliki perbedaan operasional yang cukup signifikan jika disandingkan dengan metodologi eksperimen ideal yang dipaparkan dalam Paper 1 (Shrestha & Ali, 2024). Pada Paper 1, proses evaluasi configuration drift dan penghitungan Remedy Time (MTTR) diasumsikan berjalan pada infrastruktur berskala industri dengan ketersediaan kapasitas komputasi yang melimpah dan lingkungan monitoring terisolasi. Dalam kondisi teoretis tersebut, interval waktu pengecekan (polling interval) sinkronisasi data dapat diatur sekerap mungkin tanpa berisiko menurunkan stabilitas kinerja kluster secara keseluruhan.

Namun, pada realitas praktisnya, kelompok kami menghadapi keterbatasan sumber daya komputasi yang nyata karena harus menjalankan seluruh komponen, mulai dari beban kerja aplikasi TaskFlow, kontroler ArgoCD, hingga admission webhook Kyverno, di atas server VPS lokal dengan spesifikasi yang sangat terbatas. Tantangan teknis utama yang saya hadapi selaku pembuat skrip otomatisasi `simulate-drift1.ps1` adalah menyiasati pengaturan interval rekonsiliasi bawaan (default resync timeout) milik ArgoCD yang secara standar membutuhkan waktu hingga 180 detik (3 menit) untuk memindai perubahan status manifes di repositori GitHub. Jika kami membiarkan pengaturan standar ini berjalan sesuai teori paper, siklus tunggu pemulihan otomatis pada sesi live demo berdurasi 20 menit di depan dosen akan menjadi sangat tidak efisien dan menghabiskan sisa waktu presentasi kelompok.

Untuk mengatasi hambatan tersebut, kami terpaksa mengambil pendekatan kompromi dengan memodifikasi konfigurasi internal kontroler ArgoCD (pada ConfigMap `argocd-cm`) agar melakukan polling secara jauh lebih agresif. Hasilnya, skrip otomatisasi yang saya jalankan berhasil mencatat waktu pemulihan otomatis (Remedy Time) yang sangat instan, yaitu sebesar 2.038 detik setelah objek deployment dihancurkan secara sengaja. Perbedaan taktis ini membuktikan bahwa penerapan teori akademis di dunia nyata tidak selalu dapat ditelan mentah-mentah; engineer harus mampu melakukan penyesuaian konfigurasi yang relevan demi menyelaraskan kesenjangan antara tuntutan skenario uji dengan keterbatasan infrastruktur yang tersedia di lapangan.

---

## 3. Jika kamu punya waktu satu bulan penuh dan akses ke production cluster nyata, apa yang akan kamu lakukan berbeda atau tambahkan? Gunakan paper sebagai landasan argumenmu.

_(Ditulis oleh Anggota 1 & Anggota 6)_
_(Menunggu kontribusi penulisan dari Anggota 1 dan Anggota 6)_
**Refleksi Kelompok — Pertanyaan 3**
**Bagian QA (Ditulis oleh Anggota 6)**
Rencana Jika Ada Waktu 1 Bulan & Kluster Produksi
Kyverno dan ArgoCD yang sudah kami implementasikan berhasil menjawab dua
masalah inti: mencegah konfigurasi berbahaya lolos ke cluster (Kyverno) dan
memastikan state cluster selalu sesuai dengan Git (ArgoCD). Namun, dari sudut
pandang QA dan audit kepatuhan, ada satu gap besar yang belum tersentuh:
observability terhadap apa yang sebenarnya terjadi di dalam cluster setelah
sebuah Pod berhasil di-deploy.

Saat ini, pengujian kami sebatas memverifikasi bahwa admission webhook
menolak/menerima Pod pada titik deployment (point-in-time check). Tapi di
lingkungan produksi nyata, terutama untuk kasus finansial seperti yang dibahas
Paper 2, regulator dan auditor biasanya tidak hanya bertanya "apakah kontrol
keamanan ada?", melainkan "bisakah kamu membuktikan, untuk setiap request yang
masuk, siapa yang mengaksesnya, lewat service apa, dan apakah ada anomali?".
Inilah yang tidak bisa dijawab oleh Kyverno maupun ArgoCD — keduanya bekerja di
level konfigurasi/deployment, bukan di level request-flow antar service saat
runtime.

Jika diberi waktu satu bulan dengan akses ke kluster produksi, hal pertama yang
akan kami tambahkan adalah distributed tracing (misalnya OpenTelemetry yang
diekspor ke Jaeger atau Grafana Tempo). Dengan ini, setiap request ke API
TaskFlow dapat dilacak end-to-end: dari masuk ke ingress, diteruskan ke Pod
mana, query database apa yang dijalankan, hingga response dikembalikan —
lengkap dengan trace ID yang bisa dikorelasikan dengan log Kyverno (siapa yang
mencoba deploy apa) dan riwayat sync ArgoCD (kapan konfigurasi berubah).

Manfaat konkretnya untuk audit:
Korelasi insiden: jika ada anomali (misalnya latency tiba-tiba naik atau
error rate melonjak), tim bisa langsung menelusuri apakah itu berkorelasi
dengan perubahan konfigurasi terakhir yang disetujui Kyverno/ArgoCD.
Bukti kepatuhan berkelanjutan: berbeda dengan test Kyverno kami yang
sifatnya snapshot (diuji sekali saat demo), tracing memberi bukti kepatuhan
yang berjalan terus-menerus, bukan hanya pada saat audit dijadwalkan.
Deteksi drift di level perilaku, bukan hanya konfigurasi — ArgoCD
mendeteksi drift pada state (replika, manifest), tapi tidak mendeteksi
jika sebuah service mulai berperilaku abnormal walau konfigurasinya tetap
sesuai Git.

Selain tracing, kami juga akan mempertimbangkan integrasi dengan tools seperti
Falco untuk runtime security monitoring (melengkapi Kyverno yang sifatnya
preventif di admission time, dengan deteksi di level syscall saat container
sudah berjalan) — namun ini menjadi prioritas kedua setelah tracing, karena
tracing memberi fondasi observability yang lebih mendasar untuk kebutuhan audit
jangka panjang.
