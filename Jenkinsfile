pipeline {
    agent any

    environment {
        DOCKER_REGISTRY   = 'localhost:5000'
        APP_NAME          = 'monitoring-app'
        TERRAFORM_VERSION = '1.6.0'
        ANSIBLE_VERSION   = '2.15'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log --oneline -5'
            }
        }

        stage('Security Scan - IaC') {
            parallel {
                stage('Checkov Terraform') {
                    steps {
                        sh '''
                            echo "Scanning Terraform with Checkov..."
                            checkov -d infrastructure/terraform \
                              --framework terraform \
                              --output junitxml \
                              --output-file-path . \
                              || true
                        '''
                        junit 'results_terraform.xml'
                    }
                }

                stage('Checkov Ansible') {
                    steps {
                        sh '''
                            echo "Scanning Ansible with Checkov..."
                            checkov -d configuration/ansible \
                              --framework ansible \
                              --output junitxml \
                              --output-file-path . \
                              || true
                        '''
                        junit 'results_ansible.xml'
                    }
                }
            }
        }

        stage('Build Application Container') {
            steps {
                script {
                    sh '''
                        echo "Building application container..."
                        cat > application/docker/Dockerfile << 'EOF'
FROM cgr.dev/chainguard/node:latest
WORKDIR /app
USER node
COPY --chown=node:node package*.json ./
RUN npm ci --only=production
COPY --chown=node:node . .
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD node healthcheck.js
CMD ["node", "server.js"]
EOF
                    '''
                }
            }
        }

        stage('Security Scan - Container') {
            steps {
                sh '''
                    echo "Scanning container with Trivy..."
                    trivy fs --severity HIGH,CRITICAL \
                      --format table \
                      --exit-code 0 \
                      application/docker/
                '''
            }
        }

        stage('Deploy Infrastructure') {
            steps {
                dir('infrastructure/terraform') {
                    sh '''
                        terraform init
                        terraform validate
                        terraform plan -out=tfplan
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Configure Services') {
            steps {
                dir('configuration/ansible') {
                    sh '''
                        ansible-playbook -i inventory.yml playbook.yml \
                          --extra-vars "environment=development"
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Checking services health..."
                    sleep 10

                    # Check Prometheus
                    curl -f http://localhost:9090/-/healthy || exit 1

                    # Check Grafana
                    curl -f http://localhost:3000/api/health || exit 1

                    # Check Jenkins
                    curl -f http://localhost:8080/login || exit 1

                    echo "All services are healthy!"
                '''
            }
        }

        stage('Integration Tests') {
            steps {
                sh '''
                    echo "Running integration tests..."

                    # Test Prometheus metrics
                    curl -s "http://localhost:9090/api/v1/query?query=up" | grep -q "success"

                    # Test Grafana API
                    curl -s -u admin:gitops2024 http://localhost:3000/api/datasources | grep -q "prometheus"

                    echo "Integration tests passed!"
                '''
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            sh 'docker system prune -f || true'
        }

        success {
            echo 'Pipeline executed successfully!'
            emailext(
                subject: "GitOps Pipeline Success: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "The GitOps pipeline has completed successfully.\n\nPrometheus: http://localhost:9090\nGrafana: http://localhost:3000",
                to: 'devops@techmonitor.corp'
            )
        }

        failure {
            echo 'Pipeline failed!'
            emailext(
                subject: "GitOps Pipeline Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "The GitOps pipeline has failed. Please check the logs.",
                to: 'devops@techmonitor.corp'
            )
        }
    }
}
