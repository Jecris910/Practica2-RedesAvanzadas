#!/usr/bin/env bash

# PRACTICA 2 - REDES AVANZADAS
# Demostracion interactiva de funcionamiento.

set -euo pipefail

cd "$(dirname "$0")/.."

TOTAL=16

paso() {
    echo
    echo "============================================================"
    echo " [$1/$TOTAL] $2"
    echo "============================================================"
    echo
    read -r -p "Pulsa ENTER para continuar..." dummy
    echo
}

ejecutar() {
    make --no-print-directory "$@"
}

# Consultar metricas reales de Prometheus.
metrica() {
    local query="$1"
    local unidad="$2"

    curl -fsS -G \
        http://127.0.0.1:8400/api/v1/query \
        --data-urlencode "query=$query" |
    python3 -c '
import json
import sys

data = json.load(sys.stdin)

assert data["status"] == "success"

result = data["data"]["result"]

assert result, "No se han encontrado metricas"

for item in result:
    name = item["metric"].get("name", "unknown")
    value = float(item["value"][1])
    print(f"{name:35} {value:.2f} {sys.argv[1]}")
' "$unidad"
}

clear

echo "============================================================"
echo "              PRACTICA 2 - REDES AVANZADAS"
echo "                DEMOSTRACION FUNCIONAL"
echo "============================================================"

# ============================================================
# 1. ESTADO INICIAL
# ============================================================

paso 1 "CONTENEDORES DESPLEGADOS"

ejecutar status

cantidad=$(docker ps \
    --filter "name=practica2-" \
    --format '{{.Names}}' | wc -l)

echo
echo "Contenedores activos: $cantidad/18"

test "$cantidad" -eq 18

# ============================================================
# 2. DEV Y PROD
# ============================================================

paso 2 "FUNCIONAMIENTO SIMULTANEO DEV Y PROD"

ejecutar check

python3 - <<'PY'
import json
import urllib.request

for env, port in [("dev", 8100), ("prod", 8200)]:

    with urllib.request.urlopen(
        f"http://127.0.0.1:{port}/status",
        timeout=10
    ) as response:
        data = json.load(response)

    assert data["environment"] == env

    for service in ["web", "database", "cache"]:
        assert data[service] == "connected", data

    print(f"[OK] {env.upper()}: Web, MySQL y Redis")

PY

echo
echo "DEV:  http://localhost:8100"
echo "PROD: http://localhost:8200"

echo
echo "Mostrar ambas aplicaciones en el navegador."

# ============================================================
# 3. BALANCEO DEV
# ============================================================

paso 3 "ROUND ROBIN DEV - DOS REPLICAS"

ejecutar balance-dev

# ============================================================
# 4. BALANCEO PROD
# ============================================================

paso 4 "ROUND ROBIN PROD - TRES REPLICAS"

ejecutar balance-prod

# ============================================================
# 5. IDENTIFICACION DE INSTANCIAS
# ============================================================

paso 5 "IDENTIFICACION DE INSTANCIAS EN LA WEB"

python3 - <<'PY'
import re
import urllib.request
from collections import Counter

for env, port, replicas in [
    ("dev", 8100, 2),
    ("prod", 8200, 3)
]:

    counts = Counter()

    print(f"\n===== {env.upper()} =====")

    for i in range(12):

        with urllib.request.urlopen(
            f"http://127.0.0.1:{port}/",
            timeout=10
        ) as response:
            html = response.read().decode()

        match = re.search(
            r'id="instance-id">\s*([^<]+)',
            html
        )

        assert match, "Instancia no encontrada en HTML"

        instance = match.group(1).strip()

        counts[instance] += 1

        print(f"Peticion {i+1:02}: {instance}")

    expected = {
        f"{env}-flask-{i}"
        for i in range(1, replicas+1)
    }

    assert set(counts) == expected, counts

    print("\nDistribucion:")

    for name, total in sorted(counts.items()):
        print(f"  {name}: {total}")

    print("[OK] Todas las instancias visibles.")

PY

echo
echo "Actualizar DEV y PROD en el navegador."

# ============================================================
# 6. INSERCION, PERSISTENCIA Y ELIMINACION
# ============================================================

paso 6 "BASE DE DATOS Y PERSISTENCIA MYSQL"

echo "1. Insertar jugador temporal."
echo "2. Comprobar que aparece en la aplicacion."
echo "3. Recrear MySQL."
echo "4. Comprobar que el jugador permanece."
echo "5. Eliminar el jugador temporal."
echo "6. Comprobar los datos originales."
echo

ejecutar test-persistencia

# ============================================================
# 7. CACHE
# ============================================================

paso 7 "CACHE REDIS - MISS Y HIT"

echo "Cerrar temporalmente las webs antes de la prueba"
echo "para evitar consultas simultaneas a la cache."

read -r -p "Pulsa ENTER para probar Redis..." dummy

ejecutar test-cache

