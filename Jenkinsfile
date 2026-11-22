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

        stage('Validate Build Environment') {
            steps {
                container('buildah') {
                    sh '''
                        echo "Checking Buildah..."
                        buildah --version

                        echo "Checking build context..."
                        ls -la "$WORKSPACE"

                        echo "Checking Dockerfile..."
                        test -f "$WORKSPACE/Dockerfile"
                    '''
                }
            }
        }

        stage('Build and Push Image') {
            steps {
                container('buildah') {
                    withCredentials([
                        usernamePassword(
                            credentialsId: "${DOCKERHUB_CREDENTIALS}",
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_TOKEN'
                        )
                    ]) {
                        sh '''
                            set -euo pipefail
                            set +x

                            # Use an isolated auth file so credentials don't persist in the shared pod
                            export REGISTRY_AUTH_FILE=$(mktemp)
                            trap 'rm -f "$REGISTRY_AUTH_FILE"' EXIT

                            echo "Logging into Docker Hub..."
                            printf '%s' "$DOCKER_TOKEN" | buildah login \
                                --username "$DOCKER_USER" \
                                --password-stdin \
                                docker.io

                            echo "Building image..."
                            buildah bud \
                                --layers \
                                -f "$WORKSPACE/Dockerfile" \
                                -t "$DOCKERHUB_REPOSITORY:$IMAGE_TAG" \
                                -t "$DOCKERHUB_REPOSITORY:latest" \
                                "$WORKSPACE"

                            echo "Pushing image tags..."
                            buildah push "$DOCKERHUB_REPOSITORY:$IMAGE_TAG"
                            buildah push "$DOCKERHUB_REPOSITORY:latest"
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Jenkins DevOps agent image pipeline completed.'
        }
    }
}
