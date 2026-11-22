
# MODULO DATABASE
# MySQL con credenciales automaticas y datos persistentes.

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
  }
}

# Generamos contrasenas diferentes para root y Flask.
resource "random_password" "root" {
  length  = 24
  special = false
}

resource "random_password" "app" {
  length  = 24
  special = false
}

# Construimos una imagen MySQL con el SQL incluido.
resource "docker_image" "mysql" {
  name         = "practica2-${var.environment}-mysql:1"
  keep_locally = true

  build {
    context = var.build_context
  }
}

# Volumen de datos independiente del contenedor.
resource "docker_volume" "data" {
  name = "practica2-${var.environment}-mysql-data"

  lifecycle {
    prevent_destroy = true
  }
}

# Contenedor MySQL del entorno.
resource "docker_container" "mysql" {
  name    = "practica2-${var.environment}-mysql"
  image   = docker_image.mysql.image_id
  restart = "unless-stopped"

  env = [
    "MYSQL_ROOT_PASSWORD=${random_password.root.result}",
    "MYSQL_DATABASE=practica2",
    "MYSQL_USER=inazuma",
    "MYSQL_PASSWORD=${random_password.app.result}"
  ]

  networks_advanced {
    name = var.network_name
  }

  # El volumen sobrevive a la recreacion del contenedor.
  volumes {
    volume_name    = docker_volume.data.name
    container_path = "/var/lib/mysql"
  }

  # Comprueba que MySQL acepta conexiones autenticadas.
  healthcheck {
    test = [
      "CMD-SHELL",
      "MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\" mysql -h 127.0.0.1 -uroot -e 'SELECT 1' >/dev/null 2>&1"
    ]

    interval     = "30s"
    timeout      = "5s"
    retries      = 5
    start_period = "1m0s"
  }
}
