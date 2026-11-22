
pipeline {
    agent {
        label 'agent-builder'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        DOCKERHUB_REPOSITORY = 'adityatanwar03/jenkins-devops-agent'
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short=12 HEAD',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Validate Tools') {
            steps {
                sh '''
                    echo "Checking Docker connectivity..."
                    docker version
                    docker info

                    echo "Checking build environment..."
                    git --version
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build --pull \
                      -t "$DOCKERHUB_REPOSITORY:latest" \
                      -t "$DOCKERHUB_REPOSITORY:$IMAGE_TAG" \
                      .
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_TOKEN'
                    )
                ]) {
                    sh '''
                        set +x

                        echo "$DOCKER_TOKEN" | docker login \
                          --username "$DOCKER_USER" \
                          --password-stdin

                        docker push "$DOCKERHUB_REPOSITORY:latest"

                        docker push "$DOCKERHUB_REPOSITORY:$IMAGE_TAG"

                        docker logout
                    '''
                }
            }
        }
    }

    post {
        always {
            sh '''
                docker image rm \
                  "$DOCKERHUB_REPOSITORY:latest" \
                  "$DOCKERHUB_REPOSITORY:$IMAGE_TAG" \
                  2>/dev/null || true
            '''
        }
    }
}
