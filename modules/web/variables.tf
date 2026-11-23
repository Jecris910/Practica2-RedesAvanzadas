
variable "environment" {
  type = string
}

variable "network_name" {
  type = string
}

variable "build_context" {
  type = string
}

variable "replicas" {
  type = number

  validation {
    condition     = var.replicas >= 1
    error_message = "Se necesita al menos una instancia Flask."
  }
}

variable "base_port" {
  description = "Primer puerto HTTP publicado en Ubuntu"
  type        = number
}

variable "mysql_host" {
  type = string
}

variable "mysql_password" {
  type      = string
  sensitive = true
}

variable "redis_host" {
  type = string
}

# Endpoint interno del almacenamiento compartido.
variable "minio_url" {
  description = "URL interna del servidor MinIO"
  type        = string
  default     = "http://practica2-minio:8800"
}
