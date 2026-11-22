
# MODULO WEB
# Crea multiples instancias Flask mediante count.

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

# Imagen propia de Flask con la aplicacion Inazuma Eleven.
resource "docker_image" "flask" {
  name         = "practica2-${var.environment}-flask:1"
  keep_locally = true

  build {
    context = var.build_context
  }
}

# Instancias independientes de la misma aplicacion.
resource "docker_container" "flask" {
  count = var.replicas

  name  = "practica2-${var.environment}-flask-${count.index + 1}"
  image = docker_image.flask.image_id

  restart = "unless-stopped"

  # Configuracion de acceso a MySQL y Redis.
  env = [
    "MYSQL_HOST=${var.mysql_host}",
    "MYSQL_PORT=3306",
    "MYSQL_USER=inazuma",
    "MYSQL_PASSWORD=${var.mysql_password}",
    "MYSQL_DATABASE=practica2",
    "REDIS_HOST=${var.redis_host}",
    "REDIS_PORT=6379",
    "APP_ENV=${var.environment}",
    "INSTANCE_ID=${var.environment}-flask-${count.index + 1}"
  ]

  networks_advanced {
    name = var.network_name
  }
}
