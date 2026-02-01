# Modulos Terraform para Azure

Coleccion de modulos reutilizables de Terraform para desplegar recursos de Azure siguiendo las mejores practicas.

## Modulos Disponibles

| Modulo | Descripcion |
|--------|-------------|
| [resource-group](./modules/resource-group) | Resource Groups con soporte para locks |
| [virtual-network](./modules/virtual-network) | Virtual Networks con DDoS y diagnosticos |
| [subnet](./modules/subnet) | Subnets con service endpoints y delegations |
| [network-security-group](./modules/network-security-group) | NSGs con reglas dinamicas |
| [storage-account](./modules/storage-account) | Storage Accounts con containers y file shares |
| [key-vault](./modules/key-vault) | Key Vaults con RBAC y network ACLs |
| [virtual-machine-linux](./modules/virtual-machine-linux) | VMs Linux con discos y extensiones |
| [log-analytics-workspace](./modules/log-analytics-workspace) | Log Analytics con solutions y DCR |

## Requisitos

- Terraform >= 1.5.0
- Azure Provider >= 3.80
- Azure CLI o Service Principal configurado

## Uso Rapido

```hcl
module "resource_group" {
  source = "./modules/resource-group"

  name     = "rg-mi-proyecto-dev"
  location = "westeurope"
  tags = {
    Environment = "dev"
    Project     = "mi-proyecto"
  }
}

module "vnet" {
  source = "./modules/virtual-network"

  name                = "vnet-mi-proyecto-dev"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = ["10.0.0.0/16"]
}

module "subnet" {
  source = "./modules/subnet"

  name                 = "snet-web"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

## Ejemplo Completo

Ver el directorio [examples/complete](./examples/complete) para un ejemplo de infraestructura completa que incluye:

- Resource Group
- Virtual Network con multiples subnets
- Network Security Groups
- Storage Account
- Key Vault
- Linux Virtual Machine
- Log Analytics Workspace

```bash
cd examples/complete
terraform init
terraform plan
terraform apply
```

## Estructura del Proyecto

```
terraform/
├── modules/
│   ├── resource-group/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── virtual-network/
│   ├── subnet/
│   ├── network-security-group/
│   ├── storage-account/
│   ├── key-vault/
│   ├── virtual-machine-linux/
│   └── log-analytics-workspace/
├── examples/
│   └── complete/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── README.md
```

## Convenciones

### Nomenclatura
Los modulos siguen las convenciones de nomenclatura de Azure:
- `rg-{proyecto}-{entorno}` - Resource Groups
- `vnet-{proyecto}-{entorno}` - Virtual Networks
- `snet-{proyecto}-{tier}-{entorno}` - Subnets
- `nsg-{proyecto}-{tier}-{entorno}` - Network Security Groups
- `st{proyecto}{entorno}001` - Storage Accounts
- `kv-{proyecto}-{entorno}` - Key Vaults
- `vm-{proyecto}-{rol}-{entorno}` - Virtual Machines
- `law-{proyecto}-{entorno}` - Log Analytics Workspaces

### Tags
Todos los modulos soportan tags personalizados y aplican tags por defecto:

```hcl
default_tags = {
  ManagedBy = "Terraform"
}
```

### Seguridad
- TLS 1.2 minimo para Storage Accounts
- RBAC habilitado por defecto en Key Vault
- Purge protection habilitado en Key Vault
- Diagnostic settings configurables para monitoreo

## Contribuir

1. Crear una rama desde `main`
2. Realizar cambios siguiendo las convenciones
3. Ejecutar `terraform fmt` y `terraform validate`
4. Crear Pull Request

## Licencia

MIT
