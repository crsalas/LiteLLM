#!/usr/bin/env bash
set -euo pipefail

echo "Warning: logs may include prompts and metadata. Use only for active troubleshooting." >&2
docker compose logs -f --tail "${LITELLM_LOG_TAIL:-200}" litellm
