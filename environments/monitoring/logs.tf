# ==========================================================
# LOKI - Almacenamiento y consultas de logs centralizados
# ==========================================================

resource "docker_image" "loki" {
  name         = "grafana/loki:3.7.0"
  keep_locally = true
}

resource "docker_volume" "loki_data" {
  name = "practica2-loki-data"

  lifecycle {
    prevent_destroy = true
  }
}

resource "docker_container" "loki" {
  name         = "practica2-loki"
  image        = docker_image.loki.image_id
  restart      = "unless-stopped"
  network_mode = "host"

  # Solo laboratorio: evitar conflictos de permisos
  # al escribir en el volumen persistente.
  user = "0:0"

  command = [
    "-config.file=/etc/loki/local-config.yaml"
  ]

  volumes {
    host_path      = abspath("${path.module}/loki.yml")
    container_path = "/etc/loki/local-config.yaml"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.loki_data.name
    container_path = "/loki"
  }
}

# ==========================================================
# ALLOY - Recogida automatica de logs de Docker
# ==========================================================

resource "docker_image" "alloy" {
  name         = "grafana/alloy:v1.18.0"
  keep_locally = true
}

resource "docker_volume" "alloy_data" {
  name = "practica2-alloy-data"
}

resource "docker_container" "alloy" {
  name         = "practica2-alloy"
  image        = docker_image.alloy.image_id
  restart      = "unless-stopped"
  network_mode = "host"

  # Acceso necesario al socket Docker en la VM de laboratorio.
  user = "0:0"

  command = [
    "run",
    "--storage.path=/var/lib/alloy/data",
    "--server.http.listen-addr=127.0.0.1:8700",
    "/etc/alloy/config.alloy"
  ]

  volumes {
    host_path      = abspath("${path.module}/config.alloy")
    container_path = "/etc/alloy/config.alloy"
    read_only      = true
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.alloy_data.name
    container_path = "/var/lib/alloy/data"
  }

  depends_on = [
    docker_container.loki
  ]
}
