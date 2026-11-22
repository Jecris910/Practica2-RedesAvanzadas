
# Parametros del modulo de MySQL.
variable "environment" {
  description = "Entorno dev o prod"
  type        = string
}

variable "network_name" {
  description = "Red Docker del entorno"
  type        = string
}

variable "build_context" {
  description = "Ruta absoluta a la carpeta db"
  type        = string
}
