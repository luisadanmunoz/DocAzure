variable "name" {
  description = "Nombre del Network Security Group"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.]{0,78}[a-zA-Z0-9]$", var.name))
    error_message = "El nombre debe comenzar y terminar con alfanumerico, 2-80 caracteres."
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

variable "security_rules" {
  description = "Lista de reglas de seguridad"
  type = list(object({
    name                         = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_range       = optional(string)
    destination_port_ranges      = optional(list(string))
    source_address_prefix        = optional(string)
    source_address_prefixes      = optional(list(string))
    destination_address_prefix   = optional(string)
    destination_address_prefixes = optional(list(string))
    description                  = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.security_rules :
      contains(["Inbound", "Outbound"], rule.direction)
    ])
    error_message = "La direccion debe ser 'Inbound' o 'Outbound'."
  }

  validation {
    condition = alltrue([
      for rule in var.security_rules :
      contains(["Allow", "Deny"], rule.access)
    ])
    error_message = "El acceso debe ser 'Allow' o 'Deny'."
  }
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
