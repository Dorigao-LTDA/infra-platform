#!/usr/bin/env bash
set -euo pipefail

mkdir -p reports

report_file="reports/report.md"

echo "# Relatorio de gates" > "$report_file"

# TODO: integrar leitura de resultados k6/chaos em JSON
# Placeholder simples para validacao inicial

echo "- Status: PENDENTE" >> "$report_file"

echo "Relatorio gerado em $report_file"
