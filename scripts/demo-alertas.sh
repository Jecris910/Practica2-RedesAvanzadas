#!/usr/bin/env bash

# PRACTICA 2 - Pruebas controladas de alertas.
set -euo pipefail

cd "$(dirname "$0")/.."

port=8200

case "${1:-}" in
    flask-dev)
        container="practica2-dev-flask-2"
        port=8100
        ;;
    flask-prod)
        container="practica2-prod-flask-2"
        ;;
    nginx)
        container="practica2-prod-nginx"
        ;;
    mysql)
        container="practica2-prod-mysql"
        ;;
    redis)
        container="practica2-prod-redis"
        ;;
    *)
        echo "Uso: $0 flask-dev|flask-prod|nginx|mysql|redis"
        exit 1
        ;;
esac

stopped=0

# Recuperar el servicio si se interrumpe la prueba.
cleanup() {
    if [ "$stopped" -eq 1 ]; then
        echo "Recuperando $container..."
        docker start "$container" >/dev/null
    fi
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

docker inspect -f '{{.State.Running}}' "$container" \
    | grep -qx true

echo "============================================"
echo " PRUEBA CONTROLADA DE ALERTAS"
echo "============================================"
echo "Contenedor: $container"
echo "Grafana: http://localhost:8500"
echo "Mailpit: http://localhost:8025"

read -r -p "Pulsa ENTER para detener el servicio..." dummy

stopped=1
docker stop "$container"

echo
echo "===== ESTADO DE LA APLICACION ====="

curl -fsS --max-time 10 \
    "http://localhost:$port/status" \
    || echo "Aplicacion temporalmente inaccesible."

echo
echo "Esperando la deteccion de la alerta..."

for i in $(seq 60 -1 1); do
    printf "\rTiempo restante: %02d segundos " "$i"
    sleep 1
done

echo
echo "Comprueba la alerta Firing en Grafana."
echo "Comprueba la notificacion en Mailpit."

case "$1" in
    flask-dev)
        make balance-dev
        ;;
    flask-prod)
        make balance-prod
        ;;
esac

read -r -p "Pulsa ENTER para recuperar el servicio..." dummy

docker start "$container"
stopped=0

echo "===== RECUPERACION ====="

ready=0

for i in $(seq 1 60); do

    if curl -fsS --max-time 5 \
        "http://localhost:$port/status" 2>/dev/null | \
        python3 -c '
import json
import sys

data = json.load(sys.stdin)

assert all(
    data.get(k) == "connected"
    for k in ("web", "database", "cache")
)

print(json.dumps(data, indent=2))
' 2>/dev/null; then

        ready=1
        break
    fi

    sleep 2
done

if [ "$ready" -ne 1 ]; then
    echo "ERROR: El servicio no se ha recuperado."
    exit 1
fi

echo "Comprueba que la alerta vuelve a Normal."

read -r -p "Pulsa ENTER para finalizar..." dummy

echo "[OK] Servicio recuperado."
