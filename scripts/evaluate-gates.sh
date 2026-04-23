#!/usr/bin/env bash
set -euo pipefail

mkdir -p reports

report_file="reports/report.md"
status_file="reports/status.env"
overall="PASS"

predeploy_summary="${PREDEPLOY_SUMMARY:-reports/predeploy-summary.json}"
postdeploy_summary="${POSTDEPLOY_SUMMARY:-reports/postdeploy-summary.json}"
resilience_status="${RESILIENCE_STATUS:-unknown}"

extract_metric() {
  local file="$1"
  local metric="$2"
  if [[ ! -f "$file" ]]; then
    echo ""
    return 0
  fi

  python3 - "$file" "$metric" <<'PY' 2>/dev/null || true
import json
import sys

file_path = sys.argv[1]
metric = sys.argv[2]

with open(file_path, "r", encoding="utf-8") as f:
    data = json.load(f)

metrics = data.get("metrics", {})
if metric == "p95":
    value = metrics.get("http_req_duration", {}).get("values", {}).get("p(95)")
elif metric == "fail_rate":
    value = metrics.get("http_req_failed", {}).get("values", {}).get("rate")
else:
    value = None

if value is not None:
    print(value)
PY
}

pre_p95="$(extract_metric "$predeploy_summary" "p95")"
pre_fail="$(extract_metric "$predeploy_summary" "fail_rate")"
post_p95="$(extract_metric "$postdeploy_summary" "p95")"
post_fail="$(extract_metric "$postdeploy_summary" "fail_rate")"

echo "# Relatorio de gates" > "$report_file"
echo "" >> "$report_file"
echo "| Gate | Resultado | Detalhe |" >> "$report_file"
echo "|---|---|---|" >> "$report_file"

if [[ -n "$pre_p95" && -n "$pre_fail" ]]; then
  echo "| Performance pre-deploy | PASS | p95=${pre_p95}ms, erro=${pre_fail} |" >> "$report_file"
else
  echo "| Performance pre-deploy | FAIL | resumo ausente em ${predeploy_summary} |" >> "$report_file"
  overall="FAIL"
fi

if [[ -n "$post_p95" && -n "$post_fail" ]]; then
  echo "| Performance post-deploy | PASS | p95=${post_p95}ms, erro=${post_fail} |" >> "$report_file"
else
  echo "| Performance post-deploy | FAIL | resumo ausente em ${postdeploy_summary} |" >> "$report_file"
  overall="FAIL"
fi

if [[ "$resilience_status" == "pass" ]]; then
  echo "| Resiliencia | PASS | recuperacao validada |" >> "$report_file"
else
  echo "| Resiliencia | FAIL | status=${resilience_status} |" >> "$report_file"
  overall="FAIL"
fi

echo "" >> "$report_file"
echo "**Status final:** ${overall}" >> "$report_file"
echo "OVERALL_STATUS=${overall}" > "$status_file"

echo "Relatorio gerado em $report_file"
if [[ "$overall" != "PASS" ]]; then
  exit 1
fi
