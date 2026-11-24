#!/usr/bin/env bash

# ============================================================
# PRACTICA 2 - PRUEBA DE LOGS CENTRALIZADOS
# ============================================================

set -euo pipefail

marker="practica2-demo-$(date +%s%N)"

echo "============================================"
echo " PRUEBA DE LOGS CENTRALIZADOS"
echo "============================================"

echo
echo "Identificador de prueba: $marker"

# Generar peticiones en ambos entornos.
for port in 8100 8200; do

    echo "Generando peticiones en puerto $port..."

    for i in $(seq 1 5); do

        curl -fsS --max-time 10 \
            "http://localhost:$port/status?demo=$marker" \
            >/dev/null

    done

done

echo
echo "Consultando los registros almacenados en Loki..."

python3 - "$marker" <<'PY'
import json
import sys
import time
import urllib.parse
import urllib.request

marker = sys.argv[1]

query = (
    '{container=~"practica2-(dev|prod)-nginx"}'
    ' |= "' + marker + '"'
)

print()
print("Consulta LogQL:")
print(query)
print()

expected = {
    "practica2-dev-nginx",
    "practica2-prod-nginx"
}

for intento in range(30):

    params = urllib.parse.urlencode({
        "query": query,
        "start": time.time_ns() - 300 * 10**9,
        "end": time.time_ns(),
        "limit": 100
    })

    url = (
        "http://127.0.0.1:8600"
        "/loki/api/v1/query_range?"
        + params
    )

    with urllib.request.urlopen(
        url,
        timeout=10
    ) as response:

        data = json.load(response)

    results = data["data"]["result"]

    counts = {}

    for item in results:

        name = item["stream"].get("container")

        counts[name] = (
            counts.get(name, 0)
            + len(item["values"])
        )

    if all(counts.get(name, 0) >= 5 for name in expected):

        for name in sorted(expected):
            print("Contenedor:", name)
            print("Registros encontrados:", counts[name])
            print("[OK]")
            print()

        print("[OK] Logs DEV y PROD centralizados.")
        break

    time.sleep(2)

else:
    raise SystemExit(
        "ERROR: No se encontraron los registros esperados."
    )
PY

echo
echo "============================================"
echo " PRUEBA DE LOGS COMPLETADA"
echo "============================================"
