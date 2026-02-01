/**
 * # Azure Key Vault Module
 *
 * Modulo reutilizable para crear Key Vaults en Azure.
 * Soporta access policies, RBAC, network rules y purge protection.
 */

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)
  sku_name                      = var.sku_name
  enabled_for_deployment        = var.enabled_for_deployment
  enabled_for_disk_encryption   = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization     = var.enable_rbac_authorization
  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = var.soft_delete_retention_days
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = merge(var.default_tags, var.tags)

  # Network ACLs
  dynamic "network_acls" {
    for_each = var.enable_network_acls ? [1] : []
    content {
      default_action             = var.network_default_action
      bypass                     = var.network_bypass
      ip_rules                   = var.network_ip_rules
      virtual_network_subnet_ids = var.network_subnet_ids
    }
  }

  # Access policies (solo si RBAC no esta habilitado)
  dynamic "access_policy" {
    for_each = var.enable_rbac_authorization ? [] : var.access_policies
    content {
      tenant_id               = coalesce(access_policy.value.tenant_id, data.azurerm_client_config.current.tenant_id)
      object_id               = access_policy.value.object_id
      application_id          = lookup(access_policy.value, "application_id", null)
      certificate_permissions = lookup(access_policy.value, "certificate_permissions", [])
      key_permissions         = lookup(access_policy.value, "key_permissions", [])
      secret_permissions      = lookup(access_policy.value, "secret_permissions", [])
      storage_permissions     = lookup(access_policy.value, "storage_permissions", [])
    }
  }
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Secrets
resource "azurerm_key_vault_secret" "this" {
  for_each = { for s in var.secrets : s.name => s }

  name            = each.value.name
  value           = each.value.value
  key_vault_id    = azurerm_key_vault.this.id
  content_type    = lookup(each.value, "content_type", null)
  expiration_date = lookup(each.value, "expiration_date", null)
  not_before_date = lookup(each.value, "not_before_date", null)
  tags            = lookup(each.value, "tags", {})

  depends_on = [azurerm_key_vault.this]
}
