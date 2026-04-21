#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TEST_KIND="${1:-predeploy}"
TARGET_URL="${TARGET_URL:-}"

if [[ -z "$TARGET_URL" ]]; then
  echo "TARGET_URL is required (ex.: https://argocd.dorigao.dev.br/)." >&2
  exit 1
fi

case "$TEST_KIND" in
  predeploy)
    TEST_FILE="$REPO_ROOT/tests/perf/predeploy-infra.js"
    ;;
  postdeploy)
    TEST_FILE="$REPO_ROOT/tests/perf/postdeploy-app.js"
    ;;
  *)
    echo "Usage: $0 [predeploy|postdeploy] (set TARGET_URL)" >&2
    exit 1
    ;;
 esac

if [[ ! -f "$TEST_FILE" ]]; then
  echo "Test file not found: $TEST_FILE" >&2
  exit 1
fi

if command -v k6 >/dev/null 2>&1; then
  TARGET_URL="$TARGET_URL" k6 run "$TEST_FILE"
  exit 0
fi

if command -v docker >/dev/null 2>&1; then
  docker run --rm -i -e TARGET_URL="$TARGET_URL" -v "$TEST_FILE":/test.js grafana/k6 run /test.js
  exit 0
fi

echo "k6 or docker is required to run performance tests." >&2
exit 1
