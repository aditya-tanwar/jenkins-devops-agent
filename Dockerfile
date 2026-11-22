# ==================================================
# Jenkins DevOps Agent (with Podman)
# ==================================================
FROM docker.io/jenkins/inbound-agent:jdk21

USER root

ARG TERRAFORM_VERSION=1.11.4
ARG KUBECTL_VERSION=v1.32.3
ARG COSIGN_VERSION=v3.0.5

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        coreutils \
        curl \
        fuse-overlayfs \
        git \
        jq \
        openssh-client \
        podman \
        slirp4netns \
        tar \
        uidmap \
        unzip \
    && update-ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure rootless user namespaces and container storage for the jenkins user
RUN echo "jenkins:100000:65536" >> /etc/subuid && \
    echo "jenkins:100000:65536" >> /etc/subgid && \
    mkdir -p /home/jenkins/.config/containers && \
    printf '[storage]\ndriver = "overlay"\nrunroot = "/tmp/containers-runroot"\ngraphroot = "/home/jenkins/.local/share/containers/storage"\n\n[storage.options.overlay]\nmount_program = "/usr/bin/fuse-overlayfs"\n' \
        > /home/jenkins/.config/containers/storage.conf && \
    chown -R jenkins:jenkins /home/jenkins/.config

ENV PATH="${JAVA_HOME}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV SSL_CERT_DIR="/etc/ssl/certs"
ENV _CONTAINERS_USERNS_CONFIGURED=""

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
    podman --version

WORKDIR /home/jenkins/agent
USER jenkins
