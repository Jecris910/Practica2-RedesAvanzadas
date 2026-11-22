
# PRACTICA 2 - ENTORNO DE DESARROLLO
# Infraestructura independiente gestionada con Terraform.

# Red interna de DEV.
module "network" {
  source = "../../modules/network"

  network_name = "practica2-dev-network"
}

# Base de datos MySQL de DEV.
module "database" {
  source = "../../modules/database"

  environment   = var.environment
  network_name  = module.network.network_name
  build_context = abspath("${path.root}/../../db")
}

# Servicio Redis de DEV.
module "cache" {
  source = "../../modules/cache"

  environment  = var.environment
  network_name = module.network.network_name
}

# Aplicacion Flask con dos instancias.
module "web" {
  source = "../../modules/web"

  environment   = var.environment
  network_name  = module.network.network_name
  build_context = abspath("${path.root}/../../app")
  replicas      = var.web_replicas
  base_port     = 5101

  mysql_host     = module.database.container_name
  mysql_password = module.database.app_password
  redis_host     = module.cache.container_name
}
