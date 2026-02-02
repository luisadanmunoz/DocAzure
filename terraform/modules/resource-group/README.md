# Azure Resource Group Module

Modulo de Terraform para crear y gestionar Resource Groups en Azure con soporte para tags y management locks.

## Uso Basico

```hcl
module "resource_group" {
  source = "../../modules/resource-group"

  name     = "rg-mi-proyecto-dev"
  location = "westeurope"
}
```

## Uso con Lock de Proteccion

```hcl
module "resource_group" {
  source = "../../modules/resource-group"

  name        = "rg-mi-proyecto-prod"
  location    = "westeurope"
  enable_lock = true
  lock_level  = "CanNotDelete"
  lock_notes  = "Recurso critico de produccion - no eliminar"

  tags = {
    Environment = "production"
    CostCenter  = "IT-001"
    Owner       = "platform-team@empresa.com"
  }
}
```

## Uso con Tags Personalizados

```hcl
module "resource_group" {
  source = "../../modules/resource-group"

  name     = "rg-aplicacion-staging"
  location = "northeurope"

  # Tags por defecto que se aplican a todos los recursos
  default_tags = {
    ManagedBy   = "Terraform"
    Repository  = "infraestructura-azure"
    LastUpdated = "2024-01-15"
  }

  # Tags especificos para este resource group
  tags = {
    Environment = "staging"
    Application = "mi-aplicacion"
    Team        = "desarrollo"
  }
}
```

## Inputs

| Nombre | Descripcion | Tipo | Default | Requerido |
|--------|-------------|------|---------|-----------|
| `name` | Nombre del Resource Group (1-90 caracteres alfanumericos) | `string` | - | Si |
| `location` | Region de Azure | `string` | `"westeurope"` | No |
| `tags` | Tags adicionales para el Resource Group | `map(string)` | `{}` | No |
| `default_tags` | Tags por defecto aplicados a todos los recursos | `map(string)` | `{ManagedBy = "Terraform"}` | No |
| `enable_lock` | Habilitar lock de proteccion | `bool` | `false` | No |
| `lock_level` | Nivel del lock: `CanNotDelete` o `ReadOnly` | `string` | `"CanNotDelete"` | No |
| `lock_notes` | Descripcion del motivo del lock | `string` | `"Resource Group protegido..."` | No |

## Outputs

| Nombre | Descripcion |
|--------|-------------|
| `id` | ID completo del Resource Group |
| `name` | Nombre del Resource Group |
| `location` | Region donde se creo el Resource Group |
| `tags` | Tags aplicados al Resource Group |

## Notas

### Convenciones de Nomenclatura
Se recomienda seguir el patron: `rg-{proyecto}-{entorno}`

Ejemplos:
- `rg-webapp-dev`
- `rg-datalake-prod`
- `rg-shared-services-hub`

### Management Locks
- **CanNotDelete**: Permite modificar recursos pero no eliminarlos
- **ReadOnly**: No permite modificar ni eliminar recursos

> **Importante**: Los locks se heredan a los recursos hijos. Un lock en el Resource Group afecta a todos los recursos dentro de el.

### Regiones de Azure Recomendadas
| Region | Codigo |
|--------|--------|
| West Europe | `westeurope` |
| North Europe | `northeurope` |
| East US | `eastus` |
| East US 2 | `eastus2` |
| West US 2 | `westus2` |

## Recursos Creados

- `azurerm_resource_group.this` - El Resource Group
- `azurerm_management_lock.this` - Lock de proteccion (si `enable_lock = true`)

## Dependencias

Este modulo no tiene dependencias de otros modulos.

## Ejemplo de Integracion

```hcl
# Crear el Resource Group
module "rg" {
  source = "../../modules/resource-group"

  name     = "rg-ejemplo-dev"
  location = "westeurope"
}

# Usar el Resource Group en otros modulos
module "vnet" {
  source = "../../modules/virtual-network"

  name                = "vnet-ejemplo-dev"
  resource_group_name = module.rg.name      # Referencia al nombre
  location            = module.rg.location  # Referencia a la ubicacion
  address_space       = ["10.0.0.0/16"]
}
```
