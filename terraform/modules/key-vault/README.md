# Azure Key Vault Module

Modulo de Terraform para crear Key Vaults en Azure con soporte para RBAC, Access Policies, Network ACLs, secrets y diagnosticos.

## Uso Basico

```hcl
module "key_vault" {
  source = "../../modules/key-vault"

  name                = "kv-mi-proyecto-dev"
  resource_group_name = "rg-mi-proyecto-dev"
  location            = "westeurope"
}
```

## Uso con RBAC (Recomendado)

```hcl
module "key_vault" {
  source = "../../modules/key-vault"

  name                      = "kv-empresa-prod"
  resource_group_name       = "rg-security-prod"
  location                  = "westeurope"
  sku_name                  = "standard"
  enable_rbac_authorization = true  # Usar RBAC en lugar de Access Policies
  purge_protection_enabled  = true  # Proteccion contra purga
  soft_delete_retention_days = 90

  tags = {
    Environment = "production"
    Compliance  = "SOC2"
  }
}

# Asignar rol de administrador de secrets
resource "azurerm_role_assignment" "secrets_admin" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Asignar rol de lectura a una aplicacion
resource "azurerm_role_assignment" "app_secrets_reader" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}
```

## Uso con Access Policies (Legacy)

```hcl
module "key_vault" {
  source = "../../modules/key-vault"

  name                      = "kv-legacy-dev"
  resource_group_name       = "rg-mi-proyecto-dev"
  location                  = "westeurope"
  enable_rbac_authorization = false  # Usar Access Policies

  access_policies = [
    {
      object_id          = data.azurerm_client_config.current.object_id
      secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
      key_permissions    = ["Get", "List", "Create", "Delete", "Update"]
    },
    {
      object_id          = azurerm_user_assigned_identity.app.principal_id
      secret_permissions = ["Get", "List"]
      key_permissions    = ["Get", "WrapKey", "UnwrapKey"]
    }
  ]
}
```

## Uso con Network ACLs

```hcl
module "key_vault_seguro" {
  source = "../../modules/key-vault"

  name                          = "kv-seguro-prod"
  resource_group_name           = "rg-security-prod"
  location                      = "westeurope"
  public_network_access_enabled = true  # Necesario para aplicar ACLs

  # Network ACLs
  enable_network_acls    = true
  network_default_action = "Deny"
  network_bypass         = "AzureServices"

  # IPs permitidas
  network_ip_rules = [
    "203.0.113.0/24"  # Oficina
  ]

  # Subnets permitidas (requiere Service Endpoint Microsoft.KeyVault)
  network_subnet_ids = [
    module.subnet_app.id
  ]
}
```

## Uso con Secrets Iniciales

```hcl
module "key_vault" {
  source = "../../modules/key-vault"

  name                      = "kv-app-prod"
  resource_group_name       = "rg-app-prod"
  location                  = "westeurope"
  enable_rbac_authorization = true

  # Crear secrets iniciales
  secrets = [
    {
      name         = "database-connection-string"
      value        = var.db_connection_string
      content_type = "text/plain"
    },
    {
      name            = "api-key"
      value           = var.api_key
      content_type    = "application/json"
      expiration_date = "2025-12-31T23:59:59Z"
    },
    {
      name  = "storage-key"
      value = module.storage.primary_access_key
      tags = {
        Source = "storage-account"
      }
    }
  ]
}
```

## Uso para Disk Encryption

```hcl
module "key_vault_encryption" {
  source = "../../modules/key-vault"

  name                        = "kv-encryption-prod"
  resource_group_name         = "rg-security-prod"
  location                    = "westeurope"
  enabled_for_disk_encryption = true  # Permitir Azure Disk Encryption
  purge_protection_enabled    = true  # Requerido para disk encryption
}
```

## Uso con Diagnosticos

```hcl
module "key_vault" {
  source = "../../modules/key-vault"

  name                       = "kv-auditado-prod"
  resource_group_name        = "rg-security-prod"
  location                   = "westeurope"
  log_analytics_workspace_id = module.log_analytics.id

  # Todos los accesos seran auditados
}
```

## Inputs

| Nombre | Descripcion | Tipo | Default | Requerido |
|--------|-------------|------|---------|-----------|
| `name` | Nombre (3-24 caracteres, alfanumerico) | `string` | - | Si |
| `resource_group_name` | Nombre del Resource Group | `string` | - | Si |
| `location` | Region de Azure | `string` | - | Si |
| `tenant_id` | Tenant ID (default: actual) | `string` | `null` | No |
| `sku_name` | SKU: standard o premium | `string` | `"standard"` | No |

### Configuracion General

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `enabled_for_deployment` | Permitir VMs acceder a certificados | `bool` | `false` |
| `enabled_for_disk_encryption` | Permitir Azure Disk Encryption | `bool` | `false` |
| `enabled_for_template_deployment` | Permitir ARM templates | `bool` | `false` |
| `enable_rbac_authorization` | Usar RBAC | `bool` | `true` |
| `purge_protection_enabled` | Proteccion contra purga | `bool` | `true` |
| `soft_delete_retention_days` | Dias de retencion (7-90) | `number` | `90` |
| `public_network_access_enabled` | Acceso publico | `bool` | `true` |

