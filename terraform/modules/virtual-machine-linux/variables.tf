variable "name" {
  description = "Nombre de la Virtual Machine"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}[a-zA-Z0-9]$", var.name))
    error_message = "El nombre debe tener 2-64 caracteres alfanumericos y guiones."
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

variable "size" {
  description = "Tamano de la VM (ej: Standard_B2s, Standard_D2s_v3)"
  type        = string
  default     = "Standard_B2s"
}

variable "zone" {
  description = "Availability Zone (1, 2 o 3)"
  type        = string
  default     = null
}

# Network
variable "subnet_id" {
  description = "ID de la subnet donde se desplegara la VM"
  type        = string
}

variable "private_ip_address_allocation" {
  description = "Metodo de asignacion de IP privada (Dynamic o Static)"
  type        = string
  default     = "Dynamic"
}

variable "private_ip_address" {
  description = "IP privada estatica (requerido si allocation es Static)"
  type        = string
  default     = null
}

variable "public_ip_address_id" {
  description = "ID de la IP publica (opcional)"
  type        = string
  default     = null
}

variable "network_security_group_id" {
  description = "ID del NSG a asociar con la NIC"
  type        = string
  default     = null
}

# Authentication
variable "admin_username" {
  description = "Nombre del usuario administrador"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Password del administrador (requerido si disable_password_authentication es false)"
  type        = string
  default     = null
  sensitive   = true
}

variable "disable_password_authentication" {
  description = "Deshabilitar autenticacion por password"
  type        = bool
  default     = true
}

variable "admin_ssh_keys" {
  description = "Lista de claves SSH publicas"
  type        = list(string)
  default     = []
}

variable "computer_name" {
  description = "Hostname de la VM (por defecto usa el nombre de la VM)"
  type        = string
  default     = null
}

# OS Disk
variable "os_disk_caching" {
  description = "Tipo de caching del disco OS"
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "Tipo de storage del disco OS"
  type        = string
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"], var.os_disk_storage_account_type)
    error_message = "Tipo de storage no valido."
  }
}

variable "os_disk_size_gb" {
  description = "Tamano del disco OS en GB"
  type        = number
  default     = null
}

variable "os_disk_write_accelerator_enabled" {
  description = "Habilitar Write Accelerator"
  type        = bool
  default     = false
}

variable "disk_encryption_set_id" {
  description = "ID del Disk Encryption Set"
  type        = string
  default     = null
}

# Source Image
variable "source_image_id" {
  description = "ID de imagen personalizada (si se usa, ignora source_image_reference)"
  type        = string
  default     = null
}

variable "source_image_publisher" {
  description = "Publisher de la imagen"
  type        = string
  default     = "Canonical"
}

variable "source_image_offer" {
  description = "Offer de la imagen"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "source_image_sku" {
  description = "SKU de la imagen"
  type        = string
  default     = "22_04-lts-gen2"
}

variable "source_image_version" {
  description = "Version de la imagen"
  type        = string
  default     = "latest"
}

# Identity
variable "identity_type" {
  description = "Tipo de identidad (SystemAssigned, UserAssigned, SystemAssigned,UserAssigned)"
  type        = string
  default     = "SystemAssigned"
}

variable "identity_ids" {
  description = "Lista de IDs de identidades asignadas por usuario"
  type        = list(string)
  default     = []
}

# Boot Diagnostics
variable "enable_boot_diagnostics" {
  description = "Habilitar boot diagnostics"
  type        = bool
  default     = true
}

variable "boot_diagnostics_storage_account_uri" {
  description = "URI del storage account para boot diagnostics (null para managed)"
  type        = string
  default     = null
}

# Data Disks
variable "data_disks" {
  description = "Lista de data disks a crear y adjuntar"
  type = list(object({
    name                 = string
    disk_size_gb         = number
    storage_account_type = string
    lun                  = number
    caching              = optional(string, "ReadWrite")
    create_option        = optional(string, "Empty")
  }))
  default = []
}

# Configuration
variable "custom_data" {
  description = "Cloud-init custom data (base64 encoded)"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data (base64 encoded)"
  type        = string
  default     = null
}

variable "encryption_at_host_enabled" {
  description = "Habilitar encriptacion en el host"
  type        = bool
  default     = false
}

variable "patch_mode" {
  description = "Modo de parcheo (ImageDefault, AutomaticByPlatform)"
  type        = string
  default     = "ImageDefault"
}

variable "provision_vm_agent" {
  description = "Instalar el agente de VM"
  type        = bool
  default     = true
}

# Extensions
variable "enable_azure_monitor_agent" {
  description = "Instalar Azure Monitor Agent"
  type        = bool
  default     = false
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
