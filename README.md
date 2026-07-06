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

At least one LLM provider key is required. OpenCode also supports custom OpenAI-compatible endpoints via `opencode.json` config.

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
