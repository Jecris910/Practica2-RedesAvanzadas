
# Entorno que estamos desplegando.
variable "environment" {
  description = "Entorno dev o prod"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "El entorno debe ser dev o prod."
  }
}

# Red Docker del entorno.
variable "network_name" {
  description = "Red Docker del balanceador"
  type        = string
}

# Numero de instancias Flask.
variable "replicas" {
  description = "Cantidad de servidores web"
  type        = number

  validation {
    condition     = var.replicas >= 2
    error_message = "El balanceador necesita al menos 2 instancias."
  }
}

# Puerto publicado en Ubuntu.
variable "external_port" {
  description = "Puerto de acceso al balanceador"
  type        = number
}
