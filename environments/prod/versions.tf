# Version de Terraform y proveedor Docker.
# Fijamos la version del proveedor para reproducir el entorno.
terraform {
  required_version = ">= 1.17.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

# Docker se ejecuta localmente en Ubuntu.
provider "docker" {}