echo
echo "Mostrar el indicador de cache en la aplicacion."

# ============================================================
# 8. MINIO
# ============================================================

paso 8 "ALMACENAMIENTO COMPARTIDO MINIO"

ejecutar test-minio

echo
ejecutar check-minio

echo
echo "Mostrar el archivo compartido en DEV y PROD."
echo "Consola MinIO: http://localhost:8801"

# ============================================================
# 9. MONITORIZACION
# ============================================================

paso 9 "SERVICIOS DE MONITORIZACION"

ejecutar test-monitoring

echo
echo "cAdvisor:   http://localhost:8300"
echo "Prometheus: http://localhost:8400/targets"
echo "Grafana:    http://localhost:8500"

# ============================================================
# 10. CPU
# ============================================================

paso 10 "GRAFICAS DE CPU"

metrica \
    '100 * sum by(name) (rate(container_cpu_usage_seconds_total{name=~"practica2-(dev|prod)-.*"}[1m]))' \
    "% de un nucleo"

echo
echo "Mostrar la grafica de CPU en Grafana."

# ============================================================
# 11. MEMORIA RAM
# ============================================================

paso 11 "GRAFICAS DE MEMORIA RAM"

metrica \
    'container_memory_usage_bytes{name=~"practica2-(dev|prod)-.*"} / 1024 / 1024' \
    "MiB"

echo
echo "Mostrar la grafica de RAM en Grafana."

# ============================================================
# 12. ESTADO DE CONTENEDORES
# ============================================================

paso 12 "ESTADO DE LOS CONTENEDORES"

query='max by(name) (container_last_seen{name=~"practica2-(dev|prod)-.*"})'

curl -fsS -G \
    http://127.0.0.1:8400/api/v1/query \
    --data-urlencode "query=$query" |
python3 -c '
import json
import sys
import time

data = json.load(sys.stdin)

assert data["status"] == "success"

result = data["data"]["result"]

assert result, "Sin metricas de estado"

for item in result:
    name = item["metric"].get("name", "unknown")
    age = time.time() - float(item["value"][1])

    state = (
        "ACTIVO"
        if age < 45
        else "SIN METRICAS RECIENTES"
    )

    print(f"{name:35} {state}")
'

echo
echo "Mostrar State Timeline en Grafana."

# ============================================================
# 13. LOGS
# ============================================================

paso 13 "LOGS CENTRALIZADOS"

ejecutar test-logs

echo
echo "Abrir Grafana Explore y seleccionar Loki."

echo
echo "Consulta LogQL:"

echo '{container=~"practica2-(dev|prod)-nginx"}'

echo
echo "Mostrar los registros DEV y PROD."

# ============================================================
# 14. ALTA DISPONIBILIDAD Y ALERTAS
# ============================================================

paso 14 "ALTA DISPONIBILIDAD Y ALERTAS PROD"

echo "Mostrar las cinco alertas en Grafana."
echo
echo "Grafana: http://localhost:8500"
echo "Mailpit: http://localhost:8025"

read -r -p "Pulsa ENTER para iniciar la prueba..." dummy

ejecutar alert-flask-prod

echo
echo "Mostrar la alerta y el correo recibido."
echo "Comprobar la recuperacion de la replica."

# ============================================================
# 15. DASHBOARDS
# ============================================================

paso 15 "DASHBOARDS Y PERSISTENCIA DE GRAFANA"

python3 - <<'PY'
import json
from pathlib import Path

root = Path("environments/monitoring/grafana")

files = sorted((root / "dashboards").glob("*.json"))

assert len(files) >= 4, "Faltan dashboards"

for file in files:
    data = json.loads(file.read_text())
    print("[OK]", data["dashboard"]["title"])

print("\nDashboards exportados:", len(files))

rules = json.loads(
    (root / "alert-rules.json").read_text()
)

assert len(rules) >= 5, "Faltan alertas"

print("Alertas exportadas:", len(rules))

PY

echo
echo "Mostrar los dashboards de Grafana."
echo "Mostrar la evidencia de restauracion del simulacro."
echo "No se elimina el volumen actual."

# ============================================================
# 16. COMPROBACION FINAL
# ============================================================

paso 16 "RECUPERACION Y COMPROBACION FINAL"

ejecutar check-full

ejecutar balance-prod

ejecutar test-monitoring

ejecutar status

cantidad=$(docker ps \
    --filter "name=practica2-" \
    --format '{{.Names}}' | wc -l)

test "$cantidad" -eq 18

echo
echo "============================================================"
echo "             DEMOSTRACION FINALIZADA"
echo "============================================================"
echo
echo "Contenedores activos: $cantidad/18"
echo "DEV y PROD operativos."
echo "Balanceo comprobado."
echo "Persistencia y cache comprobadas."
echo "Almacenamiento compartido comprobado."
echo "Monitorizacion y logs comprobados."
echo "Prueba de alertas ejecutada."
echo "============================================================"

