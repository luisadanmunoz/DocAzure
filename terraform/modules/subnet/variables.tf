variable "name" {
  description = "Nombre de la Subnet"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.]{0,78}[a-zA-Z0-9]$", var.name))
    error_message = "El nombre debe comenzar y terminar con alfanumerico, 2-80 caracteres."
  }
}

variable "resource_group_name" {
  description = "Nombre del Resource Group"
  type        = string
}

variable "virtual_network_name" {
  description = "Nombre de la Virtual Network"
  type        = string
}

variable "address_prefixes" {
  description = "Prefijos de direcciones CIDR para la Subnet"
  type        = list(string)

  validation {
    condition     = length(var.address_prefixes) > 0
    error_message = "Debe especificar al menos un prefijo de direcciones."
  }
}

variable "service_endpoints" {
  description = "Lista de Service Endpoints a habilitar"
  type        = list(string)
  default     = []

  # Valores validos: Microsoft.AzureActiveDirectory, Microsoft.AzureCosmosDB,
  # Microsoft.ContainerRegistry, Microsoft.EventHub, Microsoft.KeyVault,
  # Microsoft.ServiceBus, Microsoft.Sql, Microsoft.Storage, Microsoft.Web
}

variable "delegations" {
  description = "Lista de delegations para la subnet"
  type = list(object({
    name                       = string
    service_delegation_name    = string
    service_delegation_actions = optional(list(string), [])
  }))
  default = []
}

variable "private_endpoint_network_policies" {
  description = "Politica de red para Private Endpoints (Enabled, Disabled, NetworkSecurityGroupEnabled, RouteTableEnabled)"
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"], var.private_endpoint_network_policies)
    error_message = "Valor no valido para private_endpoint_network_policies."
  }
}

variable "private_link_service_network_policies_enabled" {
  description = "Habilitar politicas de red para Private Link Service"
  type        = bool
  default     = true
}

variable "network_security_group_id" {
  description = "ID del Network Security Group a asociar"
  type        = string
  default     = null
}

variable "route_table_id" {
  description = "ID de la Route Table a asociar"
  type        = string
  default     = null
}
