output "id" {
  description = "ID del Network Security Group"
  value       = azurerm_network_security_group.this.id
}

output "name" {
  description = "Nombre del NSG"
  value       = azurerm_network_security_group.this.name
}

output "location" {
  description = "Ubicacion del NSG"
  value       = azurerm_network_security_group.this.location
}

output "resource_group_name" {
  description = "Resource Group del NSG"
  value       = azurerm_network_security_group.this.resource_group_name
}

output "security_rules" {
  description = "Reglas de seguridad configuradas"
  value = {
    for rule in azurerm_network_security_rule.this :
    rule.name => {
      priority  = rule.priority
      direction = rule.direction
      access    = rule.access
      protocol  = rule.protocol
    }
  }
}
