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
    perl \
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

# Patch the embedded web client. OpenCode's JS defaults to http://localhost:4096
# when window.location.hostname contains the substring "opencode.ai" (so the
# official hosted UI talks to a user's local server). A self-hosted domain like
# opencode.example.com matches that substring and the browser wrongly tries
# localhost, breaking the app. Neutralize the check with a same-length byte swap
# (binary stays byte-for-byte valid). The assertions make the build FAIL loudly
# if a future opencode version no longer ships this exact pattern.
RUN perl -0777 -pi -e 's/includes\("opencode\.ai"\)/includes("opencode.zz")/' /usr/local/bin/opencode \
 && grep -aq 'includes("opencode.zz")' /usr/local/bin/opencode \
 && ! grep -aq 'includes("opencode.ai")' /usr/local/bin/opencode

# Create non-root user
RUN useradd -m -s /bin/bash opencode

# Create directories
RUN mkdir -p /home/opencode/.config/opencode \
             /home/opencode/.local/share/opencode \
             /workspace && \
    chown -R opencode:opencode /home/opencode /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy default OpenCode config (GLM-5.2 via Z.AI Anthropic endpoint)
COPY opencode.json /home/opencode/.config/opencode/opencode.json
RUN chown opencode:opencode /home/opencode/.config/opencode/opencode.json

USER opencode
WORKDIR /workspace

EXPOSE 4096

ENTRYPOINT ["/entrypoint.sh"]
