
# Stage 1: Kaniko source image
FROM ghcr.io/osscontainertools/kaniko:debug AS kaniko

# Stage 2: Jenkins DevOps agent
FROM jenkins/inbound-agent:jdk21

USER root

ARG TERRAFORM_VERSION=1.11.4
ARG KUBECTL_VERSION=v1.32.3

# Install common DevOps utilities
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        jq \
        openssh-client \
        unzip \
        tar \
    && update-ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy Kaniko executor and its supporting files
COPY --from=kaniko /kaniko /kaniko
COPY --from=kaniko /busybox /busybox

ENV PATH="/kaniko:/busybox:/usr/local/bin:${PATH}"
ENV DOCKER_CONFIG="/kaniko/.docker/"
ENV SSL_CERT_DIR="/kaniko/ssl/certs"

# Install Terraform
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) tf_arch="amd64" ;; \
      arm64) tf_arch="arm64" ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSLo /tmp/terraform.zip \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${tf_arch}.zip"; \
    unzip /tmp/terraform.zip -d /usr/local/bin; \
    rm -f /tmp/terraform.zip

# Install kubectl
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) kubectl_arch="amd64" ;; \
      arm64) kubectl_arch="arm64" ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSLo /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${kubectl_arch}/kubectl"; \
    chmod +x /usr/local/bin/kubectl

# Verify installed tools
RUN /kaniko/executor version \
    && terraform version \
    && kubectl version --client \
    && git --version \
    && java -version

# Jenkins workspace
WORKDIR /home/jenkins/agent

USER jenkins
