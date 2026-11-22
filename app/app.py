
# PRACTICA 2 - APLICACION INAZUMA ELEVEN
# Flask conectado a MySQL y Redis.
# La infraestructura se despliega mediante Terraform.

from flask import Flask, jsonify, render_template
import json
import time
import os
import pymysql
import redis

app = Flask(__name__)


# Conecta con la base de datos del entorno correspondiente.
def get_database_connection():
    return pymysql.connect(
        host=os.getenv("MYSQL_HOST"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER"),
        password=os.getenv("MYSQL_PASSWORD"),
        database=os.getenv("MYSQL_DATABASE"),
        connect_timeout=2,
        cursorclass=pymysql.cursors.DictCursor
    )


# Redis almacena temporalmente las consultas a equipos.
def get_cache_connection():
    redis_host = os.getenv("REDIS_HOST")

    if not redis_host:
        return None

    return redis.Redis(
        host=redis_host,
        port=int(os.getenv("REDIS_PORT", "6379")),
        socket_connect_timeout=2,
        socket_timeout=2,
        decode_responses=True
    )


# Comprueba si MySQL responde.
def check_database():
    try:
        connection = get_database_connection()
        connection.ping(reconnect=False)
        connection.close()
        return "connected"
    except Exception:
        return "disconnected"


# Comprueba si Redis responde.
def check_cache():
    try:
        cache = get_cache_connection()

        if cache is None:
            return "not configured"

        cache.ping()
        return "connected"
    except Exception:
        return "disconnected"


# Pagina principal con el identificador real de la instancia.
@app.route("/")
def home():
    return render_template(
        "index.html",
        environment=os.getenv("APP_ENV", "unknown"),
        instance_id=os.getenv("INSTANCE_ID", "unknown")
    )


# Estado de la aplicacion y de sus servicios.
# Incluye la instancia que ha atendido la peticion.
@app.route("/status")
def status():
    return jsonify({
        "web": "connected",
        "database": check_database(),
        "cache": check_cache(),
        "environment": os.getenv("APP_ENV", "unknown"),
        "instance": os.getenv("INSTANCE_ID", "unknown")
    })


# Devuelve todos los jugadores y sus equipos.
@app.route("/players")
def players():
    try:
        connection = get_database_connection()

        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    p.id,
                    p.name,
                    p.position,
                    p.element,
                    p.best_move_1,
                    p.best_move_2,
                    p.image_path,
                    t.name AS team
                FROM players p
                JOIN teams t ON p.team_id = t.id
                ORDER BY t.id, p.id
            """)

            players_data = cursor.fetchall()

        connection.close()

        return jsonify({
            "players": players_data
        })

    except Exception:
        return jsonify({
            "error": "database unavailable"
        }), 503


# Devuelve equipos, utilizando Redis como cache.
@app.route("/teams")
def teams():
    start_time = time.perf_counter()
    cache = None

    # Primero intentamos leer desde Redis.
    try:
        cache = get_cache_connection()

        if cache is not None:
            cached_teams = cache.get("teams")

            if cached_teams:
                load_time_ms = round(
                    (time.perf_counter() - start_time) * 1000,
                    2
                )

                return jsonify({
                    "source": "cache",
                    "cache": "HIT",
                    "load_time_ms": load_time_ms,
                    "teams": json.loads(cached_teams)
                })

    except Exception:
        cache = None

    # Si no hay cache, consultamos MySQL.
    try:
        connection = get_database_connection()

        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT id, name, category, school_or_country
                FROM teams
            """)

            teams_data = cursor.fetchall()

        connection.close()

        # Guardamos los equipos 60 segundos en Redis.
        if cache is not None:
            try:
                cache.setex(
                    "teams",
                    60,
                    json.dumps(teams_data)
                )
            except Exception:
                pass

        load_time_ms = round(
            (time.perf_counter() - start_time) * 1000,
            2
        )

        return jsonify({
            "source": "database",
            "cache": "MISS",
            "load_time_ms": load_time_ms,
            "teams": teams_data
        })

    except Exception:
        return jsonify({
            "error": "database unavailable"
        }), 503


if __name__ == "__main__":
    # El puerto 5000 es interno al contenedor.
    app.run(host="0.0.0.0", port=5000, threaded=True)
