#!/usr/bin/env bash

# ============================================================
# PRACTICA 2 - REDES AVANZADAS
# DEMOSTRACION INTERACTIVA
# ============================================================

set -euo pipefail

cd "$(dirname "$0")/.."

TOTAL=16

paso() {
    echo
    echo "============================================================"
    echo " [$1/$TOTAL] $2"
    echo "============================================================"
    echo

    read -r -p "Pulsa ENTER para comenzar este apartado..." dummy
    echo
}

clear

echo "============================================================"
echo "           PRACTICA 2 - REDES AVANZADAS"
echo "            INFRAESTRUCTURA COMO CODIGO"
echo "============================================================"
echo
echo "Terraform y Docker"
echo "Flask, MySQL, Redis y Nginx"
echo "Prometheus, cAdvisor y Grafana"
echo "Loki, Alloy, Mailpit y MinIO"
echo "============================================================"

# ============================================================
# 1. ARQUITECTURA
# ============================================================

paso 1 "ARQUITECTURA DEL PROYECTO"

cat <<'DIAGRAMA'

                       USUARIO
                          |
           +--------------+--------------+
           |                             |
       NGINX DEV                    NGINX PROD
         :8100                         :8200
           |                             |
      ROUND ROBIN                   ROUND ROBIN
           |                             |
     +-----+-----+              +--------+--------+
     |           |              |        |        |
   Flask 1    Flask 2         Flask 1  Flask 2  Flask 3
     |           |              |        |        |
     +-----+-----+              +--------+--------+
           |                             |
     MySQL + Redis                 MySQL + Redis
           |                             |
      Volumen DEV                   Volumen PROD

           ALMACENAMIENTO COMPARTIDO
                     MinIO

           PLATAFORMA DE MONITORIZACION

      cAdvisor -> Prometheus -> Grafana
                                    |
                                 Mailpit

      Docker -> Alloy -> Loki -> Grafana

DIAGRAMA

echo "DEV y PROD tienen redes y bases de datos independientes."
echo "MinIO proporciona almacenamiento compartido."
echo "Toda la infraestructura se gestiona mediante Terraform."

# ============================================================
# 2. TERRAFORM
# ============================================================

paso 2 "INFRAESTRUCTURA COMO CODIGO"

echo "Version de Terraform:"
terraform version

echo
echo "Modulos reutilizables:"
find modules -maxdepth 1 -mindepth 1 -type d | sort

echo
echo "Entornos independientes:"
find environments -maxdepth 1 -mindepth 1 -type d | sort

echo
echo "Validacion de Terraform:"

make --no-print-directory validate-all
make --no-print-directory validate-monitoring

# ============================================================
# 3. CONTENEDORES
# ============================================================

paso 3 "CONTENEDORES DESPLEGADOS"

make --no-print-directory status

echo
echo "Contenedores en ejecucion:"

docker ps \
    --filter "name=practica2" \
    --format '{{.Names}}' | wc -l

echo
echo "Redes Docker:"

docker network ls --filter "name=practica2"

# ============================================================
# 4. APLICACIONES
# ============================================================

paso 4 "FUNCIONAMIENTO SIMULTANEO DEV Y PROD"

make --no-print-directory check

echo
echo "Aplicacion DEV:  http://localhost:8100"
echo "Aplicacion PROD: http://localhost:8200"

echo
echo "Mostrar en el navegador ambas aplicaciones."
echo "Comprobar los identificadores de instancia."

# ============================================================
# 5. BALANCEO DEV
# ============================================================

paso 5 "BALANCEO ROUND ROBIN DEV"

echo "Dos replicas distribuyen las peticiones."

make --no-print-directory balance-dev

# ============================================================
# 6. BALANCEO PROD
# ============================================================

paso 6 "BALANCEO ROUND ROBIN PROD"

echo "Tres replicas distribuyen las peticiones."

make --no-print-directory balance-prod

make --no-print-directory nginx-test

# ============================================================
# 7. CACHE
# ============================================================

paso 7 "CACHE REDIS"

echo "Primera consulta: MySQL - CACHE MISS."
echo "Segunda consulta: Redis - CACHE HIT."

make --no-print-directory test-cache

# ============================================================
# 8. PERSISTENCIA
# ============================================================

paso 8 "PERSISTENCIA DE DATOS MYSQL"

echo "Esta prueba reinicia MySQL en cada entorno."
echo "Se comparan los datos antes y despues del reinicio."

make --no-print-directory test-persistencia

# ============================================================
# 9. ALMACENAMIENTO
# ============================================================

