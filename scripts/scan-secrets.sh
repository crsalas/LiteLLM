#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "gitleaks not found. Install it from https://github.com/gitleaks/gitleaks and rerun." >&2
  exit 1
fi

if [[ "${1:-}" == "--full" ]]; then
  shift
  gitleaks detect --source . --no-git --redact "$@"
else
  gitleaks detect --source . --redact "$@"
fi