### Network ACLs

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `enable_network_acls` | Habilitar firewall | `bool` | `false` |
| `network_default_action` | Accion por defecto | `string` | `"Deny"` |
| `network_bypass` | Servicios bypass | `string` | `"AzureServices"` |
| `network_ip_rules` | IPs permitidas | `list(string)` | `[]` |
| `network_subnet_ids` | Subnets permitidas | `list(string)` | `[]` |

### Access Policies

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `access_policies` | Lista de policies | `list(object)` | `[]` |

### Secrets

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `secrets` | Lista de secrets a crear | `list(object)` | `[]` |

## Outputs

| Nombre | Descripcion |
|--------|-------------|
| `id` | ID del Key Vault |
| `name` | Nombre del Key Vault |
| `vault_uri` | URI del Key Vault |
| `tenant_id` | Tenant ID |
| `location` | Region |
| `resource_group_name` | Resource Group |
| `secret_ids` | IDs de secrets creados |
| `secret_versionless_ids` | IDs sin version de secrets |

## Roles RBAC para Key Vault

| Rol | Descripcion | Permisos |
|-----|-------------|----------|
| `Key Vault Administrator` | Control total | Todo |
| `Key Vault Certificates Officer` | Gestionar certificados | Certificados CRUD |
| `Key Vault Crypto Officer` | Gestionar claves | Keys CRUD + operaciones crypto |
| `Key Vault Crypto User` | Usar claves | Encrypt, Decrypt, Wrap, Unwrap |
| `Key Vault Secrets Officer` | Gestionar secrets | Secrets CRUD |
| `Key Vault Secrets User` | Leer secrets | Get, List secrets |
| `Key Vault Reader` | Leer metadata | Read metadata only |

## Permisos de Access Policy

### Secrets
```
Get, List, Set, Delete, Recover, Backup, Restore, Purge
```

### Keys
```
Get, List, Create, Delete, Update, Import, Recover, Backup, Restore,
Decrypt, Encrypt, UnwrapKey, WrapKey, Verify, Sign, Purge,
GetRotationPolicy, SetRotationPolicy, Rotate
```

### Certificates
```
Get, List, Create, Delete, Update, Import, Recover, Backup, Restore,
ManageContacts, GetIssuers, ListIssuers, SetIssuers, DeleteIssuers,
ManageIssuers, Purge
```

## Ejemplo Completo con Private Endpoint

```hcl
# Key Vault con acceso privado
module "key_vault" {
  source = "../../modules/key-vault"

  name                          = "kv-privado-prod"
  resource_group_name           = "rg-security-prod"
  location                      = "westeurope"
  public_network_access_enabled = false
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
}

# Private Endpoint
resource "azurerm_private_endpoint" "kv" {
  name                = "pep-kv-prod"
  location            = "westeurope"
  resource_group_name = "rg-security-prod"
  subnet_id           = module.subnet_pep.id

  private_service_connection {
    name                           = "psc-kv"
    private_connection_resource_id = module.key_vault.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv.id]
  }
}

# DNS Zone
resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = "rg-dns-prod"
}
```

## Recursos Creados

- `azurerm_key_vault.this` - El Key Vault
- `azurerm_monitor_diagnostic_setting.this` - Diagnosticos (opcional)
- `azurerm_key_vault_secret.this` - Secrets (por cada secret)

## Consideraciones de Seguridad

### Purge Protection
- **Recomendacion**: Siempre habilitar en produccion
- Una vez habilitado, no se puede deshabilitar
- Protege contra eliminacion maliciosa/accidental
- Requerido para Azure Disk Encryption

### Soft Delete
- Habilitado por defecto (no se puede deshabilitar)
- Retencion entre 7-90 dias
- Permite recuperar secrets/keys/certificates eliminados

### RBAC vs Access Policies
- **RBAC (Recomendado)**:
  - Gestion centralizada con Azure RBAC
  - Herencia de permisos
  - Auditoria unificada
- **Access Policies**:
  - Legacy, pero aun soportado
  - Mas granular pero mas complejo
  - Maximo 1024 policies por vault

### Logs de Auditoria
Los diagnosticos capturan:
- `AuditEvent` - Todas las operaciones en el vault
- `AzurePolicyEvaluationDetails` - Evaluaciones de policies

## Integracion con Aplicaciones

```hcl
# Ejemplo: App Service accediendo a Key Vault
resource "azurerm_linux_web_app" "app" {
  name                = "webapp-ejemplo"
  # ...

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    # Referencia a secret en Key Vault
    "ConnectionString" = "@Microsoft.KeyVault(SecretUri=${module.key_vault.vault_uri}secrets/database-connection-string/)"
  }
}

# Asignar permiso a la identidad del App Service
resource "azurerm_role_assignment" "app_kv" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}
```
