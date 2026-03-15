#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

failures=0

error() {
  echo "ERROR: $*" >&2
  failures=$((failures + 1))
}

warn() {
  echo "WARN: $*" >&2
}

read_env_value() {
  local key="$1"
  awk -F= -v key="${key}" '
    $0 ~ "^[[:space:]]*" key "=" {
      sub(/^[^=]*=/, "", $0)
      print $0
      exit
    }
  ' .env
}

trim_spaces() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf "%s" "${value}"
}

env_file_mode() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    stat -f "%OLp" .env
  else
    stat -c "%a" .env
  fi
}

if [[ ! -f .env ]]; then
  error ".env not found. Run ./scripts/up.sh first."
else
  current_mode="$(env_file_mode || true)"
  if [[ "${current_mode}" != "600" ]]; then
    error ".env permissions are ${current_mode:-unknown}; expected 600."
  fi
fi

if [[ -f docker-compose.yml ]] && ! grep -q '127.0.0.1:4000:4000' docker-compose.yml; then
  error "docker-compose.yml must publish LiteLLM only on 127.0.0.1:4000."
fi

if [[ -f .env ]]; then
  master_key="$(read_env_value "LITELLM_MASTER_KEY" || true)"
  if [[ -z "${master_key}" ]]; then
    error "LITELLM_MASTER_KEY is empty in .env."
  fi

  required_provider_keys_raw="$(read_env_value "LITELLM_REQUIRED_PROVIDER_KEYS" || true)"
  required_provider_keys_raw="$(trim_spaces "${required_provider_keys_raw}")"

  declare -a required_provider_keys=()
  allowed_provider_keys=("OPENAI_API_KEY" "ANTHROPIC_API_KEY" "GEMINI_API_KEY")

  if [[ -n "${required_provider_keys_raw}" ]]; then
    IFS=',' read -r -a requested_keys <<< "${required_provider_keys_raw}"
    for key in "${requested_keys[@]}"; do
      cleaned_key="$(trim_spaces "${key}")"
      if [[ -z "${cleaned_key}" ]]; then
        continue
      fi
      case "${cleaned_key}" in
        OPENAI_API_KEY|ANTHROPIC_API_KEY|GEMINI_API_KEY)
          required_provider_keys+=("${cleaned_key}")
          ;;
        *)
          error "Unsupported value in LITELLM_REQUIRED_PROVIDER_KEYS: ${cleaned_key}"
          ;;
      esac
    done
  else
    for key in "${allowed_provider_keys[@]}"; do
      value="$(read_env_value "${key}" || true)"
      if [[ -n "${value}" ]]; then
        required_provider_keys+=("${key}")
      fi
    done
  fi

  if [[ ${#required_provider_keys[@]} -eq 0 ]]; then
    warn "No provider keys were marked as required. Set LITELLM_REQUIRED_PROVIDER_KEYS to enforce specific providers."
  fi

  for key in "${required_provider_keys[@]}"; do
    value="$(read_env_value "${key}" || true)"
    if [[ -z "${value}" ]]; then
      error "${key} is required but empty in .env."
    fi
  done
fi

if [[ ${failures} -ne 0 ]]; then
  echo "Security check failed (${failures} issue(s))." >&2
  exit 1
fi

echo "Security check passed."
