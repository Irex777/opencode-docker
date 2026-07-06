FROM debian:bookworm-slim

ARG OPENCODE_VERSION=1.17.14

# System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    build-essential \
    ca-certificates \
    curl \
    git \
    jq \
    openssh-client \
    ripgrep \
    unzip \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Install OpenCode binary (multi-arch)
ARG TARGETARCH
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x64") && \
    URL="https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-${ARCH}.tar.gz" && \
    echo "Downloading OpenCode v${OPENCODE_VERSION} (${ARCH}) from ${URL}" && \
    curl -fsSL -o /tmp/opencode.tar.gz "${URL}" && \
    tar -xzf /tmp/opencode.tar.gz -C /usr/local/bin opencode && \
    rm /tmp/opencode.tar.gz && \
    chmod +x /usr/local/bin/opencode && \
    opencode --version

# Create non-root user
RUN useradd -m -s /bin/bash opencode

# Create directories
RUN mkdir -p /home/opencode/.config/opencode \
             /home/opencode/.local/share/opencode \
             /workspace && \
    chown -R opencode:opencode /home/opencode /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER opencode
WORKDIR /workspace

EXPOSE 4096

ENTRYPOINT ["/entrypoint.sh"]
