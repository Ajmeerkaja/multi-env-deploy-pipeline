pipeline {
    agent any

    environment {
        AWS_REGION   = 'ap-south-1'
        ECR_REPO     = '976193240813.dkr.ecr.ap-south-1.amazonaws.com/multi-env-app'
        IMAGE_NAME   = 'multi-env-app'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Ajmeerkaja/multi-env-deploy-pipeline.git',
                    credentialsId: 'github-creds'
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('app') {
                    sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} ."
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}
                        docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${ECR_REPO}:${BUILD_NUMBER}
                        docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${ECR_REPO}:latest
                        docker push ${ECR_REPO}:${BUILD_NUMBER}
                        docker push ${ECR_REPO}:latest
                    """
                }
            }
        }

        stage('Deploy to Dev') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'dev-ssh-key', keyFileVariable: 'DEV_KEY'),
                    usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('ansible') {
                        sh """
                            cp \$DEV_KEY ./dev-key.pem
                            chmod 400 ./dev-key.pem
                            ansible-playbook -i inventories/dev.ini playbook.yml --extra-vars "app_env=dev ecr_repo=${ECR_REPO}"
                        """
                    }
                }
            }
        }

        stage('Approve Prod Deployment') {
            steps {
                input message: 'Deploy this build to PRODUCTION?', ok: 'Deploy'
            }
        }

        stage('Deploy to Prod') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'prod-ssh-key', keyFileVariable: 'PROD_KEY'),
                    usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('ansible') {
                        sh """
                            cp \$PROD_KEY ./prod-key.pem
                            chmod 400 ./prod-key.pem
                            ansible-playbook -i inventories/prod.ini playbook.yml --extra-vars "app_env=prod ecr_repo=${ECR_REPO}"
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -f || true'
        }
    }
}