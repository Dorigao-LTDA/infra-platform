#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TEST_KIND="${1:-predeploy}"
TARGET_URL="${TARGET_URL:-}"
SUMMARY_EXPORT="${SUMMARY_EXPORT:-}"

if [[ -z "$TARGET_URL" ]]; then
  echo "TARGET_URL is required (ex.: https://localhost:8080/healthz)." >&2
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
  if [[ -n "$SUMMARY_EXPORT" ]]; then
    TARGET_URL="$TARGET_URL" k6 run --summary-export "$SUMMARY_EXPORT" "$TEST_FILE"
  else
    TARGET_URL="$TARGET_URL" k6 run "$TEST_FILE"
  fi
  exit 0
fi

if command -v docker >/dev/null 2>&1; then
  docker_args=(-e TARGET_URL="$TARGET_URL" -v "$TEST_FILE":/test.js)
  if [[ -n "$SUMMARY_EXPORT" ]]; then
    summary_abs="$(realpath "$SUMMARY_EXPORT")"
    summary_dir="$(dirname "$summary_abs")"
    summary_file="$(basename "$summary_abs")"
    mkdir -p "$summary_dir"
    docker_args+=(-v "$summary_dir":/summary)
    docker run --rm -i "${docker_args[@]}" grafana/k6 run --summary-export "/summary/$summary_file" /test.js
  else
    docker run --rm -i "${docker_args[@]}" grafana/k6 run /test.js
  fi
  exit 0
fi

echo "k6 or docker is required to run performance tests." >&2
exit 1
