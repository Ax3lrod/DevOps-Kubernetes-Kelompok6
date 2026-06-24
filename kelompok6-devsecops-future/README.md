# DevOps Final Project - Kelompok 6

Dokumentasi ini merupakan implementasi Final Project DevSecOps yang mengadopsi pendekatan GitOps menggunakan ArgoCD dan Policy-as-Code menggunakan Kyverno pada aplikasi TaskFlow API. Tujuan implementasi adalah meningkatkan keamanan deployment, mengurangi configuration drift melalui auto-healing, serta menerapkan validasi keamanan pada level Kubernetes. Implementasi ini didasarkan pada temuan dari dua paper utama:
1. Paper 1: Efisiensi GitOps dalam menangani Configuration Drift (Shrestha & Ali, 2024).
2. Paper 2: Arsitektur Cloud-Native aman untuk sektor finansial (Sanghi et al., 2025).


## 1. Infrastructure Setup (Persiapan Server)
Jalankan perintah ini di VPS Anda untuk menginstal semua *tools* dasar.

### A. Install Docker
```bash
sudo apt update && sudo apt install -y docker.io
sudo systemctl enable --now docker
# Beri izin user agar bisa akses docker tanpa sudo
sudo usermod -aG docker $USER && newgrp docker
```

### B. Install K3s (Lightweight Kubernetes)
```bash
curl -sfL https://get.k3s.io | sh -
# Set izin agar kubectl bisa diakses
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc
```

### C. Install Helm
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### D. Install Jenkins (via Docker)
Kami menjalankan Jenkins di dalam Docker agar terisolasi.
```bash
docker run -d -p 8080:8080 -p 50000:50000 --name jenkins \
-v /var/run/docker.sock:/var/run/docker.sock \
-v jenkins_home:/var/jenkins_home jenkins/jenkins:lts
```
Setelah Jenkins berhasil diinstal pada VPS, akses antarmuka web Jenkins melalui http://<IP_VPS>:8080 dan selesaikan proses konfigurasi awal menggunakan password administrator. Selanjutnya, instal plugin yang diperlukan, yaitu Git, GitHub, Pipeline, Docker Pipeline, dan Credentials Binding. Tambahkan credentials yang digunakan oleh pipeline, yaitu github-token untuk autentikasi ke GitHub dan dockerhub untuk autentikasi ke Docker Hub. 

Apabila ingin mengaktifkan notifikasi, tambahkan pula telegram-bot-token dan telegram-chat-id. Setelah konfigurasi selesai, buat sebuah Pipeline Job yang menggunakan Jenkinsfile dari repository ini, kemudian jalankan pipeline untuk memulai proses build, pengujian, dan deployment berbasis GitOps.

### E. Clone Repository
```bash
git clone https://github.com/Ax3lrod/DevOps-Kubernetes-Kelompok6.git
cd DevOps-Kubernetes-Kelompok6
```


## 2. Project Deployment (GitOps & Security)
Setelah server siap, kita instal mesin utama (ArgoCD & Kyverno) dan deploy aplikasi.

### A. Install Kyverno (Policy Engine)
```bash
helm repo add kyverno https://kyverno.github.io/kyverno/ --force-update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
# Terapkan kebijakan keamanan Kelompok 6
kubectl apply -f kelompok6-devsecops-future/implementation/kyverno/policies.yaml
```

### B. Install ArgoCD (GitOps Engine)
```bash
kubectl create namespace argocd
helm install argocd argo/argo-cd -n argocd --repo https://argoproj.github.io/argo-helm
```

### C. Create Secret & Namespace Aplikasi
Langkah ini wajib dilakukan manual untuk menjaga kerahasiaan kredensial database (Prinsip Zero Trust).
```bash
kubectl create namespace taskflow-prod
kubectl create secret generic taskflow-db-secret \
--from-literal=DATABASE_URL="postgres://user:password@host:port/db" \
-n taskflow-prod
```

### D. Apply ArgoCD Application
Langkah inilah yang akan memicu ArgoCD untuk menarik semua manifest di folder `kelompok6-devsecops-future/implementation/kubernetes`.
```bash
kubectl apply -f kelompok6-devsecops-future/implementation/argocd/application.yaml
```

## 3. CI/CD Pipeline (Automasi)
Alur kerja otomatisasi kami adalah sebagai berikut:

1.  **Menjalankan Jenkins**: Buka `http://<IP_VPS>:8080`, buat "Pipeline Job", dan hubungkan ke repositori GitHub Kelompok 6.
2.  **Update Image Logic**:
    *   Jenkins membangun Docker Image baru.
    *   Jenkins **tidak SSH ke VPS**. Jenkins menggunakan *Credentials* GitHub untuk mengedit file `kelompok6-devsecops-future/implementation/kubernetes/deployment.yaml`.
    *   Jenkins mengganti tag image (misal: `sha-123` ke `sha-456`).
    *   Jenkins melakukan `git push` perubahan tersebut kembali ke GitHub.
3.  **ArgoCD Sync**:
    *   ArgoCD memantau GitHub secara berkala melalui webhook.
    *   Begitu melihat perubahan tag image di GitHub, ArgoCD secara otomatis melakukan *Pull* dan memperbarui aplikasi di K3s.

## 4. Verification (Memastikan Keberhasilan)
Gunakan perintah ini untuk memastikan semua sistem berjalan sesuai rencana.

### A. Cek Status Sinkronisasi GitOps
```bash
# Pastikan statusnya 'Healthy' dan 'Synced'
kubectl get applications -n argocd
```

### B. Cek Status Keamanan (Kyverno)
```bash
# Pastikan 3 policy (Non-root, Resource Limits, Registry) statusnya Ready
kubectl get clusterpolicy
```

### C. Cek Jalannya Aplikasi
```bash
kubectl get pods -n taskflow-prod
```

### D. Uji Coba Self-Healing (Drift Test)
Hapus deployment secara paksa untuk melihat keajaiban auto-healing ArgoCD.
```powershell
# Jika di Windows (PowerShell)
cd kelompok6-devsecops-future/implementation/script
pwsh ./simulate-drift1.ps1
```

Atau lakukan manual dengan menjalankan `kubectl delete deployment taskflow-api -n taskflow-prod`. Tunggu 10-30 detik, ArgoCD akan membangkitkan deployment itu kembali secara otomatis.

---

### Troubleshooting
*   **ArgoCD Lambat Sync?** Jalankan `kubectl patch cm argocd-cm -n argocd --type merge -p '{"data": {"timeout.reconciliation": "10s"}}'` untuk mempercepat pengecekan ke GitHub.
*   **Pod Pending?** Cek apakah resource VPS mencukupi dengan `kubectl describe pod <nama-pod> -n taskflow-prod`.
*   **Secret Error?** Pastikan nama secret adalah `taskflow-db-secret` karena sudah *hardcoded* di manifest deployment.