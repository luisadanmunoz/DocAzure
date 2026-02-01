/**
 * # Azure Network Security Group Module
 *
 * Modulo reutilizable para crear NSGs en Azure.
 * Soporta reglas de seguridad dinamicas y diagnosticos.
 */

resource "azurerm_network_security_group" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.default_tags, var.tags)
}

# Reglas de seguridad
resource "azurerm_network_security_rule" "this" {
  for_each = { for rule in var.security_rules : rule.name => rule }

  name                         = each.value.name
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = lookup(each.value, "source_port_range", null)
  source_port_ranges           = lookup(each.value, "source_port_ranges", null)
  destination_port_range       = lookup(each.value, "destination_port_range", null)
  destination_port_ranges      = lookup(each.value, "destination_port_ranges", null)
  source_address_prefix        = lookup(each.value, "source_address_prefix", null)
  source_address_prefixes      = lookup(each.value, "source_address_prefixes", null)
  destination_address_prefix   = lookup(each.value, "destination_address_prefix", null)
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", null)
  description                  = lookup(each.value, "description", null)
  resource_group_name          = var.resource_group_name
  network_security_group_name  = azurerm_network_security_group.this.name
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_network_security_group.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
