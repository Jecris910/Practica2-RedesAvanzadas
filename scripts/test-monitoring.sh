#!/usr/bin/env bash

# Comprobar los servicios de monitorizacion.
set -euo pipefail

check_http() {

    printf '%-15s ' "$1"

    curl -fsS --max-time 10 "$2" >/dev/null

    echo "[OK]"
}

echo "=========================================="
echo " SERVICIOS DE MONITORIZACION"
echo "=========================================="

check_http "cAdvisor" \
    "http://127.0.0.1:8300/metrics"

check_http "Prometheus" \
    "http://127.0.0.1:8400/-/ready"

check_http "Grafana" \
    "http://127.0.0.1:8500/api/health"

check_http "Loki" \
    "http://127.0.0.1:8600/ready"

check_http "Alloy" \
    "http://127.0.0.1:8700/-/ready"

check_http "Mailpit" \
    "http://127.0.0.1:8025/"

check_http "MinIO" \
    "http://127.0.0.1:8800/minio/health/live"

echo
echo "===== TARGETS PROMETHEUS ====="

curl -fsS \
    http://127.0.0.1:8400/api/v1/targets | \
python3 -c '
import json
import sys

targets = json.load(sys.stdin)["data"]["activeTargets"]

assert targets, "No hay targets configurados"

for target in targets:
    print(target["scrapeUrl"], "-", target["health"])

assert all(
    target["health"] == "up"
    for target in targets
)
'

echo
echo "===== METRICAS DISPONIBLES ====="

for metric in \
    container_cpu_usage_seconds_total \
    container_memory_usage_bytes \
    container_last_seen
do

    curl -fsS -G \
        http://127.0.0.1:8400/api/v1/query \
        --data-urlencode "query=count(${metric}{name=~\"practica2-(dev|prod)-.*\"})" | \
    python3 -c '
import json
import sys

data = json.load(sys.stdin)
result = data["data"]["result"]

assert result
assert float(result[0]["value"][1]) > 0

print(sys.argv[1], "- [OK]")
' "$metric"

done

echo
echo "[OK] Monitorizacion comprobada."
