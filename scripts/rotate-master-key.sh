#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f .env ]]; then
  echo ".env not found. Run ./scripts/up.sh first." >&2
  exit 1
fi

if command -v openssl >/dev/null 2>&1; then
  new_master_key="sk-litellm-$(openssl rand -hex 24)"
else
  new_master_key="sk-litellm-$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 48)"
fi

tmp_file="$(mktemp)"
awk -v value="${new_master_key}" '
  BEGIN { updated = 0 }
  /^LITELLM_MASTER_KEY=/ {
    if (updated == 0) {
      print "LITELLM_MASTER_KEY=" value
      updated = 1
    }
    next
  }
  { print }
  END {
    if (updated == 0) {
      print "LITELLM_MASTER_KEY=" value
    }
  }
' .env > "${tmp_file}"
mv "${tmp_file}" .env
chmod 600 .env

echo "Rotated LITELLM_MASTER_KEY in .env"
echo "Restart the proxy with ./scripts/down.sh && ./scripts/up.sh"
