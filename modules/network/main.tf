
# MODULO NETWORK
# Crea una red Docker independiente para cada entorno.
#
# Declaramos el proveedor dentro del modulo para que
# Terraform identifique correctamente su origen.

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.6.0"
    }
  }
}

# Crea una red de tipo bridge para conectar
# los futuros contenedores del mismo entorno.
resource "docker_network" "network" {
  name   = var.network_name
  driver = "bridge"
}
