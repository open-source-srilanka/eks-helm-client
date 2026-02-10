FROM alpine:3.20

# Build arguments for version pinning
ARG K8_VERSION="1.31.3"
ARG HELM_VERSION="3.16.3"
ARG IAM_AUTHENTICATOR_VERSION="0.6.28"
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Environment variables
ENV KUBECONFIG="/opt/kubernetes/config" \
    HELM_HOME="/opt/helm" \
    XDG_CONFIG_HOME="/opt/helm" \
    HELM_CACHE_HOME="/opt/helm/cache" \
    PATH="/usr/local/bin:${PATH}"

# Install base dependencies
RUN apk add --no-cache \
    ca-certificates \
    bash \
    git \
    gnupg \
    jq \
    curl \
    gettext \
    aws-cli \
    && rm -rf /var/cache/apk/*

# Download and install kubectl with multi-arch support
RUN set -ex && \
    ARCH=$(case ${TARGETARCH:-amd64} in \
        amd64) echo "amd64" ;; \
        arm64) echo "arm64" ;; \
        *) echo "amd64" ;; \
    esac) && \
    curl -sL "https://dl.k8s.io/release/v${K8_VERSION}/bin/linux/${ARCH}/kubectl" \
        -o /usr/local/bin/kubectl && \
    curl -sL "https://dl.k8s.io/release/v${K8_VERSION}/bin/linux/${ARCH}/kubectl.sha256" \
        -o /tmp/kubectl.sha256 && \
    echo "$(cat /tmp/kubectl.sha256)  /usr/local/bin/kubectl" | sha256sum -c - && \
    chmod +x /usr/local/bin/kubectl && \
    rm /tmp/kubectl.sha256

# Download and install Helm with multi-arch support
RUN set -ex && \
    ARCH=$(case ${TARGETARCH:-amd64} in \
        amd64) echo "amd64" ;; \
        arm64) echo "arm64" ;; \
        *) echo "amd64" ;; \
    esac) && \
    curl -sL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz" \
        -o /tmp/helm.tar.gz && \
    tar -xzf /tmp/helm.tar.gz -C /tmp && \
    mv /tmp/linux-${ARCH}/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    rm -rf /tmp/helm.tar.gz /tmp/linux-${ARCH}

# Download and install aws-iam-authenticator with multi-arch support
RUN set -ex && \
    ARCH=$(case ${TARGETARCH:-amd64} in \
        amd64) echo "amd64" ;; \
        arm64) echo "arm64" ;; \
        *) echo "amd64" ;; \
    esac) && \
    curl -sL "https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${IAM_AUTHENTICATOR_VERSION}/aws-iam-authenticator_${IAM_AUTHENTICATOR_VERSION}_linux_${ARCH}" \
        -o /usr/local/bin/aws-iam-authenticator && \
    chmod +x /usr/local/bin/aws-iam-authenticator

# Create necessary directories with proper permissions
RUN mkdir -p /opt/kubernetes /opt/helm /opt/helm/cache && \
    chmod -R 755 /opt/kubernetes /opt/helm

# Copy application files
COPY entrypoint.sh /entrypoint.sh
COPY config.template /config.template

RUN chmod +x /entrypoint.sh

# Use non-root user for security
RUN addgroup -g 1000 kubectl && \
    adduser -D -u 1000 -G kubectl kubectl && \
    chown -R kubectl:kubectl /opt/kubernetes /opt/helm

USER kubectl

WORKDIR /home/kubectl

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]