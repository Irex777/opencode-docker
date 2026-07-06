FROM debian:bookworm-slim

# Install runtime dependencies and build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        bash \
        curl \
        git \
        ca-certificates \
        ripgrep \
        jq \
        openssh-client \
        zsh \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

# Download and install the OpenCode binary (multi-arch aware)
ARG OPENCODE_VERSION=v1.17.14
RUN ARCH="$(dpkg --print-architecture)" && \
    case "$ARCH" in \
        arm64)   OCPKG_ARCH=arm64 ;; \
        amd64|x86_64) OCPKG_ARCH=x64 ;; \
        *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;; \
    esac && \
    curl -fsSL -o /tmp/opencode.tar.gz \
        "https://github.com/anomalyco/opencode/releases/download/${OPENCODE_VERSION}/opencode-linux-${OCPKG_ARCH}.tar.gz" && \
    mkdir -p /tmp/opencode-extract && \
    tar -xzf /tmp/opencode.tar.gz -C /tmp/opencode-extract && \
    install -m 0755 /tmp/opencode-extract/opencode /usr/local/bin/opencode && \
    rm -rf /tmp/opencode.tar.gz /tmp/opencode-extract

# Create non-root user (UID 1000)
RUN useradd --uid 1000 --create-home --shell /usr/bin/zsh opencode

# Create directories owned by opencode
RUN mkdir -p /workspace \
    /home/opencode/.config/opencode \
    /home/opencode/.local/share/opencode \
    && chown -R opencode:opencode /workspace /home/opencode/.config /home/opencode/.local

# Copy entrypoint
COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 4096
WORKDIR /workspace

USER opencode

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["opencode", "web", "--hostname", "0.0.0.0", "--port", "4096"]
