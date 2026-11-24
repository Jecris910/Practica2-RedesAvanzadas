#!/usr/bin/env bash

# Comprobar la persistencia de datos MySQL.
set -euo pipefail

obtener_hash() {

    curl -fsS --max-time 10 \
        "http://localhost:$1/players" | \
    python3 -c '
import hashlib
import json
import sys

data = json.load(sys.stdin)
players = data["players"]

assert players, "No hay jugadores"

content = json.dumps(
    players,
    sort_keys=True,
    ensure_ascii=False
).encode()

print(hashlib.sha256(content).hexdigest())
'
}

for env in dev prod; do

    if [ "$env" = "dev" ]; then
        port=8100
    else
        port=8200
    fi

    echo
    echo "=========================================="
    echo " PERSISTENCIA MYSQL ${env^^}"
    echo "=========================================="

    antes="$(obtener_hash "$port")"

    echo "Hash inicial: $antes"

    echo
    echo "Volumen persistente:"

    docker inspect \
        --format '{{range .Mounts}}{{println .Name .Destination}}{{end}}' \
        "practica2-$env-mysql"

    echo
    echo "Reiniciando MySQL..."

    docker restart "practica2-$env-mysql"

    despues=""
    ready=0

    for i in $(seq 1 60); do

        if despues="$(obtener_hash "$port" 2>/dev/null)"; then
            ready=1
            break
        fi

        sleep 2

    done

    if [ "$ready" -ne 1 ]; then
        echo "ERROR: MySQL no se ha recuperado."
        exit 1
    fi

    echo "Hash final:   $despues"

    if [ "$antes" != "$despues" ]; then
        echo "ERROR: Los datos son diferentes."
        exit 1
    fi

    echo "[OK] Los datos se conservan."

done

echo
echo "[OK] Persistencia DEV y PROD comprobada."
