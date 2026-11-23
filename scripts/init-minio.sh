#!/usr/bin/env bash

# Inicializacion reproducible del almacenamiento compartido.
set -euo pipefail

cd "$(dirname "$0")/.."

export AWS_ACCESS_KEY_ID="practica2admin"

export AWS_SECRET_ACCESS_KEY="$(
    terraform -chdir=environments/monitoring \
    output -raw minio_password
)"

trap 'unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY' EXIT

docker run --rm -i \
    --network host \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    python:3.11-slim \
    sh -c 'pip install --quiet --disable-pip-version-check boto3 && python -' <<'PY'

import boto3
import json

from botocore.config import Config
from botocore.exceptions import ClientError

bucket = "practica2-static"

s3 = boto3.client(
    "s3",
    endpoint_url="http://127.0.0.1:8800",
    region_name="us-east-1",
    config=Config(s3={"addressing_style": "path"})
)

# Crear el bucket si no existe.
try:
    s3.head_bucket(Bucket=bucket)
except ClientError as error:
    if error.response["Error"]["Code"] in ("404", "NoSuchBucket"):
        s3.create_bucket(Bucket=bucket)
    else:
        raise

# Crear el archivo solamente si todavia no existe.
try:
    s3.head_object(Bucket=bucket, Key="prueba.txt")
except ClientError as error:
    if error.response["Error"]["Code"] in ("404", "NoSuchKey"):
        s3.put_object(
            Bucket=bucket,
            Key="prueba.txt",
            Body=b"PRACTICA 2 - Almacenamiento compartido MinIO\n",
            ContentType="text/plain"
        )
    else:
        raise

# Permitir solamente la lectura del archivo estatico.
policy = {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": ["s3:GetObject"],
            "Resource": [
                "arn:aws:s3:::practica2-static/prueba.txt"
            ]
        }
    ]
}

s3.put_bucket_policy(
    Bucket=bucket,
    Policy=json.dumps(policy)
)

print("[OK] Bucket configurado.")
print("[OK] Archivo estatico disponible.")
print("[OK] Politica de lectura configurada.")
PY

echo "Inicializacion MinIO completada."
