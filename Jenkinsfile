pipeline {
    agent {
        docker { 
            image 'ax3lrod/taskflow-ci:latest'
            // Konfigurasi VPS agar Jenkins bisa mengelola container dan network dengan lancar
            args '-u root -v /var/run/docker.sock:/var/run/docker.sock --network host'
        }
    }
    
    environment {
        PROJECT_DIR = '.'
        GOCACHE = "${WORKSPACE}/.cache"
        DATABASE_URL = "postgres://taskflow:taskflow_secret@localhost:5432/taskflow?sslmode=disable"
        // Target repositori Docker Hub kamu
        DOCKER_IMAGE = "fikriau/taskflow-api-k8s"
    }

    stages {
        stage('0. Prevent Infinite Loop') {
            steps {
                // Plugin SCM Skip akan mendeteksi [skip ci] lalu membatalkan dan MENGHAPUS build ini dari history
                scmSkip(deleteBuild: true, skipPattern:'.*\\[skip ci\\].*')
            }
        }

        stage('1. Preparation') {
            steps {
                // Memastikan Jenkins menarik branch/PR yang benar
                checkout scm
                // Mengatasi kendala izin direktori Git di lingkungan VPS
                sh 'git config --global --add safe.directory "*"'
                dir("${env.PROJECT_DIR}") {
                    echo '📦 Downloading Dependencies...'
                    sh 'go mod download'
                }
                sh 'git remote -v'  
            }
        }

        stage('2. Static Analysis') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    echo '🔍 Running go vet...'
                    sh 'go vet ./...'
                }
            }
        }

        stage('2.1 Security Audit: SAST') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    echo '🛡️ Running Gosec (Static Application Security Testing)...'
                    script {
                        // Install gosec jika belum ada di environment
                        sh 'go install github.com/securego/gosec/v2/cmd/gosec@v2.20.0'
                        // Jalankan scan. Pipeline akan FAIL jika ada temuan HIGH (exit-code non-zero)
                        // Laporan disimpan sebagai gosec-report.json
                        sh '/go/bin/gosec -fmt json -out gosec-report.json ./...'
                    }
                }
            }
        }

        stage('3. Database Startup') {
            steps {
                script {
                    def dbContainerName = "db-container-${env.BUILD_ID}"
                    echo "🚀 Starting PostgreSQL Sidecar: ${dbContainerName}"
                    sh "docker run -d --name ${dbContainerName} -p 5432:5432 -e POSTGRES_DB=taskflow -e POSTGRES_USER=taskflow -e POSTGRES_PASSWORD=taskflow_secret postgres:16"
                    sh 'sleep 15'
                }
            }
        }

        stage('4. Unit Testing') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    echo '🧪 Running Unit Tests...'
                    sh "CGO_ENABLED=1 go test -v -race -buildvcs=false ./internal/service/... ./internal/validator/... ./internal/handler/..."
                }
            }
        }

        stage('5. Integration Testing') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    echo '🔗 Running Integration Tests...'
                    sh "CGO_ENABLED=1 DATABASE_URL='${env.DATABASE_URL}' go test -v -race -tags=integration -buildvcs=false ./internal/repository/..."
                }
            }
        }

        stage('6. Coverage Gate') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    script {
                        echo '📊 Checking Coverage (Minimum 75%)...'
                        sh "DATABASE_URL='${env.DATABASE_URL}' go test ./... -tags=integration -coverprofile=cov.out -buildvcs=false"
                        def coverage = sh(script: "go tool cover -func=cov.out | grep total | awk '{print \$3}' | sed 's/%//'", returnStdout: true).trim()
                        echo "Total Project Coverage: ${coverage}%"
                        
                        if (coverage.toFloat() < 75.0) {
                            error "❌ FAILED: Coverage (${coverage}%) di bawah batas minimal 75%!"
                        }
                    }
                }
            }
        }

        stage('7. Build Binary') {
            steps {
                dir("${env.PROJECT_DIR}") {
                    echo '🏗️ Compiling Application...'
                    sh 'go build -buildvcs=false -o bin/taskflow-api ./cmd/server'
                }
            }
        }

        stage('8. CD - Build & Push Docker Hub') {
            when { branch 'main' }
            steps {
                script {
                    // Membuat tag unik berdasarkan 7 digit pertama commit SHA
                    def commitSha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    def fullTag = "${env.DOCKER_IMAGE}:sha-${commitSha}"

                    echo "🚀 Memulai proses Build & Push untuk image: ${fullTag}"

                    // Memanggil kredensial 'dockerhub-fikri' yang harus didaftarkan di Jenkins VPS
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-fikri', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                        sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}"
                        
                        dir("${env.PROJECT_DIR}") {
                            // Proses build menggunakan Dockerfile multi-stage
                            sh "docker build -t ${fullTag} ."
                            sh "docker push ${fullTag}"
                            
                            // Menambahkan tag latest sebagai penanda versi paling baru
                            sh "docker tag ${fullTag} ${env.DOCKER_IMAGE}:latest"
                            sh "docker push ${env.DOCKER_IMAGE}:latest"
                        }
                        sh "docker logout"
                    }
                }
            }
        }

        // === SCENARIO 6: KATEGORI D - CONTAINER SCAN (TAMBAHAN KAMU) ===
        stage('8.1 Security Audit: Container Scan') {
            steps {
                script {
                    def commitSha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    def fullTag = "${env.DOCKER_IMAGE}:sha-${commitSha}"
                    
                    echo "🛡️ Scanning Docker Image: ${fullTag}"
                    // Install Trivy secara sementara untuk scanning
                    sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin'
                    // Scan image. Pipeline akan FAIL jika ada temuan HIGH atau CRITICAL
                    sh "trivy image --severity HIGH,CRITICAL --exit-code 0 --format json --output trivy-report.json ${fullTag}"
                }
            }
        }
        
        stage('9. GitOps CD') {
            when { branch 'main' }

            steps {
                script {

                    def commitSha = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    def IMAGE_TAG = "${env.DOCKER_IMAGE}:sha-${commitSha}"

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'github-token',
                            usernameVariable: 'GIT_USER',
                            passwordVariable: 'GIT_TOKEN'
                        )
                    ]) {

                        sh """
                        git remote set-url origin https://${GIT_USER}:${GIT_TOKEN}@github.com/Ax3lrod/DevOps-Kubernetes-Kelompok6.git

                        git fetch origin
                        
                        git checkout -B main origin/main

                        sed -i "s|image: fikriau/taskflow-api-k8s:.*|image: ${IMAGE_TAG}|" kelompok6-devsecops-future/implementation/kubernetes/deployment.yaml

                        git config user.email "jenkins@local"
                        git config user.name "Jenkins"

                        git add kelompok6-devsecops-future/implementation/kubernetes/deployment.yaml

                        git commit -m "[skip ci] Update image ${commitSha}" || true

                        git push origin main
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                withCredentials([
                    string(credentialsId: 'telegram-bot-token', variable: 'BOT_TOKEN'),
                    string(credentialsId: 'telegram-chat-id', variable: 'CHAT_ID')
                ]) {
                    def commitSha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    def branchName = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    def buildUrl = env.BUILD_URL ?: 'unknown'
                    def now = new Date().format("yyyy-MM-dd HH:mm:ss", TimeZone.getTimeZone('Asia/Jakarta'))

                    def message = "✅ *Pipeline Sukses*\n\n" +
                        "• *Branch*: ${branchName}\n" +
                        "• *Commit*: ${commitSha}\n" +
                        "• *Waktu*: ${now} WIB\n" +
                        "• *Link*: ${buildUrl}\n" +
                        "• *Security Scan*: Laporan JSON tersedia di Artifacts"

                    sh """
                        curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
                            --data-urlencode "chat_id=${CHAT_ID}" \
                            --data-urlencode "parse_mode=Markdown" \
                            --data-urlencode "text=${message}"
                    """
                }
            }
        }

        failure {
            script {
                withCredentials([
                    string(credentialsId: 'telegram-bot-token', variable: 'BOT_TOKEN'),
                    string(credentialsId: 'telegram-chat-id', variable: 'CHAT_ID')
                ]) {
                    def commitSha = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    def branchName = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    def buildUrl = env.BUILD_URL ?: 'unknown'
                    def now = new Date().format("yyyy-MM-dd HH:mm:ss", TimeZone.getTimeZone('Asia/Jakarta'))

                    def message = "❌ *Pipeline Gagal*\n\n" +
                        "• *Branch*: ${branchName}\n" +
                        "• *Commit*: ${commitSha}\n" +
                        "• *Waktu*: ${now} WIB\n" +
                        "• *Link*: ${buildUrl}\n" +
                        "• *Catatan*: Periksa log untuk kegagalan Test atau Security Audit"

                    sh """
                        curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
                            --data-urlencode "chat_id=${CHAT_ID}" \
                            --data-urlencode "parse_mode=Markdown" \
                            --data-urlencode "text=${message}"
                    """
                }
            }
        }

        always {
            echo '🧹 Membersihkan container...'
            script {
                def dbContainerName = "db-container-${env.BUILD_ID}"
                sh "docker rm -f ${dbContainerName} || true"
                sh "docker rm -f \$(docker ps -aq --filter name=taskflow-smoke) 2>/dev/null || true"
            }
            
            dir("${env.PROJECT_DIR}") {
                // UPDATE: Menambahkan pengarsipan file JSON laporan security
                archiveArtifacts artifacts: 'cov.out, **/*.json', allowEmptyArchive: true
            }
        }
    }
}