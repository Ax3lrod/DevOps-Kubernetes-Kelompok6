#!/bin/bash
# ------------------------------------------------------------------
# Script Otomatisasi Deployment TaskFlow ke Kubernetes Cluster (VPS)
# Fokus Tugas 7.5 & Finalisasi - Anggota 6 (Fikri)
# ------------------------------------------------------------------

# Keluar dari skrip jika ada perintah yang memicu error
set -e

# Definisikan variabel environment lokal agar selaras dengan Jenkinsfile
EXPORT_KUBECONFIG="/home/kelompok6/.kube/config"
NAMESPACE_PROD="taskflow-prod"
DEPLOYMENT_NAME="taskflow-api"

echo "=========================================================="
echo "☸️  Memulai Pemasangan & Konfigurasi Manifest Kubernetes..."
echo "=========================================================="

# 1. Mengarahkan variabel KUBECONFIG secara aman
if [ -f "$EXPORT_KUBECONFIG" ]; then
    export KUBECONFIG="$EXPORT_KUBECONFIG"
    echo "✅ Kubeconfig ditemukan dan dimuat."
else
    echo "⚠️  Peringatan: Kubeconfig tidak ditemukan di $EXPORT_KUBECONFIG."
    echo "Mencoba melanjutkan menggunakan konfigurasi default cluster..."
fi

# 2. Membuat atau memperbarui Namespace
echo ""
echo "📁 Langkah 1: Menerapkan konfigurasi Namespaces..."
if [ -f "kubernetes/namespace-dev.yaml" ] && [ -f "kubernetes/namespace-prod.yaml" ]; then
    kubectl apply -f kubernetes/namespace-dev.yaml
    kubectl apply -f kubernetes/namespace-prod.yaml
    echo "✅ Namespace dev dan prod berhasil dikonfigurasi."
else
    echo "❌ Error: Berkas konfigurasi namespace di folder kubernetes/ tidak ditemukan!"
    exit 1
fi

# 3. Menerapkan Deployment & Service awal ke Production
echo ""
echo "🚀 Langkah 2: Deploy Arsitektur TaskFlow ke Namespace Prod..."
if [ -f "kubernetes/deployment.yaml" ] && [ -f "kubernetes/service.yaml" ]; then
    kubectl apply -f kubernetes/deployment.yaml -n $NAMESPACE_PROD
    kubectl apply -f kubernetes/service.yaml -n $NAMESPACE_PROD
    echo "✅ Manifest Deployment dan Service berhasil diterapkan."
else
    echo "❌ Error: Berkas deployment.yaml atau service.yaml tidak ditemukan!"
    exit 1
fi

# 4. Melakukan simulasi pembaruan tag ke versi SHA paling anyar di lokal
echo ""
echo "🔄 Langkah 3: Sinkronisasi Tag Image Kontainer Terkini..."
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
DOCKER_IMAGE="fikriau/taskflow-api-k8s:sha-$COMMIT_SHA"

echo "→ Mengarahkan deployment ke image: $DOCKER_IMAGE"
kubectl set image deployment/$DEPLOYMENT_NAME $DEPLOYMENT_NAME=$DOCKER_IMAGE -n $NAMESPACE_PROD

# 5. Memantau Status Rollout (Penting untuk penyelesaian Insiden 2 & 3)
echo ""
echo "⏳ Langkah 4: Menunggu proses Rolling Update selesai..."
kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE_PROD --timeout=120s

# 6. Informasi Akses Akhir
echo ""
echo "=========================================================="
echo "🎉 DEPLOYMENT SELESAI DAN BERJALAN SUKSES!"
echo "=========================================================="
echo "Aplikasi TaskFlow aktif di lingkungan Production."
echo "📊 Cek status Pod dengan perintah: kubectl get pods -n $NAMESPACE_PROD"
echo "👉 Akses Layanan Web melalui URL : http://10.4.89.175:30080"
echo "=========================================================="