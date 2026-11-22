
# Jenkins DevOps Agent

A reusable Jenkins agent tooling image containing:

- Docker CLI
- Terraform
- Ansible
- kubectl
- Git
- Bash
- curl
- jq

## Docker Image

Docker Hub:

https://hub.docker.com/r/adityatanwar03/jenkins-devops-agent

## Build Locally

```bash
docker build -t jenkins-devops-agent:latest .
```

## Run Locally

```bash
docker run --rm jenkins-devops-agent:latest terraform version
docker run --rm jenkins-devops-agent:latest kubectl version --client
docker run --rm jenkins-devops-agent:latest ansible --version
docker run --rm jenkins-devops-agent:latest docker --version
```

## Jenkins CI/CD

The Jenkinsfile:

1. Checks out the repository.
2. Validates Docker connectivity.
3. Builds the Docker image.
4. Tags the image as latest.
5. Tags the image using the Git commit SHA.
6. Pushes both tags to Docker Hub.

## Image Tags

```text
adityatanwar03/jenkins-devops-agent:latest
adityatanwar03/jenkins-devops-agent:<commit-sha>
```

## Jenkins Credentials

Create a Jenkins credential:

- Type: Username with password
- ID: dockerhub-creds
- Username: Docker Hub username
- Password: Docker Hub access token

## Kubernetes Agent Usage

Use the published image in your Jenkins Kubernetes Pod Template as a tooling container.

Keep the Jenkins inbound-agent container separate unless you explicitly configure agent injection.
