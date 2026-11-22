# Nombre del entorno de despliegue.
variable "environment" {
  description = "Nombre del entorno"
  type        = string
}

# Numero de instancias de la aplicacion web.
variable "web_replicas" {
  description = "Numero de replicas web"
  type        = number

  validation {
    condition     = var.web_replicas >= 1
    error_message = "Debe existir al menos una instancia web."
  }
}