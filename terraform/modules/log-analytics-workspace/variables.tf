variable "name" {
  description = "Nombre del Log Analytics Workspace"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{2,61}[a-zA-Z0-9]$", var.name))
    error_message = "El nombre debe tener 4-63 caracteres alfanumericos y guiones."
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

variable "sku" {
  description = "SKU del workspace (Free, PerNode, Premium, Standard, Standalone, Unlimited, CapacityReservation, PerGB2018)"
  type        = string
  default     = "PerGB2018"

  validation {
    condition     = contains(["Free", "PerNode", "Premium", "Standard", "Standalone", "Unlimited", "CapacityReservation", "PerGB2018"], var.sku)
    error_message = "SKU no valido."
  }
}

variable "retention_in_days" {
  description = "Dias de retencion de logs"
  type        = number
  default     = 30

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "La retencion debe estar entre 30 y 730 dias."
  }
}

variable "daily_quota_gb" {
  description = "Cuota diaria de ingestion en GB (-1 para ilimitado)"
  type        = number
  default     = -1
}

variable "internet_ingestion_enabled" {
  description = "Permitir ingestion desde internet"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Permitir queries desde internet"
  type        = bool
  default     = true
}

variable "reservation_capacity_in_gb_per_day" {
  description = "Capacidad reservada por dia (solo para SKU CapacityReservation)"
  type        = number
  default     = null
}

# Solutions
variable "solutions" {
  description = "Lista de solutions a habilitar"
  type = list(object({
    solution_name = string
    publisher     = string
    product       = string
  }))
  default = [
    {
      solution_name = "VMInsights"
      publisher     = "Microsoft"
      product       = "OMSGallery/VMInsights"
    },
    {
      solution_name = "SecurityInsights"
      publisher     = "Microsoft"
      product       = "OMSGallery/SecurityInsights"
    }
  ]
}

# Data Collection Rule
variable "create_data_collection_rule" {
  description = "Crear Data Collection Rule para VMs"
  type        = bool
  default     = false
}

variable "syslog_facilities" {
  description = "Facilities de syslog a recolectar"
  type        = list(string)
  default     = ["auth", "authpriv", "cron", "daemon", "kern", "syslog"]
}

variable "syslog_levels" {
  description = "Niveles de syslog a recolectar"
  type        = list(string)
  default     = ["Alert", "Critical", "Emergency", "Error", "Warning"]
}

variable "performance_counters" {
  description = "Contadores de rendimiento a recolectar"
  type        = list(string)
  default = [
    "Processor(*)\\% Processor Time",
    "Memory(*)\\% Used Memory",
    "LogicalDisk(*)\\% Free Space",
    "Network(*)\\Total Bytes Transmitted",
    "Network(*)\\Total Bytes Received"
  ]
}

variable "performance_sampling_frequency" {
  description = "Frecuencia de muestreo en segundos"
  type        = number
  default     = 60
}

# Action Group
variable "create_action_group" {
  description = "Crear Action Group para alertas"
  type        = bool
  default     = false
}

variable "action_group_emails" {
  description = "Lista de emails para el action group"
  type = list(object({
    name  = string
    email = string
  }))
  default = []
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
