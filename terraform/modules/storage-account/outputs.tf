output "id" {
  description = "ID del Storage Account"
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "Nombre del Storage Account"
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Endpoint primario de blob"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_file_endpoint" {
  description = "Endpoint primario de files"
  value       = azurerm_storage_account.this.primary_file_endpoint
}

output "primary_access_key" {
  description = "Clave de acceso primaria"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Clave de acceso secundaria"
  value       = azurerm_storage_account.this.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Cadena de conexion primaria"
  value       = azurerm_storage_account.this.primary_connection_string
  sensitive   = true
}

output "identity" {
  description = "Identidad del Storage Account"
  value       = azurerm_storage_account.this.identity
}

output "container_ids" {
  description = "IDs de los containers creados"
  value = {
    for name, container in azurerm_storage_container.this :
    name => container.id
  }
}

output "file_share_ids" {
  description = "IDs de los file shares creados"
  value = {
    for name, share in azurerm_storage_share.this :
    name => share.id
  }
}
