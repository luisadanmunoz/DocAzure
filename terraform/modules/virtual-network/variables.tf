variable "name" {
  description = "Nombre de la Virtual Network"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.]{0,62}[a-zA-Z0-9]$", var.name))
    error_message = "El nombre debe comenzar y terminar con alfanumerico, 2-64 caracteres."
  }
}

variable "location" {
  description = "Region de Azure"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del Resource Group"
  type        = string
}

variable "address_space" {
  description = "Espacio de direcciones CIDR para la VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]

  validation {
    condition     = length(var.address_space) > 0
    error_message = "Debe especificar al menos un espacio de direcciones."
  }
}

variable "dns_servers" {
  description = "Lista de servidores DNS personalizados"
  type        = list(string)
  default     = []
}

variable "ddos_protection_plan_id" {
  description = "ID del DDoS Protection Plan (opcional)"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "ID del Log Analytics Workspace para diagnosticos"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

variable "default_tags" {
  description = "Tags por defecto"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
