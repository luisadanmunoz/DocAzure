# Azure Storage Account Module

Modulo de Terraform para crear Storage Accounts en Azure con soporte para containers, file shares, network rules, versionado y diagnosticos.

## Uso Basico

```hcl
module "storage" {
  source = "../../modules/storage-account"

  name                = "stmiproyectodev001"
  resource_group_name = "rg-mi-proyecto-dev"
  location            = "westeurope"
}
```

## Uso con Containers y File Shares

```hcl
module "storage" {
  source = "../../modules/storage-account"

  name                     = "stempresaprod001"
  resource_group_name      = "rg-storage-prod"
  location                 = "westeurope"
  account_tier             = "Standard"
  account_replication_type = "GRS"  # Geo-redundante

  # Blob Containers
  containers = [
    {
      name        = "documentos"
      access_type = "private"
    },
    {
      name        = "imagenes"
      access_type = "blob"  # Acceso anonimo a blobs
    },
    {
      name        = "backups"
      access_type = "private"
    }
  ]

  # File Shares para SMB
  file_shares = [
    {
      name        = "compartido"
      quota       = 100  # GB
      access_tier = "TransactionOptimized"
    },
    {
      name        = "archivos-frios"
      quota       = 500
      access_tier = "Cool"
    }
  ]

  tags = {
    Environment = "production"
    Department  = "IT"
  }
}
```

## Uso con Network Rules (Firewall)

```hcl
module "storage_seguro" {
  source = "../../modules/storage-account"

  name                          = "stsegurodatos001"
  resource_group_name           = "rg-storage-prod"
  location                      = "westeurope"
  public_network_access_enabled = true  # Necesario para aplicar reglas

  # Habilitar firewall
  enable_network_rules   = true
  network_default_action = "Deny"  # Denegar por defecto
  network_bypass         = ["AzureServices", "Logging", "Metrics"]

  # IPs permitidas
  network_ip_rules = [
    "203.0.113.0/24",     # Oficina principal
    "198.51.100.50"       # IP especifica
  ]

  # Subnets permitidas (requiere Service Endpoint)
  network_subnet_ids = [
    module.subnet_app.id,
    module.subnet_web.id
  ]

  tags = {
    SecurityLevel = "high"
  }
}
```

## Uso con Blob Versioning y Soft Delete

```hcl
module "storage_protegido" {
  source = "../../modules/storage-account"

  name                     = "stprotegido001"
  resource_group_name      = "rg-storage-prod"
  location                 = "westeurope"
  account_replication_type = "RAGRS"  # Read-access geo-redundant

  # Proteccion de datos
  enable_blob_properties        = true
  blob_versioning_enabled       = true   # Mantener versiones anteriores
  blob_change_feed_enabled      = true   # Registro de cambios
  blob_last_access_time_enabled = true   # Para lifecycle policies
  blob_delete_retention_days    = 30     # Soft delete blobs
  container_delete_retention_days = 30   # Soft delete containers

  containers = [
    {
      name        = "datos-criticos"
      access_type = "private"
    }
  ]
}
```

## Uso con Managed Identity

```hcl
module "storage_identity" {
  source = "../../modules/storage-account"

  name                = "stconidentidad001"
  resource_group_name = "rg-storage-prod"
  location            = "westeurope"

  # System Assigned Identity
  identity_type = "SystemAssigned"

  # O User Assigned Identity
  # identity_type = "UserAssigned"
  # identity_ids  = [azurerm_user_assigned_identity.storage.id]
}

# Asignar rol a la identidad
resource "azurerm_role_assignment" "storage_blob" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.storage_identity.identity[0].principal_id
}
```

## Uso con Diagnosticos

```hcl
module "storage_monitoreado" {
  source = "../../modules/storage-account"

  name                       = "stmonitoreado001"
  resource_group_name        = "rg-storage-prod"
  location                   = "westeurope"
  log_analytics_workspace_id = module.log_analytics.id  # Habilita diagnosticos

  containers = [
    {
      name        = "logs"
      access_type = "private"
    }
  ]
}
```

## Inputs

| Nombre | Descripcion | Tipo | Default | Requerido |
|--------|-------------|------|---------|-----------|
| `name` | Nombre (3-24 caracteres, minusculas y numeros) | `string` | - | Si |
| `resource_group_name` | Nombre del Resource Group | `string` | - | Si |
| `location` | Region de Azure | `string` | - | Si |
| `account_tier` | Tier: Standard o Premium | `string` | `"Standard"` | No |
| `account_replication_type` | Tipo de replicacion | `string` | `"LRS"` | No |
| `account_kind` | Tipo de cuenta | `string` | `"StorageV2"` | No |
| `access_tier` | Tier de acceso: Hot o Cool | `string` | `"Hot"` | No |
| `min_tls_version` | Version minima TLS | `string` | `"TLS1_2"` | No |
| `https_traffic_only_enabled` | Solo trafico HTTPS | `bool` | `true` | No |
| `shared_access_key_enabled` | Permitir Shared Keys | `bool` | `true` | No |
| `public_network_access_enabled` | Acceso desde red publica | `bool` | `true` | No |

