/**
 * # Azure Log Analytics Workspace Module
 *
 * Modulo reutilizable para crear Log Analytics Workspaces en Azure.
 * Incluye configuracion de retencion, soluciones y data collection rules.
 */

resource "azurerm_log_analytics_workspace" "this" {
  name                               = var.name
  location                           = var.location
  resource_group_name                = var.resource_group_name
  sku                                = var.sku
  retention_in_days                  = var.retention_in_days
  daily_quota_gb                     = var.daily_quota_gb
  internet_ingestion_enabled         = var.internet_ingestion_enabled
  internet_query_enabled             = var.internet_query_enabled
  reservation_capacity_in_gb_per_day = var.sku == "CapacityReservation" ? var.reservation_capacity_in_gb_per_day : null
  tags                               = merge(var.default_tags, var.tags)
}

# Solutions
resource "azurerm_log_analytics_solution" "this" {
  for_each = { for s in var.solutions : s.solution_name => s }

  solution_name         = each.value.solution_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.this.id
  workspace_name        = azurerm_log_analytics_workspace.this.name

  plan {
    publisher = each.value.publisher
    product   = each.value.product
  }
}

# Data Collection Rule para VMs
resource "azurerm_monitor_data_collection_rule" "this" {
  count = var.create_data_collection_rule ? 1 : 0

  name                = "${var.name}-dcr"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = merge(var.default_tags, var.tags)

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
      name                  = "destination-log"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog", "Microsoft-Perf"]
    destinations = ["destination-log"]
  }

  data_sources {
    syslog {
      facility_names = var.syslog_facilities
      log_levels     = var.syslog_levels
      name           = "datasource-syslog"
      streams        = ["Microsoft-Syslog"]
    }

    performance_counter {
      counter_specifiers            = var.performance_counters
      name                          = "datasource-perfcounter"
      sampling_frequency_in_seconds = var.performance_sampling_frequency
      streams                       = ["Microsoft-Perf"]
    }
  }
}

# Action Group para alertas
resource "azurerm_monitor_action_group" "this" {
  count = var.create_action_group ? 1 : 0

  name                = "${var.name}-ag"
  resource_group_name = var.resource_group_name
  short_name          = substr(var.name, 0, 12)
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.action_group_emails
    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.email
    }
  }
}
