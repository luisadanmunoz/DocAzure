output "id" {
  description = "ID del Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.this.id
}

output "name" {
  description = "Nombre del workspace"
  value       = azurerm_log_analytics_workspace.this.name
}

output "workspace_id" {
  description = "Workspace ID (GUID)"
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "primary_shared_key" {
  description = "Clave primaria del workspace"
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "secondary_shared_key" {
  description = "Clave secundaria del workspace"
  value       = azurerm_log_analytics_workspace.this.secondary_shared_key
  sensitive   = true
}

output "location" {
  description = "Ubicacion del workspace"
  value       = azurerm_log_analytics_workspace.this.location
}

output "resource_group_name" {
  description = "Resource Group del workspace"
  value       = azurerm_log_analytics_workspace.this.resource_group_name
}

output "data_collection_rule_id" {
  description = "ID del Data Collection Rule"
  value       = var.create_data_collection_rule ? azurerm_monitor_data_collection_rule.this[0].id : null
}

output "action_group_id" {
  description = "ID del Action Group"
  value       = var.create_action_group ? azurerm_monitor_action_group.this[0].id : null
}

output "solution_ids" {
  description = "IDs de las solutions instaladas"
  value = {
    for name, solution in azurerm_log_analytics_solution.this :
    name => solution.id
  }
}
