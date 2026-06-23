# Rekomendasi Detail Kerja & Alur Pengerjaan Kelompok 6 — DevOps Final Project

Dokumen ini disusun untuk membagi tanggung jawab secara adil, di mana setiap anggota kelompok mendapatkan peran **Implementasi Teknis (Coding/Setup)** dan **Riset/Dokumentasi (Markdown)**. Nama anggota ditulis sebagai placeholder (**Anggota 1** hingga **Anggota 6**) agar kelompok Anda dapat berdiskusi dan memilih sendiri siapa yang memegang peran tersebut.

---

## 📋 Tabel Pembagian Peran & Tanggung Jawab Terintegrasi

| Anggota | Peran Teknis | Fokus Tugas Implementasi 🛠️ | Tugas Riset & Dokumentasi (Markdown) 📝 |
| :--- | :--- | :--- | :--- |
| **Anggota 1** | *Project Lead & Evaluator* | Mengintegrasikan seluruh kode manifest, memvalidasi kelancaran setup keseluruhan, dan memimpin demo live. | * Menulis `evaluation/analysis.md` (Analisis data & grafik perbandingan)<br>* Menyusun slide presentasi (`presentation/slides.pdf`) |
| **Anggota 2** | *GitOps & K8s CD Specialist* | Menulis manifest Kubernetes TaskFlow (`implementation/kubernetes/deployment.yaml` & `service.yaml`) yang aman (limits, non-root). | * Menulis review Paper 1 di `papers/paper-1-gitops-drift.md`<br>* Menyusun bagian GitOps di `research/02-state-of-the-art.md` |
| **Anggota 3** | *Security Policy Specialist* | Menginstal Kyverno dan menulis manifest ClusterPolicies keamanan kontainer (`implementation/kyverno/policies.yaml`). | * Menulis review Paper 2 di `papers/paper-2-secure-finance.md`<br>* Menyusun bagian Policy-as-Code di `research/02-state-of-the-art.md` |
| **Anggota 4** | *CI Pipeline Specialist* | Mengubah pipeline `Jenkinsfile` (mengganti deploy SSH lama dengan automasi update tag di Git config repo). | * Menulis analisis kelemahan sistem lama di `research/01-gap-analysis.md`<br>* Menulis panduan instalasi di `README.md` |
| **Anggota 5** | *Drift Tester & Automation* | Membuat skrip automasi pengujian drift dan penghitung MTTR otomatis (`implementation/scripts/simulate-drift.ps1`). | * Menulis data baseline sebelum peningkatan di `evaluation/metrics-before.md`<br>* Menulis justifikasi desain GitOps di `research/03-design-decisions.md` |
| **Anggota 6** | *QA & Policy Auditor* | Membuat manifest/skrip uji coba pemblokiran Kyverno (mencoba deploy kontainer ilegal: root user / no limits). | * Menulis data pasca-peningkatan di `evaluation/metrics-after.md`<br>* Menulis justifikasi desain Kyverno di `research/03-design-decisions.md` |

---

## 📅 Alur Kronologis Pengerjaan (Step-by-Step Workflow)

Ikuti urutan langkah di bawah ini untuk menghindari hambatan pengerjaan (*blocking tasks*):

```
HARI 1 - 2 (Riset & Inisiasi)
  ├── 1. Anggota 2 & Anggota 3: Mulai membaca Paper 1 & 2 dan tulis ringkasan di papers/
  ├── 2. Anggota 4: Menganalisis sistem Tugas 3 lama & menulis research/01-gap-analysis.md
  └── 3. Anggota 5 & Anggota 2: Setup kluster Kubernetes & install ArgoCD dan Kyverno
                                 ▲
HARI 3 (Implementasi Konfigurasi)│
  ├── 4. Anggota 2: Menulis deployment.yaml & service.yaml di implementation/kubernetes/
  │                   │
  │                   ▼ (Menunggu deployment.yaml selesai)
  ├── 5. Anggota 3: Menulis ClusterPolicies di implementation/kyverno/policies.yaml
  └── 6. Anggota 5: Mencatat data baseline manual di evaluation/metrics-before.md
                                 ▲
HARI 4 (Integrasi Pipeline)      │
  ├── 7. Anggota 4: Memodifikasi Jenkinsfile untuk beralih ke Git-commit & push CD
  └── 8. Anggota 1: Membantu verifikasi koneksi webhook Jenkins & Git configs
                                 ▲
HARI 5 (Pengujian & QA)          │
  ├── 9. Anggota 5: Jalankan simulate-drift.ps1 untuk ukur Remedy Time ArgoCD
  ├── 10. Anggota 6: Deploy Pod ilegal untuk uji pemblokiran Kyverno
  └── 11. Anggota 6: Mencatat log sukses pengujian di evaluation/metrics-after.md
                                 ▲
HARI 6 - 7 (Analisis & Finalisasi)│
  ├── 12. Anggota 1: Menulis evaluation/analysis.md & membuat slide presentasi
  ├── 13. Seluruh Anggota: Menulis porsi jawaban refleksi-kelompok.md masing-masing
  └── 14. Anggota 4 & Anggota 1: Final check README.md & demo setup
```

