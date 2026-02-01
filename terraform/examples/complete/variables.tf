variable "project" {
  description = "Nombre del proyecto"
  type        = string
  default     = "demo"
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El entorno debe ser dev, staging o prod."
  }
}

variable "location" {
  description = "Region de Azure"
  type        = string
  default     = "westeurope"
}

variable "admin_ssh_public_key" {
  description = "Clave SSH publica para las VMs"
  type        = string
  sensitive   = true
}
