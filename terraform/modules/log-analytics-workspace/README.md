# Azure Log Analytics Workspace Module

Modulo de Terraform para crear Log Analytics Workspaces en Azure con soporte para Solutions, Data Collection Rules y Action Groups para alertas.

## Uso Basico

```hcl
module "log_analytics" {
  source = "../../modules/log-analytics-workspace"

  name                = "law-mi-proyecto-dev"
  resource_group_name = "rg-monitoring-dev"
  location            = "westeurope"
}
```

## Uso con Retencion Personalizada

```hcl
module "log_analytics" {
  source = "../../modules/log-analytics-workspace"

  name                = "law-empresa-prod"
  resource_group_name = "rg-monitoring-prod"
  location            = "westeurope"
  sku                 = "PerGB2018"
  retention_in_days   = 90     # Retencion de 90 dias
  daily_quota_gb      = 10     # Limite de 10 GB/dia

  tags = {
    Environment = "production"
    CostCenter  = "IT-Monitoring"
  }
}
```

## Uso con Solutions

```hcl
module "log_analytics" {
  source = "../../modules/log-analytics-workspace"

  name                = "law-completo-prod"
  resource_group_name = "rg-monitoring-prod"
  location            = "westeurope"
  retention_in_days   = 90

  # Soluciones a instalar
  solutions = [
    {
      solution_name = "VMInsights"
      publisher     = "Microsoft"
      product       = "OMSGallery/VMInsights"
    },
    {
      solution_name = "SecurityInsights"  # Microsoft Sentinel
      publisher     = "Microsoft"
      product       = "OMSGallery/SecurityInsights"
    },
    {
      solution_name = "ContainerInsights"
      publisher     = "Microsoft"
      product       = "OMSGallery/ContainerInsights"
    },
    {
      solution_name = "AzureActivity"
      publisher     = "Microsoft"
      product       = "OMSGallery/AzureActivity"
    },
    {
      solution_name = "Updates"
      publisher     = "Microsoft"
      product       = "OMSGallery/Updates"
    }
  ]
}
```

## Uso con Data Collection Rule

```hcl
module "log_analytics" {
  source = "../../modules/log-analytics-workspace"

  name                = "law-vms-prod"
  resource_group_name = "rg-monitoring-prod"
  location            = "westeurope"

  # Crear DCR para recoleccion de VMs
  create_data_collection_rule = true

  # Configuracion de Syslog
  syslog_facilities = ["auth", "authpriv", "cron", "daemon", "kern", "syslog", "local0"]
  syslog_levels     = ["Alert", "Critical", "Emergency", "Error", "Warning"]

  # Contadores de rendimiento
  performance_counters = [
    "Processor(*)\\% Processor Time",
    "Processor(*)\\% Idle Time",
    "Memory(*)\\% Used Memory",
    "Memory(*)\\Available Bytes",
    "LogicalDisk(*)\\% Free Space",
    "LogicalDisk(*)\\Disk Reads/sec",
    "LogicalDisk(*)\\Disk Writes/sec",
    "Network(*)\\Total Bytes Transmitted",
    "Network(*)\\Total Bytes Received"
  ]
  performance_sampling_frequency = 60  # Cada 60 segundos
}

# Asociar DCR a las VMs
resource "azurerm_monitor_data_collection_rule_association" "vm" {
  for_each = toset(["vm-web-01", "vm-web-02", "vm-app-01"])

  name                    = "dcra-${each.key}"
  target_resource_id      = module.vms[each.key].id
  data_collection_rule_id = module.log_analytics.data_collection_rule_id
}
```

## Uso con Action Group para Alertas

```hcl
module "log_analytics" {
  source = "../../modules/log-analytics-workspace"

  name                = "law-alertas-prod"
  resource_group_name = "rg-monitoring-prod"
  location            = "westeurope"

  # Crear Action Group
  create_action_group = true
  action_group_emails = [
    {
      name  = "admin"
      email = "admin@empresa.com"
    },
    {
      name  = "oncall"
      email = "oncall@empresa.com"
    },
    {
      name  = "devops"
      email = "devops-team@empresa.com"
    }
  ]
}

# Crear alerta de CPU
resource "azurerm_monitor_metric_alert" "cpu_high" {
  name                = "alert-cpu-high"
  resource_group_name = "rg-monitoring-prod"
  scopes              = [module.vm.id]
  description         = "Alerta cuando CPU supera 80%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = module.log_analytics.action_group_id
  }
}
```

## Uso para Centralizacion de Logs

```hcl
# Workspace centralizado
module "log_analytics_central" {
  source = "../../modules/log-analytics-workspace"

  name                       = "law-central-prod"
  resource_group_name        = "rg-monitoring-prod"
  location                   = "westeurope"
  retention_in_days          = 365  # 1 año para compliance
  internet_ingestion_enabled = true
  internet_query_enabled     = true

  solutions = [
    {
      solution_name = "SecurityInsights"
      publisher     = "Microsoft"
      product       = "OMSGallery/SecurityInsights"
    }
  ]
}

# Conectar diagnosticos de otros recursos
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "diag-storage"
  target_resource_id         = "${module.storage.id}/blobServices/default"
  log_analytics_workspace_id = module.log_analytics_central.id

  enabled_log {
    category = "StorageRead"
  }
  enabled_log {
    category = "StorageWrite"
  }
  enabled_log {
    category = "StorageDelete"
  }
}

resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "diag-keyvault"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = module.log_analytics_central.id

  enabled_log {
    category = "AuditEvent"
  }
}
```

## Inputs

