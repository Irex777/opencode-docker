# OpenCode Web — Docker

Self-hosted [OpenCode](https://opencode.ai) web UI — browser-based AI coding agent.

## Quick Start

```bash
cp .env.example .env  # set your passwords and API keys
docker compose up -d
```

Open `http://localhost:4096`.

## Environment Variables

| Key | Required | Default | Purpose |
|-----|----------|---------|---------|
| `OPENCODE_SERVER_PASSWORD` | **yes** | — | Web UI auth password |
| `OPENCODE_SERVER_USERNAME` | no | `opencode` | Web UI auth username |
| `ANTHROPIC_API_KEY` | one provider | — | Anthropic API key |
| `OPENAI_API_KEY` | one provider | — | OpenAI API key |
| `GEMINI_API_KEY` | one provider | — | Google AI key |
| `GITHUB_TOKEN` | no | — | GitHub PAT (`repo` scope) to clone private repos |
| `GITHUB_REPOS` | no | — | Space-separated `owner/repo` (or `owner/repo@branch`) specs to clone into `/workspace` |
| `GIT_USER_NAME` | no | `OpenCode` | Author name for commits made inside OpenCode |
| `GIT_USER_EMAIL` | no | `opencode@localhost` | Author email for commits made inside OpenCode |

At least one LLM provider key is required. OpenCode also supports custom OpenAI-compatible endpoints via `opencode.json` config.

## Git Project Integration

On startup the entrypoint clones (or pulls) every repo listed in `GITHUB_REPOS`
into `/workspace`, authenticating with `GITHUB_TOKEN`. Each cloned repo then
shows up as a **project** in the web UI's project switcher, so you can open it
and start a new session from it.

```bash
GITHUB_TOKEN=ghp_xxx
GITHUB_REPOS="Irex777/opencode-docker Irex777/my-project@develop"
GIT_USER_NAME="Anton"
GIT_USER_EMAIL="anton@example.com"
```

Specs:

- `owner/repo` — clone the default branch.
- `owner/repo@branch` — clone and check out a specific branch.

Repos are re-synced every time the container starts, so pushes you make
elsewhere are picked up on the next restart/redeploy. Commits you create inside
OpenCode are authored with `GIT_USER_NAME` / `GIT_USER_EMAIL` and can be pushed
back using the same `GITHUB_TOKEN`.

## Volumes

| Path | Purpose |
|------|---------|
| `/workspace` | Your code repositories |
| `/home/opencode/.config` | OpenCode config, skills, MCP settings |
| `/home/opencode/.local/share` | OpenCode data, sessions, auth |

## Custom Provider (OpenAI-compatible)

Mount an `opencode.json` at `/home/opencode/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "custom": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "My LLM",
      "options": {
        "baseURL": "https://your-endpoint/v1",
        "apiKey": "{env:MY_API_KEY}"
      },
      "models": {
        "model-name": {
          "name": "Model Display Name"
        }
      }
    }
  }
}
```

## Architecture

Multi-arch build — auto-detects ARM64 (Coolify VPS) and x64. Pinned to OpenCode v1.17.14.

### Why a binary patch?

The OpenCode web client picks its server URL with roughly:

```js
location.hostname.includes("opencode.ai") ? "http://localhost:4096" : location.origin
```

That works for the official hosted UI on `opencode.ai`, but **any** self-hosted
domain containing the substring `opencode.ai` (e.g. `opencode.example.com`)
matches and the browser tries `localhost:4096`, breaking the app. The Dockerfile
neutralizes this with a same-length byte swap on the `opencode` binary
(`includes("opencode.ai")` → `includes("opencode.zz")`). If a future version
drops this pattern the build fails loudly instead of silently shipping a broken
client.
