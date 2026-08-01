# Exposing Local GGUF Models through LiteLLM

This guide explains how downstream agents can run an existing or newly
obtained GGUF model with `llama-server` and expose it through the local LiteLLM
proxy.

The current local architecture is:

```text
Downstream agent on macOS
  -> http://127.0.0.1:4000/v1
  -> LiteLLM in Docker
  -> http://host.docker.internal:8080/v1
  -> llama-server on the macOS host
```

The downstream client should use port `4000`. Port `8080` is the local model
server and is normally used only by LiteLLM or direct diagnostics.

## Prerequisites

- Docker Desktop with `docker compose`
- A working LiteLLM proxy in this repository
- `llama-server` installed and available on `PATH`
- A compatible GGUF model file
- An optional vision projection GGUF (`mmproj`) when the model requires one

Check the services before starting:

```bash
./scripts/health.sh
llama-server --version
```

## Use an existing GGUF file

Model files can live anywhere locally. Keeping them under
`local_models/<model-name>/` makes the setup easier to share:

```text
local_models/
└── my-model/
    ├── model.gguf
    ├── mmproj-model.gguf       # optional, for vision models
    └── run_llamacpp.sh
```

GGUF files are intentionally ignored by Git because they can be several
gigabytes. Scripts and documentation can still be committed.

Start a text-only model directly:

```bash
llama-server \
  --model /absolute/path/to/model.gguf \
  --port 8080 \
  --n-gpu-layers 99 \
  --ctx-size 64000
```

For a vision-capable model, add its projection adapter:

```bash
llama-server \
  --model /absolute/path/to/model.gguf \
  --mmproj /absolute/path/to/mmproj-model.gguf \
  --port 8080 \
  --n-gpu-layers 99 \
  --ctx-size 64000
```

The short flags used by the existing scripts (`-m`, `--mmproj`, `-ngl`, and
`-c`) are equivalent. Use the long forms when writing a new shared script.

## Download a new GGUF model

Obtain the GGUF and any required adapter from a source you trust. For a direct
download, use a model-specific setup script and fail on HTTP errors:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

curl -fL --retry 3 -O "https://example.invalid/model.gguf"
curl -fL --retry 3 -O "https://example.invalid/mmproj-model.gguf"
```

Do not add authentication tokens, private URLs, or downloaded model binaries
to Git. Prefer a model README or setup script that records the source without
recording secrets.

## Create a reusable runner

A runner should validate the files before starting the server and use `exec`
so signals are delivered correctly:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_PATH="$SCRIPT_DIR/model.gguf"
MMPROJ_PATH="$SCRIPT_DIR/mmproj-model.gguf"

if [[ ! -f "$MODEL_PATH" ]]; then
  echo "Model not found: $MODEL_PATH" >&2
  exit 1
fi

args=(
  --model "$MODEL_PATH"
  --port 8080
  --n-gpu-layers 99
  --ctx-size 64000
)

if [[ -f "$MMPROJ_PATH" ]]; then
  args+=(--mmproj "$MMPROJ_PATH")
fi

exec llama-server "${args[@]}"
```

Make it executable once:

```bash
chmod +x run_llamacpp.sh
```

If LiteLLM cannot reach the server from Docker, explicitly bind the server to
the host interfaces by adding:

```bash
--host 0.0.0.0
```

Use this only on a trusted local machine and keep LiteLLM's published port
localhost-only as configured in `docker-compose.yml`.

## Add a LiteLLM model alias

Add an alias to `config/config.yaml`. The alias is what downstream clients use;
the `api_base` points LiteLLM at the host server through Docker Desktop:

```yaml
  - model_name: my-local-model
    litellm_params:
      model: openai/local-model
      api_base: http://host.docker.internal:8080/v1
      api_key: sk-no-key-required
      rpm_limit: 1000
```

The `openai/` prefix tells LiteLLM to use the OpenAI-compatible API. The
downstream client should send `my-local-model`, not the internal placeholder
after `openai/`.

The existing aliases are:

```text
qwen3.5-aggressive
qwen3.5-heretic
```

After changing `config/config.yaml`, restart or recreate LiteLLM so the proxy
reloads the configuration:

```bash
docker compose up -d --force-recreate litellm
```

## Configure a downstream agent

Use the LiteLLM endpoint and current proxy master key in the downstream
project's local, gitignored environment file:

```bash
export LITELLM_API_BASE="http://127.0.0.1:4000/v1"
export LITELLM_API_KEY="<current LITELLM_MASTER_KEY>"
export RAG_LLM_MODEL="my-local-model"
```

Do not put the key in source code, committed documentation, or test fixtures.

## Verify the complete path

1. Start one llama-server runner and leave it running.

2. Check the direct model server:

   ```bash
   curl http://127.0.0.1:8080/health
   ```

   Expected response:

   ```json
   {"status":"ok"}
   ```

3. Check LiteLLM:

   ```bash
   ./scripts/health.sh
   ```

4. Check that the alias is visible through the authenticated proxy:

   ```bash
   curl -fsS \
     -H "Authorization: Bearer ${LITELLM_API_KEY}" \
     http://127.0.0.1:4000/v1/models
   ```

5. Send a completion through LiteLLM using the alias:

   ```bash
   curl -fsS \
     -H "Authorization: Bearer ${LITELLM_API_KEY}" \
     -H 'Content-Type: application/json' \
     http://127.0.0.1:4000/v1/chat/completions \
     -d '{
       "model": "my-local-model",
       "messages": [{"role": "user", "content": "Reply with: proxy works"}]
     }'
   ```

The direct health check proves llama-server is alive; only the completion
through port `4000` proves that Docker networking, LiteLLM routing, the alias,
and the downstream authentication all work together.

## One active model versus multiple models

The current setup uses port `8080` for the active local model. Both existing
Qwen aliases currently point to that same port, so only one Qwen llama-server
should be running at a time.

To serve multiple models simultaneously, assign each server a different host
port and give each LiteLLM alias a matching `api_base`, for example:

```yaml
      api_base: http://host.docker.internal:8081/v1
```

That is a separate routing change and should be validated independently.

## Troubleshooting

- `curl 127.0.0.1:8080/health` fails: llama-server is not running, the model
  path is wrong, or the server failed during startup.
- LiteLLM readiness fails: inspect `docker compose ps` and
  `docker compose logs --tail=100 litellm`.
- `/v1/models` returns `401`: use the current LiteLLM master key.
- LiteLLM returns a backend connection error: confirm llama-server is on the
  configured port and, if needed, add `--host 0.0.0.0` to the runner.
- The alias is missing: confirm the model entry is valid YAML and recreate the
  LiteLLM container.