---

## ✍️ Pembagian Penulisan Refleksi Kelompok (`docs/refleksi-kelompok.md`)
Dokumen refleksi memuat tiga pertanyaan wajib yang dijawab secara kolaboratif (masing-masing minimal 250 kata):

1. **Pertanyaan 1 (Hal mengejutkan dari paper & dampaknya)**:
   * **Ditulis oleh**: **Anggota 2 & Anggota 3** (selaku pembaca utama paper).
2. **Pertanyaan 2 (Perbedaan implementasi kita vs usulan paper)**:
   * **Ditulis oleh**: **Anggota 4 & Anggota 5** (selaku implementer pipeline & simulator drift yang mengalami kendala teknis nyata).
3. **Pertanyaan 3 (Rencana jika ada waktu 1 bulan & kluster produksi)**:
   * **Ditulis oleh**: **Anggota 1 & Anggota 6** (selaku koordinator dan QA yang memandang dari sisi kualitas dan roadmap jangka panjang).

---

## 🛠️ Detail Spesifik Deskripsi Tugas (Job Description)

### 👤 Anggota 1: Project Lead & Evaluator (PM & Slides Coordinator)
* **Detail Tugas Implementasi (Teknis)**:
  * Melakukan review struktur folder akhir untuk memastikan tidak ada file konfigurasi yang tertinggal atau salah tempat.
  * Mengintegrasikan presentasi akhir dan mengoordinasikan waktu latihan demo presentasi berdurasi 20 menit (4 menit Paper, 8 menit Demo, 5 menit Evaluasi, 3 menit Q&A).
* **Detail Tugas Riset & Dokumentasi (Markdown)**:
  * **Menulis `evaluation/analysis.md`**: Membandingkan durasi remediasi drift baseline (manual) dengan pasca-peningkatan (ArgoCD), menyusun visualisasi diagram/grafik ASCII/mermaid, dan menarik kesimpulan berdasarkan data simulasi.
  * **Menyusun Slide Presentasi (`presentation/slides.pdf`)**: Merancang slide yang memuat latar belakang, gap, usulan arsitektur, demo, hasil evaluasi data nyata, dan refleksi.
  * **Refleksi Kelompok (Pertanyaan 3)**: Menulis rencana perluasan arsitektur dalam waktu 1 bulan di lingkungan produksi (Istio service mesh, mTLS, canary deployment).

### 👤 Anggota 2: GitOps & K8s CD Specialist
* **Detail Tugas Implementasi (Teknis)**:
  * Membuat file `implementation/kubernetes/deployment.yaml`. Kontainer harus menggunakan base image TaskFlow (`fikriau/taskflow-api:stable`), mengekspos port internal, memiliki konfigurasi `readOnlyRootFilesystem: true`, dan wajib mendefinisikan `resources` limits & requests secara spesifik (cpu & memori).
  * Membuat file `implementation/kubernetes/service.yaml` untuk mengekspos aplikasi secara internal di kluster.
  * Melakukan inisiasi awal ArgoCD Application manifest di `implementation/argocd/application.yaml` yang mengarah ke folder manifest.
* **Detail Tugas Riset & Dokumentasi (Markdown)**:
  * **Menulis `papers/paper-1-gitops-drift.md`**: Menyusun reading notes ilmiah untuk Paper 1 (OsloMet UCC 2024).
  * **Menulis `research/02-state-of-the-art.md` (Bagian GitOps)**: Membahas keunggulan pull-based GitOps dibanding push-based Ansible/SSH.
  * **Refleksi Kelompok (Pertanyaan 1 - Bagian Paper 1)**: Menjelaskan temuan tak terduga tentang efisiensi auto-healing ArgoCD.

