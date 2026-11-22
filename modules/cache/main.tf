
# MODULO CACHE
# Redis para almacenar temporalmente consultas de Flask.

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

resource "docker_image" "redis" {
  name         = "redis:7.4-alpine"
  keep_locally = true
}

resource "docker_container" "redis" {
  name    = "practica2-${var.environment}-redis"
  image   = docker_image.redis.image_id
  restart = "unless-stopped"

  # Sin puertos publicados: acceso solo por red Docker.
  networks_advanced {
    name = var.network_name
  }

  # Comprueba que Redis responde.
  healthcheck {
    test         = ["CMD", "redis-cli", "ping"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }
}
