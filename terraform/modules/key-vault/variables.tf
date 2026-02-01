variable "name" {
  description = "Nombre del Key Vault (debe ser globalmente unico)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.name))
    error_message = "El nombre debe tener 3-24 caracteres, comenzar con letra, terminar con alfanumerico."
  }
}

variable "resource_group_name" {
  description = "Nombre del Resource Group"
  type        = string
}

variable "location" {
  description = "Region de Azure"
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID de Azure AD (si no se especifica, se usa el actual)"
  type        = string
  default     = null
}

variable "sku_name" {
  description = "SKU del Key Vault (standard o premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "El SKU debe ser 'standard' o 'premium'."
  }
}

variable "enabled_for_deployment" {
  description = "Permitir VMs acceder a certificados"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Permitir Azure Disk Encryption acceder a secrets"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Permitir ARM templates acceder a secrets"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Usar RBAC en lugar de Access Policies"
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Habilitar proteccion contra purga"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Dias de retencion para soft delete"
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Los dias de retencion deben estar entre 7 y 90."
  }
}

variable "public_network_access_enabled" {
  description = "Permitir acceso desde redes publicas"
  type        = bool
  default     = true
}

# Network ACLs
variable "enable_network_acls" {
  description = "Habilitar Network ACLs"
  type        = bool
  default     = false
}

variable "network_default_action" {
  description = "Accion por defecto para Network ACLs"
  type        = string
  default     = "Deny"
}

variable "network_bypass" {
  description = "Servicios que pueden bypasear Network ACLs"
  type        = string
  default     = "AzureServices"
}

variable "network_ip_rules" {
  description = "Lista de IPs o rangos CIDR permitidos"
  type        = list(string)
  default     = []
}

variable "network_subnet_ids" {
  description = "Lista de IDs de subnets permitidas"
  type        = list(string)
  default     = []
}

# Access Policies
variable "access_policies" {
  description = "Lista de access policies (ignorado si RBAC esta habilitado)"
  type = list(object({
    tenant_id               = optional(string)
    object_id               = string
    application_id          = optional(string)
    certificate_permissions = optional(list(string), [])
    key_permissions         = optional(list(string), [])
    secret_permissions      = optional(list(string), [])
    storage_permissions     = optional(list(string), [])
  }))
  default = []
}

# Secrets
variable "secrets" {
  description = "Lista de secrets a crear"
  type = list(object({
    name            = string
    value           = string
    content_type    = optional(string)
    expiration_date = optional(string)
    not_before_date = optional(string)
    tags            = optional(map(string), {})
  }))
  default   = []
  sensitive = true
}

# Diagnostics
variable "log_analytics_workspace_id" {
  description = "ID del Log Analytics Workspace para diagnosticos"
  type        = string
  default     = null
}

# Tags
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
