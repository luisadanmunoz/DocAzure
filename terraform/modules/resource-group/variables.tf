variable "name" {
  description = "Nombre del Resource Group"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,90}$", var.name))
    error_message = "El nombre debe tener entre 1-90 caracteres alfanumericos, guiones o guiones bajos."
  }
}

variable "location" {
  description = "Region de Azure donde se creara el Resource Group"
  type        = string
  default     = "westeurope"
}

variable "tags" {
  description = "Tags adicionales para el Resource Group"
  type        = map(string)
  default     = {}
}

variable "default_tags" {
  description = "Tags por defecto aplicados a todos los recursos"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

variable "enable_lock" {
  description = "Habilitar lock de eliminacion en el Resource Group"
  type        = bool
  default     = false
}

variable "lock_level" {
  description = "Nivel del lock (CanNotDelete o ReadOnly)"
  type        = string
  default     = "CanNotDelete"

  validation {
    condition     = contains(["CanNotDelete", "ReadOnly"], var.lock_level)
    error_message = "El nivel de lock debe ser 'CanNotDelete' o 'ReadOnly'."
  }
}

variable "lock_notes" {
  description = "Notas descriptivas para el lock"
  type        = string
  default     = "Resource Group protegido contra eliminacion accidental"
}
