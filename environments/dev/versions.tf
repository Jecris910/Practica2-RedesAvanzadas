
# Version de Terraform y proveedores necesarios.
# Utilizamos versiones concretas para reproducibilidad.

terraform {
  required_version = ">= 1.17.0"

  required_providers {

    # Proveedor Docker para redes, imagenes y contenedores.
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }

    # Generacion automatica de credenciales.
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
  }
}

# Conexion a Docker instalado en Ubuntu.
provider "docker" {}
