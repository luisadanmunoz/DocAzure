output "resource_group_name" {
  description = "Nombre del Resource Group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID del Resource Group"
  value       = module.resource_group.id
}

output "vnet_id" {
  description = "ID de la Virtual Network"
  value       = module.vnet.id
}

output "vnet_name" {
  description = "Nombre de la Virtual Network"
  value       = module.vnet.name
}

output "subnet_web_id" {
  description = "ID de la Subnet Web"
  value       = module.subnet_web.id
}

output "subnet_db_id" {
  description = "ID de la Subnet Database"
  value       = module.subnet_db.id
}

output "storage_account_name" {
  description = "Nombre del Storage Account"
  value       = module.storage.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Endpoint de blob del Storage Account"
  value       = module.storage.primary_blob_endpoint
}

output "key_vault_name" {
  description = "Nombre del Key Vault"
  value       = module.key_vault.name
}

output "key_vault_uri" {
  description = "URI del Key Vault"
  value       = module.key_vault.vault_uri
}

output "log_analytics_workspace_id" {
  description = "ID del Log Analytics Workspace"
  value       = module.log_analytics.id
}

output "log_analytics_workspace_name" {
  description = "Nombre del Log Analytics Workspace"
  value       = module.log_analytics.name
}

output "vm_web_private_ip" {
  description = "IP privada de la VM Web"
  value       = module.vm_web.private_ip_address
}

output "vm_web_principal_id" {
  description = "Principal ID de la identidad de la VM Web"
  value       = module.vm_web.principal_id
}
