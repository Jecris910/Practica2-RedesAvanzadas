#!/usr/bin/env bash

set -euo pipefail

containers=(
    practica2-dev-nginx
    practica2-dev-flask-1
    practica2-dev-flask-2
    practica2-dev-mysql
    practica2-dev-redis
    practica2-prod-nginx
    practica2-prod-flask-1
    practica2-prod-flask-2
    practica2-prod-flask-3
    practica2-prod-mysql
    practica2-prod-redis
    practica2-cadvisor
    practica2-prometheus
    practica2-grafana
    practica2-loki
    practica2-alloy
    practica2-mailpit
    practica2-minio
)

declare -A counts=(
    [healthy]=0
    [unhealthy]=0
    [starting]=0
    [none]=0
    [stopped]=0
    [missing]=0
)

echo
echo "===== ESTADO DE SALUD ====="
echo

for container in "${containers[@]}"; do

    if info=$(docker container inspect \
        --format '{{.State.Running}} {{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
        "$container" 2>/dev/null); then

        read -r running health <<< "$info"

        if [[ "$running" != "true" ]]; then
            health=stopped
        fi

    else
        health=missing
    fi

    counts[$health]=$((counts[$health] + 1))

    case "$health" in
        healthy)   estado="HEALTHY" ;;
        unhealthy) estado="UNHEALTHY" ;;
        starting)  estado="STARTING" ;;
        none)      estado="UP - SIN HEALTHCHECK" ;;
        stopped)   estado="DETENIDO" ;;
        missing)   estado="NO ENCONTRADO" ;;
    esac

    printf "%-30s [%s]\n" "$container" "$estado"

done

echo
echo "===== RESUMEN ====="
echo "Healthy:         ${counts[healthy]}"
echo "Unhealthy:       ${counts[unhealthy]}"
echo "Starting:        ${counts[starting]}"
echo "Sin healthcheck: ${counts[none]}"
echo "Detenidos:       ${counts[stopped]}"
echo "No encontrados:  ${counts[missing]}"

if (( counts[unhealthy] + counts[starting] \
    + counts[stopped] + counts[missing] > 0 )); then

    echo "[ERROR] Estado incorrecto."
    exit 1
fi

echo "[OK] Estado Docker correcto."

