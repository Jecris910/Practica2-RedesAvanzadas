
# PRACTICA 2 - ENTORNO DE PRODUCCION
# Recursos independientes de DEV y de la Practica 1.

# Red interna de produccion.
module "network" {
  source = "../../modules/network"

  network_name = "practica2-prod-network"
}

# Base de datos MySQL de produccion.
module "database" {
  source = "../../modules/database"

  environment   = var.environment
  network_name  = module.network.network_name
  build_context = abspath("${path.root}/../../db")
}

# Cache Redis de produccion.
module "cache" {
  source = "../../modules/cache"

  environment  = var.environment
  network_name = module.network.network_name
}

# Tres instancias Flask independientes.
module "web" {
  source = "../../modules/web"

  environment   = var.environment
  network_name  = module.network.network_name
  build_context = abspath("${path.root}/../../app")
  replicas      = var.web_replicas
  base_port     = 5201

  mysql_host     = module.database.container_name
  mysql_password = module.database.app_password
  redis_host     = module.cache.container_name
}
