#!/usr/bin/env bash
set -euo pipefail

curl -fsS http://127.0.0.1:4000/health/readiness | sed -e 's/^/readiness: /'
