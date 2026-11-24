#!/usr/bin/env bash

# PRACTICA 2 - Persistencia de datos mediante Terraform.
# Recrea MySQL conservando su volumen persistente.

set -euo pipefail

cd "$(dirname "$0")/.."

# Los planes pueden contener informacion sensible.
umask 077
tmp=$(mktemp -d)

cleanup() {
    rm -rf -- "$tmp"
}

trap cleanup EXIT


pausa_demo() {
    if [[ "${DEMO_INTERACTIVA:-0}" == "1" ]]; then
        echo
        read -r -p "$1" dummy
    fi
}

# Ejecutar SQL sin mostrar las credenciales.
sql() {

    docker exec -i "$container" /bin/sh -c '
        MYSQL_PWD="$MYSQL_ROOT_PASSWORD" \
        mysql -h 127.0.0.1 -uroot \
            -N -B "$MYSQL_DATABASE"
    '

}

# Obtener el hash de los jugadores de la aplicacion.
obtener_hash() {

    curl -fsS --max-time 10 \
        "http://localhost:$port/players" |
    python3 -c '
import hashlib
import json
import sys

players = json.load(sys.stdin)["players"]

assert players, "No hay jugadores"

content = json.dumps(
    players,
    sort_keys=True,
    ensure_ascii=False
).encode()

print(hashlib.sha256(content).hexdigest())
'

}

# Comprobar que el jugador aparece en la aplicacion.
comprobar_jugador() {

    curl -fsS --max-time 10 \
        "http://localhost:$port/players" |
    python3 -c '
import json
import sys

players = json.load(sys.stdin)["players"]

assert any(
    p["name"] == sys.argv[1]
    for p in players
), "Jugador de prueba no encontrado"
' "$marker"

}

# Comprobar el volumen utilizado por MySQL.
obtener_volumen() {

    docker inspect \
        --format '{{range .Mounts}}{{if eq .Destination "/var/lib/mysql"}}{{.Name}}{{end}}{{end}}' \
        "$container"

}

# Permitir comprobar un entorno o ambos.
case "${1:-all}" in
    dev) environments=(dev) ;;
    prod) environments=(prod) ;;
    all) environments=(dev prod) ;;
    *)
        echo "Uso: $0 [dev|prod|all]"
        exit 1
        ;;
esac

for env in "${environments[@]}"; do

    if [ "$env" = "dev" ]; then
        port=8100
    else
        port=8200
    fi

    container="practica2-$env-mysql"
    directory="environments/$env"

    marker="persistencia-${env}-$(date +%s%N)"
    plan="$tmp/$env.tfplan"

    echo
    echo "=========================================="
    echo " PERSISTENCIA MYSQL ${env^^}"
    echo "=========================================="

    # Guardar el estado inicial.
    original=$(obtener_hash)

    id_antes=$(docker inspect \
        --format '{{.Id}}' "$container")

    volumen_antes=$(obtener_volumen)

    test "$volumen_antes" = "practica2-$env-mysql-data"

    echo "Hash original: $original"
    echo "Contenedor original: ${id_antes:0:12}"
    echo "Volumen: $volumen_antes"

    # Preparar la sustitucion exclusiva de MySQL.
    echo
    echo "===== PLAN TERRAFORM ====="

    terraform -chdir="$directory" plan \
        -replace=module.database.docker_container.mysql \
        -out="$plan"

    # Impedir modificaciones adicionales.
    terraform -chdir="$directory" show -json "$plan" |
    python3 -c '
import json
import sys

data = json.load(sys.stdin)

changes = {
    resource["address"]: resource["change"]["actions"]
    for resource in data.get("resource_changes", [])
    if resource["change"]["actions"] not in (
        ["no-op"], ["read"]
    )
}

expected = "module.database.docker_container.mysql"

assert set(changes) == {expected}, \
    "El plan contiene cambios adicionales"

assert sorted(changes[expected]) == ["create", "delete"], \
    "El plan no corresponde a una recreacion"

print("[OK] Solo se reemplazara el contenedor MySQL.")
print("[OK] Volumen y contrasenas conservados.")
'

    echo
    read -r -p "Recrear MySQL ${env^^}? [s/N]: " confirm

    if [[ "$confirm" != "s" ]]; then
        echo "Prueba cancelada."
        exit 1
    fi

    # Insertar un jugador temporal.
    echo
    echo "===== INSERTAR DATO DE PRUEBA ====="

    sql <<SQL
INSERT INTO players (
    name, position, element,
    best_move_1, best_move_2, team_id
)
SELECT
    '$marker', 'Forward', 'Fire',
    'Prueba', 'Prueba', id
FROM teams
ORDER BY id
LIMIT 1;
SQL

    comprobar_jugador

    hash_antes=$(obtener_hash)

    echo "Jugador: $marker"
    echo "Hash antes: $hash_antes"
    echo "[OK] Jugador insertado y visible en Flask."
    pausa_demo "Mostrar jugador insertado y pulsar ENTER..."

    # Recrear exclusivamente el contenedor.
    echo
    echo "===== RECREAR MYSQL ====="

    terraform -chdir="$directory" apply "$plan"

    # Esperar a que la aplicacion recupere la conexion.
    echo
    echo "===== ESPERAR RECUPERACION ====="

    ready=0

    for i in $(seq 1 60); do

        if comprobar_jugador >/dev/null 2>&1; then
            ready=1
            break
        fi

        sleep 2

    done

    if [ "$ready" -ne 1 ]; then
        echo "ERROR: No se ha recuperado el jugador."
        echo "Identificador de prueba: $marker"
        exit 1
    fi

    # Verificar que el contenedor ha cambiado.
    id_despues=$(docker inspect \
        --format '{{.Id}}' "$container")

    volumen_despues=$(obtener_volumen)

    test "$id_antes" != "$id_despues"
    test "$volumen_antes" = "$volumen_despues"

    echo "Contenedor anterior: ${id_antes:0:12}"
    echo "Contenedor nuevo:    ${id_despues:0:12}"
    echo "Volumen conservado:  $volumen_despues"

    echo "[OK] Contenedor recreado."
    echo "[OK] Mismo volumen persistente."

    # Comparar los datos antes y despues.
    hash_despues=$(obtener_hash)

    echo
    echo "Hash antes:   $hash_antes"
    echo "Hash despues: $hash_despues"

    test "$hash_antes" = "$hash_despues"

    comprobar_jugador

    echo "[OK] Los datos permanecen."
    echo "[OK] El jugador de prueba sigue disponible."
    pausa_demo "Mostrar jugador conservado y pulsar ENTER..."

    # Eliminar exclusivamente el jugador temporal.
    echo
    echo "===== LIMPIAR DATOS DE PRUEBA ====="

    sql <<SQL
DELETE FROM players
WHERE name = '$marker';
SQL

    final=$(obtener_hash)

    test "$original" = "$final"

    echo "Hash original: $original"
    echo "Hash final:    $final"

    echo "[OK] Datos originales recuperados."
    pausa_demo "Mostrar jugador eliminado y pulsar ENTER..."
    echo "[OK] Persistencia ${env^^} comprobada."

done

echo
echo "=========================================="
echo " PRUEBA DE PERSISTENCIA COMPLETADA"
echo "=========================================="
