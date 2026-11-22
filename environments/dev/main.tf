# ENTORNO DE DESARROLLO
# Utilizamos el modulo compartido para crear
# una red Docker independiente para DEV.

module "network" {
  source = "../../modules/network"

  network_name = "practica2-dev-network"
}