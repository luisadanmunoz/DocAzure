output "id" {
  description = "ID del Key Vault"
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Nombre del Key Vault"
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "URI del Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}

output "tenant_id" {
  description = "Tenant ID del Key Vault"
  value       = azurerm_key_vault.this.tenant_id
}

output "location" {
  description = "Ubicacion del Key Vault"
  value       = azurerm_key_vault.this.location
}

output "resource_group_name" {
  description = "Resource Group del Key Vault"
  value       = azurerm_key_vault.this.resource_group_name
}

output "secret_ids" {
  description = "IDs de los secrets creados"
  value = {
    for name, secret in azurerm_key_vault_secret.this :
    name => secret.id
  }
}

output "secret_versionless_ids" {
  description = "IDs sin version de los secrets creados"
  value = {
    for name, secret in azurerm_key_vault_secret.this :
    name => secret.versionless_id
  }
}
