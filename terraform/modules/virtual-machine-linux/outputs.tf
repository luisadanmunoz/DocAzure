output "id" {
  description = "ID de la Virtual Machine"
  value       = azurerm_linux_virtual_machine.this.id
}

output "name" {
  description = "Nombre de la Virtual Machine"
  value       = azurerm_linux_virtual_machine.this.name
}

output "private_ip_address" {
  description = "IP privada de la VM"
  value       = azurerm_network_interface.this.private_ip_address
}

output "public_ip_address" {
  description = "IP publica de la VM (si existe)"
  value       = azurerm_linux_virtual_machine.this.public_ip_address
}

output "virtual_machine_id" {
  description = "Virtual Machine ID (VMID)"
  value       = azurerm_linux_virtual_machine.this.virtual_machine_id
}

output "identity" {
  description = "Identidad de la VM"
  value       = azurerm_linux_virtual_machine.this.identity
}

output "principal_id" {
  description = "Principal ID de la identidad de la VM"
  value       = try(azurerm_linux_virtual_machine.this.identity[0].principal_id, null)
}

output "network_interface_id" {
  description = "ID de la Network Interface"
  value       = azurerm_network_interface.this.id
}

output "admin_username" {
  description = "Nombre del usuario administrador"
  value       = azurerm_linux_virtual_machine.this.admin_username
}

output "os_disk_id" {
  description = "ID del disco del sistema operativo"
  value       = azurerm_linux_virtual_machine.this.os_disk[0].name
}

output "data_disk_ids" {
  description = "IDs de los data disks"
  value = {
    for name, disk in azurerm_managed_disk.this :
    name => disk.id
  }
}
