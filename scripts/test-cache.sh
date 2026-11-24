#!/usr/bin/env bash

# Comprobacion de CACHE MISS y CACHE HIT.
set -euo pipefail

for env in dev prod; do

    if [ "$env" = "dev" ]; then
        port=8100
    else
        port=8200
    fi

    echo
    echo "=========================================="
    echo " PRUEBA CACHE ${env^^}"
    echo "=========================================="

    # Eliminar exclusivamente la cache de equipos.
    docker exec "practica2-$env-redis" \
        redis-cli DEL teams >/dev/null

    for expected in MISS HIT; do

        curl -fsS --max-time 10 \
            "http://localhost:$port/teams" | \
        python3 -c '
import json
import sys

data = json.load(sys.stdin)

print("Origen:", data["source"])
print("Cache:", data["cache"])
print("Tiempo:", data["load_time_ms"], "ms")
print("Equipos:", len(data["teams"]))
print()

assert data["cache"] == sys.argv[1]
assert data["source"] == (
    "database" if sys.argv[1] == "MISS" else "cache"
)
' "$expected"

    done

done

echo "[OK] Cache DEV y PROD comprobada."
