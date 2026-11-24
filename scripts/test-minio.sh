#!/usr/bin/env bash

# Comprobar almacenamiento compartido en las cinco replicas.
set -euo pipefail

reference="$(
    curl -fsS --max-time 10 \
        http://127.0.0.1:8800/practica2-static/prueba.txt \
        | sha256sum | awk '{print $1}'
)"

echo "=========================================="
echo " ALMACENAMIENTO COMPARTIDO MINIO"
echo "=========================================="
echo
echo "Hash original: $reference"

for container in \
    practica2-dev-flask-1 \
    practica2-dev-flask-2 \
    practica2-prod-flask-1 \
    practica2-prod-flask-2 \
    practica2-prod-flask-3
do

    echo
    echo "===== $container ====="

    docker exec "$container" python -c '
import urllib.request
import hashlib
import sys

expected = sys.argv[1]
instance = sys.argv[2]

url = "http://127.0.0.1:5000/storage/prueba.txt"

with urllib.request.urlopen(url, timeout=5) as response:

    digest = hashlib.sha256(response.read()).hexdigest()

    assert response.status == 200
    assert response.headers["X-Storage"] == "MinIO"
    assert response.headers["X-Instance"] == instance
    assert digest == expected

    print("HTTP:", response.status)
    print("Instancia:", instance)
    print("Almacenamiento:", response.headers["X-Storage"])
    print("SHA256:", digest)
    print("[OK] Archivo identico")

' "$reference" "${container#practica2-}"

done

echo
echo "[OK] Las cinco replicas comparten el mismo archivo."
