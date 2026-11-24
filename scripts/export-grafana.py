#!/usr/bin/env python3

# PRACTICA 2 - Exportacion de la configuracion de Grafana.
# Las credenciales se solicitan sin guardarlas en el proyecto.

import base64
import getpass
import json
import urllib.request
from pathlib import Path

BASE = "http://127.0.0.1:8500"

ROOT = (
    Path(__file__).resolve().parent.parent
    / "environments/monitoring/grafana"
)

usuario = input("Usuario Grafana [admin]: ").strip() or "admin"
password = getpass.getpass("Contrasena Grafana: ")

auth = base64.b64encode(
    f"{usuario}:{password}".encode()
).decode()


# Consultar la API de Grafana.
def api(path):
    request = urllib.request.Request(
        BASE + path,
        headers={
            "Authorization": f"Basic {auth}",
            "Accept": "application/json"
        }
    )

    with urllib.request.urlopen(request, timeout=20) as response:
        return json.load(response)


# Guardar configuracion en formato JSON.
def guardar(nombre, contenido):
    archivo = ROOT / nombre

    archivo.parent.mkdir(parents=True, exist_ok=True)

    archivo.write_text(
        json.dumps(
            contenido,
            indent=2,
            ensure_ascii=False
        ) + "\n"
    )

    print("[OK]", nombre)


# ==================================================
# 1. FUENTES DE DATOS
# ==================================================

sources = []

for source in api("/api/datasources"):

    if source["type"] not in ("prometheus", "loki"):
        continue

    sources.append({
        "name": source["name"],
        "uid": source["uid"],
        "type": source["type"],
        "access": "proxy",
        "url": (
            "http://127.0.0.1:8400"
            if source["type"] == "prometheus"
            else "http://127.0.0.1:8600"
        ),
        "isDefault": source.get("isDefault", False),
        "editable": True
    })

assert {s["type"] for s in sources} == {
    "prometheus", "loki"
}

guardar("datasources.json", sources)

# ==================================================
# 2. CARPETAS
# ==================================================

folders = api("/api/search?type=dash-folder")

guardar("folders.json", [
    {
        "uid": folder["uid"],
        "title": folder["title"]
    }
    for folder in folders
])

# ==================================================
# 3. DASHBOARDS
# ==================================================

dashboards = api("/api/search?type=dash-db")

assert dashboards, "No se encontraron dashboards"

for item in dashboards:

    result = api(
        "/api/dashboards/uid/" + item["uid"]
    )

    dashboard = result["dashboard"]

    dashboard.pop("id", None)
    dashboard["version"] = 0

    guardar(
        "dashboards/" + item["uid"] + ".json",
        {
            "dashboard": dashboard,
            "folderUid": result["meta"].get(
                "folderUid", ""
            ),
            "overwrite": False
        }
    )

# ==================================================
# 4. REGLAS DE ALERTAS
# ==================================================

rules = api("/api/v1/provisioning/alert-rules")

assert len(rules) >= 5, "Faltan reglas de alertas"

for rule in rules:
    for key in ("id", "updated", "provenance"):
        rule.pop(key, None)

guardar("alert-rules.json", rules)

# ==================================================
# 5. CONTACTO MAILPIT
# ==================================================

contacts = []

for contact in api(
    "/api/v1/provisioning/contact-points"
):

    if contact.get("type") != "email":
        continue

    nombre = contact.get("name", "")
    direcciones = contact.get("settings", {}).get("addresses", "")

    print("Contacto encontrado:", nombre)

    if (
        nombre.strip().casefold() != "practica2 avisos"
        and "profesor@practica2.local" not in str(direcciones).lower()
    ):
        continue

    contacts.append({
        "uid": contact["uid"],
        "name": contact["name"],
        "type": "email",
        "settings": {
            "addresses": "profesor@practica2.local",
            "singleEmail": True
        },
        "disableResolveMessage": False
    })

assert contacts, "No se encontro el contacto de Mailpit"

guardar("contact-points.json", contacts)

# ==================================================
# 6. POLITICAS DE NOTIFICACION
# ==================================================

guardar(
    "notification-policies.json",
    api("/api/v1/provisioning/policies")
)

# ==================================================
# RESULTADOS
# ==================================================

print()
print("========================================")
print(" EXPORTACION DE GRAFANA COMPLETADA")
print("========================================")
print("Fuentes de datos:", len(sources))
print("Carpetas:", len(folders))
print("Dashboards:", len(dashboards))
print("Alertas:", len(rules))
print("Contactos:", len(contacts))
print("========================================")