paso 9 "ALMACENAMIENTO COMPARTIDO MINIO"

echo "Las cinco replicas consumen el mismo objeto."

make --no-print-directory test-minio

echo
echo "Consola MinIO: http://localhost:8801"

# ============================================================
# 10. MONITORIZACION
# ============================================================

paso 10 "PLATAFORMA DE MONITORIZACION"

make --no-print-directory test-monitoring

echo
echo "Prometheus: http://localhost:8400"
echo "Grafana:    http://localhost:8500"

# ============================================================
# 11. CPU
# ============================================================

paso 11 "MONITORIZACION DE CPU"

echo "Consulta PromQL:"

query='100 * sum by(name) (rate(container_cpu_usage_seconds_total{name=~"practica2-(dev|prod)-.*"}[1m]))'

echo "$query"

curl -fsS -G \
    http://127.0.0.1:8400/api/v1/query \
    --data-urlencode "query=$query" | \
python3 -c '
import json
import sys

data = json.load(sys.stdin)

assert data["data"]["result"], "Sin metricas CPU"

for item in data["data"]["result"]:
    name = item["metric"].get("name", "unknown")
    value = float(item["value"][1])
    print(f"{name:35} {value:.2f} %")
'

echo
echo "Mostrar el panel CPU de Grafana."

# ============================================================
# 12. RAM
# ============================================================

paso 12 "MONITORIZACION DE MEMORIA RAM"

query='container_memory_usage_bytes{name=~"practica2-(dev|prod)-.*"} / 1024 / 1024'

echo "Consulta PromQL:"
echo "$query"

curl -fsS -G \
    http://127.0.0.1:8400/api/v1/query \
    --data-urlencode "query=$query" | \
python3 -c '
import json
import sys

data = json.load(sys.stdin)

assert data["data"]["result"], "Sin metricas RAM"

for item in data["data"]["result"]:
    name = item["metric"].get("name", "unknown")
    value = float(item["value"][1])
    print(f"{name:35} {value:.2f} MiB")
'

echo
echo "Mostrar el panel RAM de Grafana."

# ============================================================
# 13. ESTADO
# ============================================================

paso 13 "ESTADO DE LOS CONTENEDORES"

query='max by(name) (container_last_seen{name=~"practica2-(dev|prod)-.*"})'

curl -fsS -G \
    http://127.0.0.1:8400/api/v1/query \
    --data-urlencode "query=$query" | \
python3 -c '
import json
import sys
import time

data = json.load(sys.stdin)

assert data["data"]["result"], "Sin metricas de estado"

for item in data["data"]["result"]:
    name = item["metric"].get("name", "unknown")
    age = time.time() - float(item["value"][1])
    state = "ACTIVO" if age < 45 else "SIN METRICAS RECIENTES"
    print(f"{name:35} {state}")
'

echo
echo "Mostrar el State Timeline de Grafana."

# ============================================================
# 14. LOGS
# ============================================================

paso 14 "LOGS CENTRALIZADOS CON LOKI Y ALLOY"

make --no-print-directory test-logs

echo
echo "Abrir Grafana Explore."
echo "Seleccionar Loki como fuente de datos."
echo
echo "Consulta LogQL general:"

echo '{container=~"practica2-(dev|prod)-.*"}'

# ============================================================
# 15. ALTA DISPONIBILIDAD Y ALERTAS
# ============================================================

paso 15 "ALTA DISPONIBILIDAD Y ALERTAS PROD"

echo "Se detendra temporalmente una replica Flask."
echo "Las otras dos replicas continuaran atendiendo peticiones."
echo "Se comprobara la alerta y la notificacion por correo."
echo
echo "Grafana: http://localhost:8500"
echo "Mailpit: http://localhost:8025"

make --no-print-directory alert-flask-prod

# ============================================================
# 16. RECUPERACION
# ============================================================

paso 16 "RECUPERACION Y COMPROBACION FINAL"

make --no-print-directory check-full

make --no-print-directory balance-prod

make --no-print-directory test-minio

make --no-print-directory status

echo
echo "============================================================"
echo " DEMOSTRACION FINALIZADA CORRECTAMENTE"
echo "============================================================"
echo
echo "Infraestructura desplegada mediante Terraform."
echo "Entornos DEV y PROD operativos."
echo "Balanceo de carga comprobado."
echo "Cache y persistencia comprobadas."
echo "Almacenamiento compartido comprobado."
echo "Monitorizacion y logs centralizados comprobados."
echo "Prueba de alta disponibilidad ejecutada."
echo "============================================================"
