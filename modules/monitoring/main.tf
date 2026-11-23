
# ============================================================
# MODULO MONITORING
# Monitorizacion de contenedores Docker.
# ============================================================

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

# ============================================================
# CADVISOR
# Recoge metricas de CPU, RAM y red de Docker.
# ============================================================

resource "docker_image" "cadvisor" {
  name         = "ghcr.io/google/cadvisor:0.55.1"
  keep_locally = true
}

resource "docker_container" "cadvisor" {
  name       = "practica2-cadvisor"
  image      = docker_image.cadvisor.image_id
  restart    = "unless-stopped"
  privileged = true

  ports {
    internal = 8080
    external = 8300
    ip       = "127.0.0.1"
  }

  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }

  volumes {
    host_path      = "/var/run"
    container_path = "/var/run"
    read_only      = true
  }

  volumes {
    host_path      = "/sys"
    container_path = "/sys"
    read_only      = true
  }

  volumes {
    host_path      = "/var/lib/docker"
    container_path = "/var/lib/docker"
    read_only      = true
  }
}
