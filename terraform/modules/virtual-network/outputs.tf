output "id" {
  description = "ID de la Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "Nombre de la Virtual Network"
  value       = azurerm_virtual_network.this.name
}

output "address_space" {
  description = "Espacio de direcciones de la VNet"
  value       = azurerm_virtual_network.this.address_space
}

output "guid" {
  description = "GUID de la Virtual Network"
  value       = azurerm_virtual_network.this.guid
}

output "location" {
  description = "Ubicacion de la VNet"
  value       = azurerm_virtual_network.this.location
}

output "resource_group_name" {
  description = "Resource Group de la VNet"
  value       = azurerm_virtual_network.this.resource_group_name
}