### 👤 Anggota 3: Security Policy Specialist
* **Detail Tugas Implementasi (Teknis)**:
  * Menginstal Kyverno di kluster Kubernetes menggunakan Helm (`helm install kyverno kyverno/kyverno`).
  * Menulis ClusterPolicies Kyverno di `implementation/kyverno/policies.yaml` untuk melarang kontainer root (`runAsNonRoot: true`), mewajibkan resource limits, dan membatasi image registry hanya dari akun kelompok.
* **Detail Tugas Riset & Dokumentasi (Markdown)**:
  * **Menulis `papers/paper-2-secure-finance-cloud.md`**: Menyusun reading notes ilmiah untuk Paper 2 (ICSIT 2025).
  * **Menulis `research/02-state-of-the-art.md` (Bagian Policy-as-Code)**: Membahas runtime admission control vs static scanning di CI.
  * **Refleksi Kelompok (Pertanyaan 1 - Bagian Paper 2)**: Menjelaskan pentingnya kepatuhan runtime (PaC) untuk mencegah eksploitasi kontainer root.

### 👤 Anggota 4: CI Pipeline Specialist
* **Detail Tugas Implementasi (Teknis)**:
  * Mengubah stage CD pada `Jenkinsfile` asli. Menghapus perintah koneksi SSH (`sshagent`) ke VPS.
  * Menulis perintah Jenkins untuk melakukan otomatisasi klon Git manifest config, memperbarui tag image manifest ke commit SHA terbaru, dan melakukan push kembali ke Git repository untuk memicu ArgoCD sync.
* **Detail Tugas Riset & Dokumentasi (Markdown)**:
  * **Menulis `research/01-gap-analysis.md`**: Mengidentifikasi kesenjangan arsitektur push-based lama (kebocoran kredensial SSH, tidak adanya auto-remediation drift, ketiadaan filter runtime).
  * **Menulis Panduan `README.md`**: Menyusun petunjuk instalasi lengkap dan reproduksi dari nol.
  * **Refleksi Kelompok (Pertanyaan 2 - Bagian Pipeline)**: Menjelaskan kendala teknis perubahan arsitektur Jenkins ke GitOps.

### 👤 Anggota 5: Drift Tester & Automation Specialist
* **Detail Tugas Implementasi (Teknis)**:
  * Menulis skrip PowerShell `implementation/scripts/simulate-drift.ps1` yang mensimulasikan drift replikasi (scale replicas ke 0), mendeteksi kapan ArgoCD melakukan auto-heal, dan menghitung durasi waktu Remedy Time (MTTR) otomatis.
* **Detail Tugas Riset & Dokumentasi (Markdown)**:
  * **Menulis `evaluation/metrics-before.md`**: Mencatat data baseline MTTR ketika container mati dan harus dinyalakan kembali lewat Jenkins secara manual (tanpa GitOps).
  * **Menulis `research/03-design-decisions.md` (Bagian GitOps)**: Menulis justifikasi ilmiah pemilihan ArgoCD berdasarkan temuan Paper 1.
  * **Refleksi Kelompok (Pertanyaan 2 - Bagian Drift Testing)**: Menulis tantangan mensimulasikan drift pada cluster lokal/VPS.

### 👤 Anggota 6: QA & Policy Auditor
* **Detail Tugas Implementasi (Teknis)**:
  * Membuat file manifest Pod "ilegal" (berjalan sebagai root, tanpa resource limits, registry asing) untuk menguji keandalan penolakan Kyverno.
  * Melakukan eksekusi test dan menangkap log error penolakan (403 Forbidden) dari admission webhook.
* **Detail Tugas Riset & Dokumentasi (Markdown)**:
  * **Menulis `evaluation/metrics-after.md`**: Mencatat data hasil pengujian pasca-peningkatan (MTTR auto-healing ArgoCD dan log penolakan Kyverno).
  * **Menulis `research/03-design-decisions.md` (Bagian Policy-as-Code)**: Menulis justifikasi ilmiah penerapan Kyverno berdasarkan model Triad Paper 2.
  * **Refleksi Kelompok (Pertanyaan 3 - Bagian QA)**: Menyusun argumen penambahan distributed tracing untuk kepatuhan audit.


Anggota 1: Satya
Anggota 2: Harwinda
Anggota 3: Andre
Anggota 4: Fio
Anggota 5: Fikri
Anggota 6: Kris