#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required but was not found on PATH." >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository; skipping hook installation." >&2
  exit 0
fi

mkdir -p .githooks
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks

echo "Installed git hooks path: .githooks"
echo "Pre-commit will run ./scripts/security-check.sh and ./scripts/scan-secrets.sh"
