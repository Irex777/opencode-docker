# OpenCode Web — Docker / Coolify

Container image for running [OpenCode](https://opencode.ai) Web UI (`opencode web`) on Coolify (ARM64 VPS).

## What it does

Starts the OpenCode Web server on `0.0.0.0:4096`:

```
opencode web --hostname 0.0.0.0 --port 4096
```

Docs: https://opencode.ai/docs/web/

## Deploy on Coolify

1. Create a new **Application** in Coolify, connect this Git repository.
2. **Build Pack**: Dockerfile (Coolify auto-detects the `Dockerfile`).
3. **Port**: `4096`.
4. Add environment variables (under Coolify → Environment):
   - `OPENCODE_SERVER_PASSWORD` — password for the web UI.
   - `OPENCODE_SERVER_USERNAME` — username for the web UI (optional).
   - `ANTHROPIC_API_KEY` — API key used by OpenCode.
5. Deploy. The app will be available at your Coolify domain on port `4096`.

## Multi-arch

The Dockerfile detects the build host architecture via `dpkg --print-architecture` and downloads the matching OpenCode release tarball:

- `arm64`  → `opencode-linux-arm64.tar.gz`
- `amd64`  → `opencode-linux-x64.tar.gz`

OpenCode version is pinned to `v1.17.14` (override at build time with `--build-arg OPENCODE_VERSION=...`).

## Run locally with Docker Compose (optional)

```bash
export OPENCODE_SERVER_PASSWORD=changeme
export ANTHROPIC_API_KEY=sk-ant-...

docker compose up -d --build
```

Then open http://localhost:4096.

## Files

| File              | Purpose                                                  |
| ----------------- | -------------------------------------------------------- |
| `Dockerfile`      | Builds the image (used by Coolify).                      |
| `entrypoint.sh`   | Runs `opencode web` as the `opencode` user.              |
| `docker-compose.yml` | Local run reference (not used by Coolify).           |
