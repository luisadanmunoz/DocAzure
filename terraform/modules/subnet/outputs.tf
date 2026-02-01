output "id" {
  description = "ID de la Subnet"
  value       = azurerm_subnet.this.id
}

output "name" {
  description = "Nombre de la Subnet"
  value       = azurerm_subnet.this.name
}

output "address_prefixes" {
  description = "Prefijos de direcciones de la Subnet"
  value       = azurerm_subnet.this.address_prefixes
}

output "virtual_network_name" {
  description = "Nombre de la VNet asociada"
  value       = azurerm_subnet.this.virtual_network_name
}

output "resource_group_name" {
  description = "Resource Group de la Subnet"
  value       = azurerm_subnet.this.resource_group_name
}
