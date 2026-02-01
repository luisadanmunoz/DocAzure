/**
 * # Azure Resource Group Module
 *
 * Modulo reutilizable para crear Resource Groups en Azure.
 * Incluye soporte para tags, locks y configuracion de ubicacion.
 */

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = merge(var.default_tags, var.tags)
}

resource "azurerm_management_lock" "this" {
  count = var.enable_lock ? 1 : 0

  name       = "${var.name}-lock"
  scope      = azurerm_resource_group.this.id
  lock_level = var.lock_level
  notes      = var.lock_notes
}
