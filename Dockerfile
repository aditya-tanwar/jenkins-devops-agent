FROM jenkins/inbound-agent:jdk21

USER root

ARG TERRAFORM_VERSION=1.11.4
ARG KUBECTL_VERSION=v1.32.3

# Install common utilities
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) tf_arch="amd64" ;; \
      arm64) tf_arch="arm64" ;; \
      *) exit 1 ;; \
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
      *) exit 1 ;; \
    esac; \
    curl -fsSLo /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${kubectl_arch}/kubectl"; \
    chmod +x /usr/local/bin/kubectl

# Install Kaniko executor
ARG KANIKO_VERSION=latest

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) kaniko_arch="amd64" ;; \
      arm64) kaniko_arch="arm64" ;; \
      *) exit 1 ;; \
    esac; \
    mkdir -p /kaniko/.docker; \
    curl -fsSL \
      "https://github.com/osscontainertools/kaniko/releases/latest/download/executor-linux-${kaniko_arch}" \
      -o /kaniko/executor; \
    chmod +x /kaniko/executor

ENV PATH="/kaniko:/usr/local/bin:${PATH}"

# Verify tools
RUN terraform version && \
    kubectl version --client && \
    git --version && \
    java -version

WORKDIR /home/jenkins/agent

USER jenkins