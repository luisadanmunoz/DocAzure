variable "name" {
  description = "Nombre del Storage Account (debe ser globalmente unico)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "El nombre debe tener 3-24 caracteres, solo minusculas y numeros."
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

variable "account_tier" {
  description = "Tier de rendimiento (Standard o Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "El tier debe ser 'Standard' o 'Premium'."
  }
}

variable "account_replication_type" {
  description = "Tipo de replicacion (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Tipo de replicacion no valido."
  }
}

variable "account_kind" {
  description = "Tipo de Storage Account"
  type        = string
  default     = "StorageV2"

  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "Storage", "StorageV2"], var.account_kind)
    error_message = "Tipo de cuenta no valido."
  }
}

variable "access_tier" {
  description = "Tier de acceso por defecto (Hot o Cool)"
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "El access tier debe ser 'Hot' o 'Cool'."
  }
}

variable "min_tls_version" {
  description = "Version minima de TLS"
  type        = string
  default     = "TLS1_2"
}

variable "https_traffic_only_enabled" {
  description = "Permitir solo trafico HTTPS"
  type        = bool
  default     = true
}

variable "shared_access_key_enabled" {
  description = "Permitir acceso mediante Shared Access Keys"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Permitir acceso desde redes publicas"
  type        = bool
  default     = true
}

# Blob Properties
variable "enable_blob_properties" {
  description = "Habilitar configuracion de blob properties"
  type        = bool
  default     = true
}

variable "blob_versioning_enabled" {
  description = "Habilitar versionado de blobs"
  type        = bool
  default     = false
}

variable "blob_change_feed_enabled" {
  description = "Habilitar change feed"
  type        = bool
  default     = false
}

variable "blob_last_access_time_enabled" {
  description = "Habilitar tracking de ultimo acceso"
  type        = bool
  default     = false
}

variable "blob_delete_retention_days" {
  description = "Dias de retencion para blobs eliminados (0 para deshabilitar)"
  type        = number
  default     = 7
}

variable "container_delete_retention_days" {
  description = "Dias de retencion para containers eliminados"
  type        = number
  default     = 7
}

# Network Rules
variable "enable_network_rules" {
  description = "Habilitar reglas de red"
  type        = bool
  default     = false
}

variable "network_default_action" {
  description = "Accion por defecto para trafico de red"
  type        = string
  default     = "Deny"
}

variable "network_bypass" {
  description = "Servicios que pueden bypasear las reglas de red"
  type        = list(string)
  default     = ["AzureServices", "Logging", "Metrics"]
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

# Identity
variable "identity_type" {
  description = "Tipo de identidad (SystemAssigned, UserAssigned, SystemAssigned,UserAssigned)"
  type        = string
  default     = null
}

variable "identity_ids" {
  description = "Lista de IDs de identidades asignadas por usuario"
  type        = list(string)
  default     = []
}

# Containers y File Shares
variable "containers" {
  description = "Lista de blob containers a crear"
  type = list(object({
    name        = string
    access_type = optional(string, "private")
  }))
  default = []
}

variable "file_shares" {
  description = "Lista de file shares a crear"
  type = list(object({
    name        = string
    quota       = number
    access_tier = optional(string, "TransactionOptimized")
  }))
  default = []
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
