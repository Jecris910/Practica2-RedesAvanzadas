# ENTORNO DE PRODUCCION
# Reutilizamos el mismo modulo de red que DEV,
# pero asignamos un nombre diferente.

module "network" {
  source = "../../modules/network"

  network_name = "practica2-prod-network"
}