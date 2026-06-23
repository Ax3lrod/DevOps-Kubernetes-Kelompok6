# Reading Notes: Paper 2

**Judul Paper**: DevOps and Secure Cloud-Native Architectures for Finance
**Penulis**: Sanghi, Sudhakaran, Koganti, Ryali
**Afiliasi**: Tidak disebutkan secara eksplisit — penulis dengan latar belakang industri keuangan dan cloud
**Tahun Publikasi**: 2025
**Venue Publikasi**: 2025 International Conference on Science, Innovation and Technology (ICSIT 2025)
**DOI/Link**: https://ieeexplore.ieee.org/document/11294986
**Tanggal Akses**: 21 Juni 2026

---

## 1. Klaim Utama dan Model yang Diusulkan

**Klaim Utama:** Paper ini mengklaim bahwa institusi keuangan modern membutuhkan sebuah framework terpadu yang mengintegrasikan praktik DevOps dengan arsitektur cloud-native yang aman — dan bahwa framework tersebut, jika diimplementasikan, mampu meningkatkan frekuensi deployment, mengurangi waktu pemulihan insiden, dan menekan jumlah pelanggaran keamanan secara signifikan.

**Model yang Diusulkan — Triad Domains:**

Penulis mengusulkan model **Triad Domains** yang terdiri dari tiga kolom yang bekerja secara independen namun terhubung satu sama lain:

| Domain | Fungsi | Tools/Metode |
|---|---|---|
| **DEVELOP** | CI/CD pipeline, automated testing, analisis kode | Jenkins, GitLab CI, SonarQube |
| **SECURE** | Zero Trust, policy enforcement lintas layer, runtime admission control | Kyverno, OPA, service mesh |
| **OPERATE** | Orkestrasi, monitoring, logging, automated rollback | Kubernetes, Prometheus, ELK Stack |

**Enam Kontribusi Utama Paper:**

A. **Standar keamanan industri terintegrasi**: Mengintegrasikan PCI-DSS, SOX, dan GDPR dengan metode cloud-native melalui service mesh dan Zero Trust untuk real-time auditing.

B. **Cross-layer Policy-as-Code (PaC)**: Menerapkan kebijakan keamanan secara seragam di seluruh layer — infrastruktur, CI/CD pipeline, dan API gateway — dalam format yang bisa di-*version control*.

C. **Operational intelligence berbasis AI**: Menggunakan *AI-driven anomaly detection* untuk prediksi insiden sebelum terjadi, bukan hanya reaktif setelah insiden.

D. **Modular triad subsystem**: Masing-masing domain DEVELOP, SECURE, dan OPERATE dapat di-*scale* secara independen sesuai kebutuhan organisasi.

E. **Data residency dan sovereignty controls**: Kontrol atas di mana data disimpan dan diproses dibangun sejak awal arsitektur (*by design*), bukan sebagai tambahan belakangan.

F. **Unified, cloud-agnostic platform layer**: Menggunakan Terraform, Kubernetes, dan Open Policy Agent (OPA) untuk memastikan operasi yang konsisten di lingkungan hybrid dan multi-cloud.

---

## 2. Temuan Kunci yang Relevan untuk Implementasi Kelompok

### Hasil Eksperimen Setelah Implementasi Framework

Paper melaporkan peningkatan metrik operasional yang signifikan setelah implementasi model Triad pada lingkungan eksperimen mereka:

| Metrik | Sebelum | Sesudah | Peningkatan |
|---|---|---|---|
| **Deployment Frequency** | 2×/minggu | 10×/minggu | +400% |
| **MTTR (Mean Time to Recovery)** | 14 jam | 3 jam | -78.6% |
| **Security Incidents** | 6/kuartal | 1/kuartal | -83.3% |
| **Compliance Violations** | 5/kuartal | 0/kuartal | -100% |

Angka-angka ini — khususnya penurunan *compliance violations* menjadi 0 — menjadi landasan empiris bagi kelompok kami untuk mengadopsi pendekatan Policy-as-Code di runtime, bukan hanya static scanning di CI.

### Relevansi Kontribusi B: Cross-Layer Policy-as-Code

Kontribusi B adalah yang paling langsung relevan untuk implementasi kami. Paper menekankan bahwa PaC harus diterapkan secara **seragam lintas layer**, bukan hanya di satu titik pipeline. Dalam konteks kelompok kami:

- **Layer CI** (Fio/Anggota 4): Jenkinsfile menjalankan build, test, dan push image — *shift-left* security
- **Layer Runtime** (Andre/Anggota 3): Kyverno ClusterPolicies memvalidasi setiap pod sebelum dijadwalkan ke node
- **Layer GitOps** (Winduts/Anggota 2): ArgoCD memastikan state cluster sesuai dengan manifest di Git

Ini adalah implementasi cross-layer PaC yang menjawab kontribusi B paper secara langsung.

### Relevansi Zero Trust dan Enforcement Mode

Paper menekankan prinsip **Zero Trust** — tidak ada entitas yang otomatis dipercaya, setiap akses dan setiap deployment harus divalidasi. Ini menjadi dasar keputusan kami untuk menggunakan `validationFailureAction: Enforce` (bukan `Audit`) pada semua ClusterPolicy Kyverno. Mode Audit hanya mencatat pelanggaran tanpa memblokir — ini tidak sesuai dengan Zero Trust yang mengharuskan *deny by default*.

---

