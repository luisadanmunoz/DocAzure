/**
 * # Azure Storage Account Module
 *
 * Modulo reutilizable para crear Storage Accounts en Azure.
 * Incluye configuracion de seguridad, networking, blob containers y file shares.
 */

resource "azurerm_storage_account" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = var.account_tier
  account_replication_type      = var.account_replication_type
  account_kind                  = var.account_kind
  access_tier                   = var.access_tier
  min_tls_version               = var.min_tls_version
  https_traffic_only_enabled    = var.https_traffic_only_enabled
  shared_access_key_enabled     = var.shared_access_key_enabled
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = merge(var.default_tags, var.tags)

  # Configuracion de blob
  dynamic "blob_properties" {
    for_each = var.enable_blob_properties ? [1] : []
    content {
      versioning_enabled       = var.blob_versioning_enabled
      change_feed_enabled      = var.blob_change_feed_enabled
      last_access_time_enabled = var.blob_last_access_time_enabled

      dynamic "delete_retention_policy" {
        for_each = var.blob_delete_retention_days > 0 ? [1] : []
        content {
          days = var.blob_delete_retention_days
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = var.container_delete_retention_days > 0 ? [1] : []
        content {
          days = var.container_delete_retention_days
        }
      }
    }
  }

  # Network rules
  dynamic "network_rules" {
    for_each = var.enable_network_rules ? [1] : []
    content {
      default_action             = var.network_default_action
      bypass                     = var.network_bypass
      ip_rules                   = var.network_ip_rules
      virtual_network_subnet_ids = var.network_subnet_ids
    }
  }

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }
}

# Blob Containers
resource "azurerm_storage_container" "this" {
  for_each = { for c in var.containers : c.name => c }

  name                  = each.value.name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = each.value.access_type
}

# File Shares
resource "azurerm_storage_share" "this" {
  for_each = { for s in var.file_shares : s.name => s }

  name               = each.value.name
  storage_account_id = azurerm_storage_account.this.id
  quota              = each.value.quota
  access_tier        = lookup(each.value, "access_tier", "TransactionOptimized")
}

# Diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "blob" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-blob-diag"
  target_resource_id         = "${azurerm_storage_account.this.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
    enabled  = true
  }
}
