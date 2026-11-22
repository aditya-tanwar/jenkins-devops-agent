
FROM alpine:3.21

ARG TERRAFORM_VERSION=1.11.4
ARG KUBECTL_VERSION=v1.32.3
ARG ANSIBLE_CORE_VERSION=2.18.3

# Install common utilities and Docker CLI
RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    openssh-client \
    python3 \
    py3-pip \
    py3-virtualenv \
    unzip \
    docker-cli \
    && update-ca-certificates

# Install Terraform
RUN set -eux; \
    arch="$(apk --print-arch)"; \
    case "$arch" in \
      x86_64) tf_arch="amd64" ;; \
      aarch64) tf_arch="arm64" ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSLo /tmp/terraform.zip \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${tf_arch}.zip"; \
    unzip /tmp/terraform.zip -d /usr/local/bin; \
    rm -f /tmp/terraform.zip

# Install kubectl
RUN set -eux; \
    arch="$(apk --print-arch)"; \
    case "$arch" in \
      x86_64) kubectl_arch="amd64" ;; \
      aarch64) kubectl_arch="arm64" ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSLo /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${kubectl_arch}/kubectl"; \
    chmod +x /usr/local/bin/kubectl

# Install Ansible in an isolated Python virtual environment
RUN python3 -m venv /opt/ansible \
    && /opt/ansible/bin/pip install --no-cache-dir \
       "ansible-core==${ANSIBLE_CORE_VERSION}" \
    && ln -s /opt/ansible/bin/ansible /usr/local/bin/ansible \
    && ln -s /opt/ansible/bin/ansible-playbook /usr/local/bin/ansible-playbook

ENV PATH="/opt/ansible/bin:${PATH}"

# Verify installations
RUN docker --version \
    && terraform version \
    && kubectl version --client \
    && ansible --version

WORKDIR /workspace

CMD ["bash"]