| Nombre | Descripcion | Tipo | Default | Requerido |
|--------|-------------|------|---------|-----------|
| `name` | Nombre del workspace (4-63 caracteres) | `string` | - | Si |
| `resource_group_name` | Nombre del Resource Group | `string` | - | Si |
| `location` | Region de Azure | `string` | - | Si |
| `sku` | SKU del workspace | `string` | `"PerGB2018"` | No |
| `retention_in_days` | Dias de retencion (30-730) | `number` | `30` | No |
| `daily_quota_gb` | Cuota diaria en GB (-1 = ilimitado) | `number` | `-1` | No |
| `internet_ingestion_enabled` | Ingestion desde internet | `bool` | `true` | No |
| `internet_query_enabled` | Queries desde internet | `bool` | `true` | No |

### Solutions

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `solutions` | Lista de solutions a instalar | `list(object)` | VMInsights, SecurityInsights |

### Data Collection Rule

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `create_data_collection_rule` | Crear DCR | `bool` | `false` |
| `syslog_facilities` | Facilities de syslog | `list(string)` | auth, cron, daemon... |
| `syslog_levels` | Niveles de syslog | `list(string)` | Alert, Critical, Error... |
| `performance_counters` | Contadores a recolectar | `list(string)` | CPU, Memory, Disk... |
| `performance_sampling_frequency` | Frecuencia en segundos | `number` | `60` |

### Action Group

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `create_action_group` | Crear Action Group | `bool` | `false` |
| `action_group_emails` | Emails para alertas | `list(object)` | `[]` |

## Outputs

| Nombre | Descripcion |
|--------|-------------|
| `id` | ID del workspace |
| `name` | Nombre del workspace |
| `workspace_id` | Workspace ID (GUID) |
| `primary_shared_key` | Clave primaria (sensitive) |
| `secondary_shared_key` | Clave secundaria (sensitive) |
| `location` | Region |
| `resource_group_name` | Resource Group |
| `data_collection_rule_id` | ID del DCR (si se creo) |
| `action_group_id` | ID del Action Group (si se creo) |
| `solution_ids` | IDs de solutions instaladas |

## SKUs Disponibles

| SKU | Descripcion | Uso |
|-----|-------------|-----|
| `Free` | Limitado a 500 MB/dia, 7 dias retencion | Solo pruebas |
| `PerGB2018` | Pago por GB ingerido | Recomendado |
| `CapacityReservation` | Reserva de capacidad | Alto volumen |
| `Standalone` | Legado | No usar |
| `PerNode` | Legado (OMS) | No usar |

## Solutions Comunes

| Solution | Producto | Descripcion |
|----------|----------|-------------|
| VMInsights | OMSGallery/VMInsights | Monitoreo de VMs |
| ContainerInsights | OMSGallery/ContainerInsights | Monitoreo de contenedores |
| SecurityInsights | OMSGallery/SecurityInsights | Microsoft Sentinel (SIEM) |
| AzureActivity | OMSGallery/AzureActivity | Activity Log de Azure |
| Updates | OMSGallery/Updates | Azure Update Management |
| ChangeTracking | OMSGallery/ChangeTracking | Tracking de cambios |
| AntiMalware | OMSGallery/AntiMalware | Antimalware assessment |
| SQLAssessment | OMSGallery/SQLAssessment | SQL Server assessment |
| ADAssessment | OMSGallery/ADAssessment | Active Directory assessment |

## Ejemplos de Queries KQL

### CPU alto en las ultimas 24 horas
```kusto
Perf
| where TimeGenerated > ago(24h)
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize AvgCPU = avg(CounterValue) by Computer, bin(TimeGenerated, 1h)
| where AvgCPU > 80
| order by AvgCPU desc
```

### Errores en logs de aplicacion
```kusto
AppTraces
| where TimeGenerated > ago(1h)
| where SeverityLevel >= 3
| summarize ErrorCount = count() by AppRoleName, Message
| order by ErrorCount desc
| take 10
```

### Eventos de seguridad
```kusto
SecurityEvent
| where TimeGenerated > ago(24h)
| where EventID in (4625, 4648, 4672)
| summarize count() by EventID, Account, Computer
| order by count_ desc
```

## Costos

El pricing de Log Analytics se basa en:

1. **Ingestion**: ~$2.30/GB (varia por region)
2. **Retencion**: Gratis hasta 30 dias, luego ~$0.10/GB/mes
3. **Sentinel**: Adicional si se usa SecurityInsights

### Tips para reducir costos:
- Filtrar logs innecesarios antes de ingerir
- Usar transformaciones en DCR para reducir volumen
- Ajustar retencion segun necesidad
- Usar sampling para logs de alto volumen

## Recursos Creados

- `azurerm_log_analytics_workspace.this` - El workspace
- `azurerm_log_analytics_solution.this` - Solutions (por cada solution)
- `azurerm_monitor_data_collection_rule.this` - DCR (opcional)
- `azurerm_monitor_action_group.this` - Action Group (opcional)

## Arquitectura de Monitoreo

```
┌─────────────────────────────────────────────────────────────────┐
│                    Log Analytics Workspace                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Solutions  │  │     DCR      │  │ Action Group │          │
│  │  - VMInsights│  │ - Syslog     │  │ - Email      │          │
│  │  - Sentinel  │  │ - Perf       │  │ - SMS        │          │
│  │  - Container │  │ - Custom     │  │ - Webhook    │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└────────────────────────────┬────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│  VMs (AMA)    │  │  Azure PaaS   │  │   Apps        │
│  - Syslog     │  │  - Diagnostic │  │  - App        │
│  - Perf       │  │    Settings   │  │    Insights   │
│  - Events     │  │               │  │               │
└───────────────┘  └───────────────┘  └───────────────┘
```
