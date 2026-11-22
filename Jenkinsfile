
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
                container('kaniko') {
                    sh '''
                        echo "Checking Kaniko executor..."
                        /kaniko/executor version

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
                container('kaniko') {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'dockerhub-creds',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_TOKEN'
                        )
                    ]) {
                        sh '''
                            set +x

                            mkdir -p /kaniko/.docker

                            AUTH=$(printf '%s' "$DOCKER_USER:$DOCKER_TOKEN" | base64 | tr -d '\\n')

                            printf '{"auths":{"https://index.docker.io/v1/":{"username":"%s","password":"%s","auth":"%s"}}}' \
                                "$DOCKER_USER" "$DOCKER_TOKEN" "$AUTH" \
                                > /kaniko/.docker/config.json

                            echo "Building and pushing image..."

                            /kaniko/executor \
                                --context="$WORKSPACE" \
                                --dockerfile="$WORKSPACE/Dockerfile" \
                                --destination="$DOCKERHUB_REPOSITORY:latest" \
                                --destination="$DOCKERHUB_REPOSITORY:$IMAGE_TAG" \
                                --cache=true

                            rm -f /kaniko/.docker/config.json
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
