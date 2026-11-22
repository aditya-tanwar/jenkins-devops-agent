
# ==================================================
# Stage 1: Extract Kaniko files
# ==================================================
FROM ghcr.io/osscontainertools/kaniko:debug AS kaniko

# Copy Kaniko files outside its reserved directory.
RUN mkdir -p /tmp/kaniko-files && \
    cp /kaniko/executor /tmp/kaniko-files/executor && \
    cp -a /kaniko/ssl/certs /tmp/kaniko-files/certs && \
    cp -a /busybox /tmp/kaniko-files/busybox


# ==================================================
# Stage 2: Jenkins DevOps Agent
# ==================================================
FROM jenkins/inbound-agent:jdk21

USER root

ARG TERRAFORM_VERSION=1.11.4
ARG KUBECTL_VERSION=v1.32.3

# ==================================================
# Install system dependencies
# ==================================================
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


# ==================================================
# Install Kaniko in the SAME Jenkins agent container
# ==================================================
RUN mkdir -p \
    /kaniko/.docker \
    /kaniko/ssl/certs \
    /busybox

COPY --from=kaniko /tmp/kaniko-files/executor /kaniko/executor
COPY --from=kaniko /tmp/kaniko-files/certs/ /kaniko/ssl/certs/
COPY --from=kaniko /tmp/kaniko-files/busybox/ /busybox/

RUN chmod +x /kaniko/executor && \
    chmod -R a+rX /kaniko /busybox && \
    chown -R jenkins:jenkins /kaniko /busybox

# System binaries must take priority over BusyBox applets.
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/kaniko:/busybox"

ENV DOCKER_CONFIG="/kaniko/.docker/"
ENV SSL_CERT_DIR="/kaniko/ssl/certs"


# ==================================================
# Install Terraform
# ==================================================
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
        amd64) tf_arch="amd64" ;; \
        arm64) tf_arch="arm64" ;; \
        *) echo "Unsupported architecture: $arch"; exit 1 ;; \
    esac; \
    curl -fsSLo /tmp/terraform.zip \
        "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${tf_arch}.zip"; \
    unzip /tmp/terraform.zip -d /usr/local/bin; \
    chmod +x /usr/local/bin/terraform; \
    rm -f /tmp/terraform.zip


# ==================================================
# Install kubectl
# ==================================================
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
        amd64) kubectl_arch="amd64" ;; \
        arm64) kubectl_arch="arm64" ;; \
        *) echo "Unsupported architecture: $arch"; exit 1 ;; \
    esac; \
    curl -fsSLo /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${kubectl_arch}/kubectl"; \
    chmod +x /usr/local/bin/kubectl


# ==================================================
# Verify installed tools
# ==================================================
RUN set -eux; \
    echo "Architecture:"; \
    dpkg --print-architecture; \
    echo "Tool locations:"; \
    command -v dpkg; \
    command -v curl; \
    command -v terraform; \
    command -v kubectl; \
    echo "Terraform:"; \
    terraform version; \
    echo "kubectl:"; \
    kubectl version --client; \
    echo "Git:"; \
    git --version; \
    echo "Java:"; \
    java -version; \
    echo "Kaniko:"; \
    /kaniko/executor version


# ==================================================
# Jenkins agent configuration
# ==================================================
WORKDIR /home/jenkins/agent

USER jenkins
