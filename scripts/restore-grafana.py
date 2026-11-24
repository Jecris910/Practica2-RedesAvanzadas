#!/usr/bin/env python3

# PRACTICA 2 - Restauracion de Grafana.
# Recupera la configuracion sin duplicar recursos existentes.

import base64
import getpass
import json
import sys
import urllib.request

from pathlib import Path
from urllib.error import HTTPError

BASE = "http://127.0.0.1:8500"

ROOT = (
    Path(__file__).resolve().parent.parent
    / "environments/monitoring/grafana"
)

# Comprobar que la exportacion esta completa.
required = [
    "datasources.json",
    "folders.json",
    "alert-rules.json",
    "contact-points.json",
    "notification-policies.json"
]

for name in required:
    if not (ROOT / name).is_file():
        raise SystemExit(f"ERROR: Falta {name}")

if not list((ROOT / "dashboards").glob("*.json")):
    raise SystemExit("ERROR: No hay dashboards exportados")

# Solicitar credenciales sin almacenarlas.
usuario = input("Usuario Grafana [admin]: ").strip() or "admin"
password = getpass.getpass("Contrasena Grafana: ")

auth = base64.b64encode(
    f"{usuario}:{password}".encode()
).decode()


# Comunicacion con la API de Grafana.
def api(path, method="GET", data=None):

    request = urllib.request.Request(
        BASE + path,
        data=None if data is None else json.dumps(data).encode(),
        method=method,
        headers={
            "Authorization": f"Basic {auth}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Disable-Provenance": "true"
        }
    )

    with urllib.request.urlopen(request, timeout=20) as response:

        body = response.read()

        return json.loads(body) if body else {}


def cargar(nombre):
    return json.loads((ROOT / nombre).read_text())


def existe(path):

    try:
        api(path)
        return True

    except HTTPError as error:

        if error.code == 404:
            return False

        raise


# ==================================================
# 1. FUENTES DE DATOS
# ==================================================

print("\n===== FUENTES DE DATOS =====")

for source in cargar("datasources.json"):

    if not existe("/api/datasources/uid/" + source["uid"]):

        api("/api/datasources", "POST", source)
        print("[CREADO]", source["name"])

    else:
        print("[EXISTE]", source["name"])


# ==================================================
# 2. CARPETAS
# ==================================================

print("\n===== CARPETAS =====")

for folder in cargar("folders.json"):

    if not existe("/api/folders/" + folder["uid"]):

        api("/api/folders", "POST", folder)
        print("[CREADO]", folder["title"])

    else:
        print("[EXISTE]", folder["title"])


# ==================================================
# 3. DASHBOARDS
# ==================================================

print("\n===== DASHBOARDS =====")

for archivo in sorted((ROOT / "dashboards").glob("*.json")):

    payload = json.loads(archivo.read_text())
    dashboard = payload["dashboard"]

    if not existe("/api/dashboards/uid/" + dashboard["uid"]):

        api("/api/dashboards/db", "POST", payload)
        print("[CREADO]", dashboard["title"])

    else:
        print("[EXISTE]", dashboard["title"])


# ==================================================
# 4. CONTACTOS
# ==================================================

print("\n===== CONTACTOS =====")

contacts = api("/api/v1/provisioning/contact-points")

uids = {contact["uid"] for contact in contacts}

for contact in cargar("contact-points.json"):

    if contact["uid"] not in uids:

        api(
            "/api/v1/provisioning/contact-points",
            "POST",
            contact
        )

        print("[CREADO]", contact["name"])

    else:
        print("[EXISTE]", contact["name"])


# ==================================================
# 5. ALERTAS
# ==================================================

print("\n===== ALERTAS =====")

for rule in cargar("alert-rules.json"):

    path = "/api/v1/provisioning/alert-rules"

    if not existe(path + "/" + rule["uid"]):

        api(path, "POST", rule)
        print("[CREADO]", rule["title"])

    else:
        print("[EXISTE]", rule["title"])


# ==================================================
# 6. POLITICAS DE NOTIFICACION
# ==================================================

print("\n===== POLITICAS =====")

# Solo sustituir politicas cuando se solicita expresamente.
if "--policies" in sys.argv:

    api(
        "/api/v1/provisioning/policies",
        "PUT",
        cargar("notification-policies.json")
    )

    print("[OK] Politicas restauradas.")

else:
    print("[OK] Se conservan las politicas actuales.")


print()
print("==========================================")
print(" RESTAURACION DE GRAFANA COMPLETADA")
print("==========================================")
