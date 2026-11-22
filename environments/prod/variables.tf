
# Variables del entorno Terraform.

# Nombre del entorno.
variable "environment" {
  description = "Entorno de despliegue: dev o prod"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "El entorno debe ser dev o prod."
  }
}

# Numero de instancias Flask.
variable "web_replicas" {
  description = "Cantidad de instancias web del entorno"
  type        = number

  validation {
    condition     = var.web_replicas >= 1
    error_message = "Debe existir al menos una instancia web."
  }
}
