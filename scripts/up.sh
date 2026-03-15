#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

generate_master_key() {
  if command -v openssl >/dev/null 2>&1; then
    printf "sk-litellm-%s" "$(openssl rand -hex 24)"
    return
  fi

  # Fallback if openssl is unavailable.
  printf "sk-litellm-%s" "$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 48)"
}

set_env_value() {
  local key="$1"
  local value="$2"
  local tmp_file

  tmp_file="$(mktemp)"
  awk -v key="$key" -v value="$value" '
    BEGIN { updated = 0 }
    $0 ~ "^" key "=" {
      if (updated == 0) {
        print key "=" value
        updated = 1
      }
      next
    }
    { print }
    END {
      if (updated == 0) {
        print key "=" value
      }
    }
  ' .env > "${tmp_file}"
  mv "${tmp_file}" .env
}

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required but was not found on PATH." >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example."
fi

chmod 600 .env

set_env_value "LITELLM_UID" "$(id -u)"
set_env_value "LITELLM_GID" "$(id -g)"

current_master_key="$(grep -E '^LITELLM_MASTER_KEY=' .env | head -n 1 | cut -d '=' -f 2- || true)"
if [[ -z "${current_master_key}" ]]; then
  new_master_key="$(generate_master_key)"
  set_env_value "LITELLM_MASTER_KEY" "${new_master_key}"
  echo "Generated LITELLM_MASTER_KEY in .env"
fi

./scripts/security-check.sh

docker compose up -d

echo "LiteLLM proxy is starting on http://127.0.0.1:4000"
echo "Run: ./scripts/health.sh"