## 3. Asumsi dan Keterbatasan Paper

Sesuai analisis kritis terhadap paper ini, terdapat beberapa keterbatasan yang perlu dicatat:

1. **Fokus sektor keuangan**: Model Triad dirancang untuk institusi keuangan dengan kebutuhan kepatuhan regulasi (PCI-DSS, SOX, GDPR) yang sangat spesifik. Generalisasi ke domain lain (e-commerce, startup, layanan publik) belum dibuktikan secara empiris.

2. **Sifat teoritis/proposal**: Model Triad yang diusulkan bersifat konseptual dan belum ada replikasi independen dari pihak ketiga yang memverifikasi klaim-klaimnya di lingkungan berbeda.

3. **Detail eksperimen tidak lengkap**: Paper tidak menjelaskan detail lingkungan eksperimen — cloud provider apa yang digunakan, versi Kubernetes berapa, skala cluster seperti apa — sehingga sulit untuk mereplikasi eksperimen secara tepat.

4. **Overhead performa tidak dibahas**: Paper tidak membahas biaya operasional (CPU, memori, latensi) dari menjalankan Kyverno/OPA sebagai admission controller. Ini kritis untuk cluster kecil seperti Minikube yang kami gunakan.

5. **Campuran domain yang tidak konsisten**: Beberapa metrik evaluasi dalam paper (seperti *inventory turnover* dan *forecast accuracy*) tampak lebih relevan untuk manajemen rantai pasok (*supply chain management*) daripada DevSecOps, sehingga koherensi paper sebagai karya DevOps murni perlu dipertanyakan.

---

## 4. Satu Pertanyaan dari Andre/Anggota 2

Paper mengklaim bahwa setelah implementasi framework Triad, *compliance violations* turun dari 5 per kuartal menjadi **0 per kuartal** — sebuah angka yang terdengar sangat ideal. Namun, paper **tidak mendefinisikan secara operasional** apa yang dimaksud dengan "compliance violation" dalam konteks pengukuran mereka.

Apakah "compliance violation" diukur dari:
- Log penolakan di admission webhook Kyverno/OPA?
- Hasil penetration testing eksternal?
- Audit manual oleh tim keamanan internal?
- Self-assessment berdasarkan checklist PCI-DSS/GDPR?

Tanpa definisi operasional yang jelas dan metode pengukuran yang transparan, angka **0 violation** tidak bisa diverifikasi secara ilmiah oleh peneliti lain. Ini adalah kelemahan metodologis yang signifikan, karena hasil eksperimen yang tidak dapat direplikasi tidak memenuhi standar *reproducibility* dalam penelitian rekayasa perangkat lunak.

Lebih jauh, jika "compliance violation" diukur dari log Kyverno — maka angka 0 hanya berarti tidak ada pod yang melanggar policy **yang sudah didefinisikan**, bukan berarti sistem benar-benar bebas dari seluruh risiko keamanan. Policy yang tidak lengkap atau yang tidak mencakup skenario serangan tertentu tidak akan menghasilkan log, sehingga angka 0 bisa menjadi *false positive* dari kesempurnaan.

---

## 5. Relevansi Langsung ke Implementasi Kelompok

Model Triad dari [Sanghi et al., 2025] adalah **kerangka konseptual** yang memetakan secara tepat ke struktur pembagian tugas kelompok kami:

| Domain Triad (Paper) | Implementasi Kelompok | Penanggung Jawab |
|---|---|---|
| **DEVELOP** | Jenkins CI pipeline: build, test, push image, update Git manifest | Fio (Anggota 4) |
| **SECURE** | Kyverno ClusterPolicies: runtime admission control, enforce security policies | **Andre (Anggota 3)** |
| **OPERATE** | ArgoCD: continuous sync, self-healing drift; simulate-drift: MTTR measurement | Winduts (Anggota 2) + Fikri (Anggota 5) |

**Pemetaan kontribusi paper ke keputusan implementasi:**

- **Kontribusi B (Cross-layer PaC)** → Kyverno di-enforce di semua namespace utama, bukan hanya namespace `default`. Kebijakan ditulis dalam YAML Kubernetes-native sehingga bisa di-*review* via pull request di Git — persis seperti manifest lainnya.
- **Prinsip Zero Trust** → `validationFailureAction: Enforce` pada semua tiga ClusterPolicy. Tidak ada pod yang bisa berjalan tanpa melewati validasi, apapun jalur deployment-nya (pipeline CI maupun `kubectl apply` langsung).
- **Least Privilege** → Policy `require-non-root` dan `require-resource-limits` memastikan setiap container hanya mendapat akses dan resource minimal yang diperlukan.
- **Supply Chain Security** → Policy `restrict-image-registry` memblokir image dari registry tidak terpercaya — menjawab risiko serangan rantai pasok yang semakin relevan di era container-native.

Secara keseluruhan, implementasi Kyverno kelompok kami adalah realisasi konkret dari visi **kolom SECURE** dalam model Triad yang diusulkan [Sanghi et al., 2025] — diterapkan pada skala akademis dengan Minikube, namun menggunakan prinsip dan mekanisme yang identik dengan implementasi production.

---

*Referensi: [Sanghi et al., 2025] — Sanghi, Sudhakaran, Koganti, Ryali. "DevOps and Secure Cloud-Native Architectures for Finance." 2025 International Conference on Science, Innovation and Technology (ICSIT 2025). https://ieeexplore.ieee.org/document/11294986*