### Blob Properties

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `enable_blob_properties` | Habilitar configuracion blob | `bool` | `true` |
| `blob_versioning_enabled` | Versionado de blobs | `bool` | `false` |
| `blob_change_feed_enabled` | Change feed | `bool` | `false` |
| `blob_last_access_time_enabled` | Tracking ultimo acceso | `bool` | `false` |
| `blob_delete_retention_days` | Dias soft delete blobs | `number` | `7` |
| `container_delete_retention_days` | Dias soft delete containers | `number` | `7` |

### Network Rules

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `enable_network_rules` | Habilitar firewall | `bool` | `false` |
| `network_default_action` | Accion por defecto | `string` | `"Deny"` |
| `network_bypass` | Servicios que bypasean | `list(string)` | `["AzureServices", "Logging", "Metrics"]` |
| `network_ip_rules` | IPs/CIDRs permitidos | `list(string)` | `[]` |
| `network_subnet_ids` | Subnets permitidas | `list(string)` | `[]` |

### Containers y File Shares

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `containers` | Lista de containers | `list(object)` | `[]` |
| `file_shares` | Lista de file shares | `list(object)` | `[]` |

## Outputs

| Nombre | Descripcion |
|--------|-------------|
| `id` | ID del Storage Account |
| `name` | Nombre del Storage Account |
| `primary_blob_endpoint` | Endpoint de blob |
| `primary_file_endpoint` | Endpoint de files |
| `primary_access_key` | Clave de acceso primaria (sensitive) |
| `secondary_access_key` | Clave de acceso secundaria (sensitive) |
| `primary_connection_string` | Connection string (sensitive) |
| `identity` | Identidad del Storage Account |
| `container_ids` | IDs de containers creados |
| `file_share_ids` | IDs de file shares creados |

## Tipos de Replicacion

| Tipo | Descripcion | Disponibilidad | Durabilidad |
|------|-------------|----------------|-------------|
| `LRS` | Locally Redundant | 1 datacenter | 11 9s |
| `ZRS` | Zone Redundant | 3 zonas | 12 9s |
| `GRS` | Geo Redundant | 2 regiones | 16 9s |
| `GZRS` | Geo-Zone Redundant | 3 zonas + 1 region | 16 9s |
| `RAGRS` | Read-Access GRS | 2 regiones (lectura) | 16 9s |
| `RAGZRS` | Read-Access GZRS | 3 zonas + 1 region (lectura) | 16 9s |

## Tipos de Cuenta

| Tipo | Descripcion | Casos de Uso |
|------|-------------|--------------|
| `StorageV2` | Proposito general v2 | Recomendado para la mayoria |
| `BlobStorage` | Solo blobs | Blobs legacy |
| `BlockBlobStorage` | Premium blobs | Alto rendimiento |
| `FileStorage` | Premium files | SMB de alto rendimiento |
| `Storage` | Proposito general v1 | Legacy |

## Access Tiers

| Tier | Costo Almacenamiento | Costo Acceso | Caso de Uso |
|------|---------------------|--------------|-------------|
| Hot | Alto | Bajo | Datos accedidos frecuentemente |
| Cool | Medio | Medio | Datos accedidos ocasionalmente (30+ dias) |
| Archive | Bajo | Alto | Datos raramente accedidos (180+ dias) |

## Ejemplo con Private Endpoint

```hcl
# Storage Account
module "storage" {
  source = "../../modules/storage-account"

  name                          = "stprivado001"
  resource_group_name           = "rg-storage-prod"
  location                      = "westeurope"
  public_network_access_enabled = false  # Deshabilitar acceso publico

  containers = [
    {
      name        = "datos"
      access_type = "private"
    }
  ]
}

# Private Endpoint para Blob
resource "azurerm_private_endpoint" "blob" {
  name                = "pep-storage-blob"
  location            = "westeurope"
  resource_group_name = "rg-storage-prod"
  subnet_id           = module.subnet_pep.id

  private_service_connection {
    name                           = "psc-storage-blob"
    private_connection_resource_id = module.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}
```

## Recursos Creados

- `azurerm_storage_account.this` - El Storage Account
- `azurerm_storage_container.this` - Containers (por cada container)
- `azurerm_storage_share.this` - File Shares (por cada share)
- `azurerm_monitor_diagnostic_setting.blob` - Diagnosticos (opcional)

## Buenas Practicas de Seguridad

1. **Siempre usar HTTPS**: `https_traffic_only_enabled = true`
2. **TLS 1.2 minimo**: `min_tls_version = "TLS1_2"`
3. **Restringir acceso de red**: Usar network rules o private endpoints
4. **Habilitar soft delete**: Para recuperacion ante borrados accidentales
5. **Usar RBAC**: Preferir roles sobre shared keys
6. **Monitorear**: Habilitar diagnosticos para auditar accesos
