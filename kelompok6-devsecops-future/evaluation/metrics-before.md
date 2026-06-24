# Metrics Before Enhancement (Sistem Lama / Baseline)
# Anggota 5: Drift Tester & Automation

Dokumen ini mencatat hasil pengukuran empiris kinerja keandalan infrastruktur Kelompok 6 pada arsitektur sistem lama (Tugas 3), sebelum diintegrasikannya ArgoCD (Deployment Intelligence) dan Kyverno (Policy-as-Code).

## 📊 1. Pengukuran Waktu Pemulihan Manual (Mean Time to Remediation)

Pengujian dilakukan secara manual dengan menyimulasikan skenario _Misconfiguration Change_ (penghapusan objek deployment `taskflow-api` pada namespace `taskflow-prod` menggunakan perintah `kubectl delete`). Karena ketiadaan *auto-healing controller*, pemulihan mengharuskan intervensi manual dari engineer (dalam skenario ini, disimulasikan *engineer delay* 30 detik sebelum menyadari insiden dan mengeksekusi pipeline ulang di Jenkins).

| Metrik Evaluasi                               | Nilai Baseline Riil | Keterangan Operasional Sistem                                                        |
| :-------------------------------------------- | :------------------ | :----------------------------------------------------------------------------------- |
| **Waktu Deteksi Drift (Discovery Time)**      | ~30 Detik           | Sangat lambat dan bergantung pada monitoring manual / laporan *downtime* pengguna.   |
| **Waktu Rekonsiliasi Manual (Remedy Time)**   | **31.581 Detik**    | Total durasi dari sistem mati, respon lambat manusia, hingga *apply* Jenkins selesai.|
| **Intervensi Operator (Human Action)**        | 100% (Mutlak)       | Pemulihan gagal jika engineer tidak menekan tombol *Deploy* di Jenkins.              |

## 🛡️ 2. Pengukuran Kepatuhan Runtime (Tanpa Policy-as-Code)

Tanpa adanya *admission controller* (seperti Kyverno), kluster sepenuhnya mengandalkan integritas kode yang lolos dari CI pipeline. Pengujian injeksi manifes langsung ke API Kubernetes menunjukkan celah fatal:

| Skenario Pod Ilegal                                       | Ekspektasi Keamanan   | Hasil Pengujian Riil                                                           | Status           |
| :-------------------------------------------------------- | :-------------------- | :----------------------------------------------------------------------------- | :--------------- |
| Deploy dengan Privilese Root User                         | Ditolak oleh Cluster  | K8s membuat Pod `runAsUser: 0` tanpa hambatan peringatan apapun.               | **100% ALLOWED** |
| Deploy tanpa Batasan CPU/Memori                           | Ditolak oleh Cluster  | K8s meloloskan beban tanpa limitasi yang berisiko *resource exhaustion*.       | **100% ALLOWED** |
| Tarik Image dari Registry Asing (`attacker.io/malware`)   | Ditolak oleh Cluster  | K8s berhasil menarik dan menjalankan image asing yang tidak terverifikasi.     | **100% ALLOWED** |

### 🔍 Kesimpulan Evaluasi Kuantitatif

Tanpa _automated reconciliation loop_ dan _runtime security validation_, sistem memiliki MTTR (*Mean Time to Remediation*) yang sangat memprihatinkan (**31.581 detik**) dan rentan terhadap _Human Error_ maupun serangan langsung ke cluster K8s. Hal ini menjadi justifikasi valid atas urgensi perpindahan menuju arsitektur GitOps.
