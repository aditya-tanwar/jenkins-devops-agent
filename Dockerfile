# ==================================================
# Stage 1: Extract Kaniko binary
# ==================================================
FROM ghcr.io/osscontainertools/kaniko:debug AS kaniko

RUN mkdir -p /tmp/kaniko-files && \
    cp /kaniko/executor /tmp/kaniko-files/executor


# ==================================================
# Stage 2: Jenkins DevOps Agent
# ==================================================
FROM jenkins/inbound-agent:jdk21

USER root

ARG TERRAFORM_VERSION=1.11.4
ARG KUBECTL_VERSION=v1.32.3
ARG COSIGN_VERSION=v3.0.5

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

# Store executor outside /kaniko so Kaniko's build snapshot includes it
RUN mkdir -p /opt/kaniko
COPY --from=kaniko /tmp/kaniko-files/executor /opt/kaniko/executor
RUN chmod 0755 /opt/kaniko/executor && \
    chown -R jenkins:jenkins /opt/kaniko

ENV PATH="${JAVA_HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/kaniko"
ENV SSL_CERT_DIR="/etc/ssl/certs"

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

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
        amd64) kubectl_arch="amd64" ;; \
        arm64) kubectl_arch="arm64" ;; \
        *) echo "Unsupported architecture: $arch"; exit 1 ;; \
    esac; \
    curl -fsSLo /tmp/kubectl \
        "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${kubectl_arch}/kubectl"; \
    chmod +x /tmp/kubectl; \
    mv /tmp/kubectl /usr/local/bin/kubectl

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
        amd64) go_arch="amd64" ;; \
        arm64) go_arch="arm64" ;; \
        *) echo "Unsupported architecture: $arch"; exit 1 ;; \
    esac; \
    curl -sSfL https://get.anchore.io/syft | sh -s -- -b /usr/local/bin; \
    curl -sSfL https://get.anchore.io/grype | sh -s -- -b /usr/local/bin; \
    curl -fsSLo /usr/local/bin/cosign \
        "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-${go_arch}"; \
    chmod +x /usr/local/bin/cosign

RUN set -eux; \
    dpkg --print-architecture; \
    java -version; \
    terraform version; \
    kubectl version --client; \
    syft version; \
    grype version; \
    cosign version; \
    git --version; \
    /opt/kaniko/executor version

WORKDIR /home/jenkins/agent
USER jenkins