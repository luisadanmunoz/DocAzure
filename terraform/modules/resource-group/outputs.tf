output "id" {
  description = "ID del Resource Group"
  value       = azurerm_resource_group.this.id
}

output "name" {
  description = "Nombre del Resource Group"
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Ubicacion del Resource Group"
  value       = azurerm_resource_group.this.location
}

output "tags" {
  description = "Tags aplicados al Resource Group"
  value       = azurerm_resource_group.this.tags
}
