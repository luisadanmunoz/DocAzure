# Azure Subnet Module

Modulo de Terraform para crear Subnets en Azure con soporte para Service Endpoints, Delegations, Private Endpoints y asociacion con NSG/Route Tables.

## Uso Basico

```hcl
module "subnet" {
  source = "../../modules/subnet"

  name                 = "snet-web-dev"
  resource_group_name  = "rg-networking-dev"
  virtual_network_name = "vnet-principal-dev"
  address_prefixes     = ["10.0.1.0/24"]
}
```

## Uso con Service Endpoints

```hcl
module "subnet_app" {
  source = "../../modules/subnet"

  name                 = "snet-app-prod"
  resource_group_name  = "rg-networking-prod"
  virtual_network_name = "vnet-principal-prod"
  address_prefixes     = ["10.0.2.0/24"]

  # Habilitar acceso directo a servicios PaaS
  service_endpoints = [
    "Microsoft.Storage",      # Azure Storage
    "Microsoft.Sql",          # Azure SQL
    "Microsoft.KeyVault",     # Key Vault
    "Microsoft.ServiceBus",   # Service Bus
    "Microsoft.EventHub"      # Event Hub
  ]
}
```

## Uso con Delegations (Azure Services)

```hcl
# Subnet para Azure Container Instances
module "subnet_aci" {
  source = "../../modules/subnet"

  name                 = "snet-aci-dev"
  resource_group_name  = "rg-containers-dev"
  virtual_network_name = "vnet-principal-dev"
  address_prefixes     = ["10.0.10.0/24"]

  delegations = [
    {
      name                       = "aci-delegation"
      service_delegation_name    = "Microsoft.ContainerInstance/containerGroups"
      service_delegation_actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  ]
}

# Subnet para Azure App Service
module "subnet_webapp" {
  source = "../../modules/subnet"

  name                 = "snet-webapp-dev"
  resource_group_name  = "rg-webapp-dev"
  virtual_network_name = "vnet-principal-dev"
  address_prefixes     = ["10.0.11.0/24"]

  delegations = [
    {
      name                       = "webapp-delegation"
      service_delegation_name    = "Microsoft.Web/serverFarms"
      service_delegation_actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  ]
}

# Subnet para Azure Database for PostgreSQL Flexible Server
module "subnet_postgres" {
  source = "../../modules/subnet"

  name                 = "snet-postgres-dev"
  resource_group_name  = "rg-database-dev"
  virtual_network_name = "vnet-principal-dev"
  address_prefixes     = ["10.0.12.0/24"]

  delegations = [
    {
      name                       = "postgres-delegation"
      service_delegation_name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      service_delegation_actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  ]
}
```

## Uso con NSG y Route Table

```hcl
module "subnet_dmz" {
  source = "../../modules/subnet"

  name                 = "snet-dmz-prod"
  resource_group_name  = "rg-networking-prod"
  virtual_network_name = "vnet-principal-prod"
  address_prefixes     = ["10.0.100.0/24"]

  # Asociar NSG para seguridad
  network_security_group_id = module.nsg_dmz.id

  # Asociar Route Table para enrutamiento personalizado
  route_table_id = azurerm_route_table.firewall.id

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault"
  ]
}
```

## Uso para Private Endpoints

```hcl
module "subnet_private_endpoints" {
  source = "../../modules/subnet"

  name                 = "snet-pep-prod"
  resource_group_name  = "rg-networking-prod"
  virtual_network_name = "vnet-principal-prod"
  address_prefixes     = ["10.0.200.0/24"]

  # Configuracion especifica para Private Endpoints
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = false
}
```

## Inputs

| Nombre | Descripcion | Tipo | Default | Requerido |
|--------|-------------|------|---------|-----------|
| `name` | Nombre de la Subnet (2-80 caracteres) | `string` | - | Si |
| `resource_group_name` | Nombre del Resource Group | `string` | - | Si |
| `virtual_network_name` | Nombre de la VNet | `string` | - | Si |
| `address_prefixes` | Lista de prefijos CIDR | `list(string)` | - | Si |
| `service_endpoints` | Service Endpoints a habilitar | `list(string)` | `[]` | No |
| `delegations` | Delegations para servicios Azure | `list(object)` | `[]` | No |
| `private_endpoint_network_policies` | Politica para Private Endpoints | `string` | `"Disabled"` | No |
| `private_link_service_network_policies_enabled` | Politicas para Private Link | `bool` | `true` | No |
| `network_security_group_id` | ID del NSG a asociar | `string` | `null` | No |
| `route_table_id` | ID de la Route Table a asociar | `string` | `null` | No |

## Outputs

| Nombre | Descripcion |
|--------|-------------|
| `id` | ID de la Subnet |
| `name` | Nombre de la Subnet |
| `address_prefixes` | Prefijos de direcciones |
| `virtual_network_name` | Nombre de la VNet asociada |
| `resource_group_name` | Resource Group de la Subnet |

## Service Endpoints Disponibles

| Service Endpoint | Servicio Azure |
|-----------------|----------------|
| `Microsoft.AzureActiveDirectory` | Azure AD Domain Services |
| `Microsoft.AzureCosmosDB` | Cosmos DB |
| `Microsoft.ContainerRegistry` | Container Registry |
| `Microsoft.EventHub` | Event Hubs |
| `Microsoft.KeyVault` | Key Vault |
| `Microsoft.ServiceBus` | Service Bus |
| `Microsoft.Sql` | Azure SQL, Synapse |
| `Microsoft.Storage` | Storage Accounts |
| `Microsoft.Web` | App Service, Functions |

## Delegations Comunes

| Servicio | Service Delegation Name |
|----------|------------------------|
| Container Instances | `Microsoft.ContainerInstance/containerGroups` |
| App Service | `Microsoft.Web/serverFarms` |
| Azure Functions | `Microsoft.Web/serverFarms` |
| PostgreSQL Flexible | `Microsoft.DBforPostgreSQL/flexibleServers` |
| MySQL Flexible | `Microsoft.DBforMySQL/flexibleServers` |
| Azure NetApp Files | `Microsoft.NetApp/volumes` |
| API Management | `Microsoft.ApiManagement/service` |
| Databricks | `Microsoft.Databricks/workspaces` |

## Subnets Especiales de Azure

Algunas subnets requieren nombres especificos:

| Nombre Requerido | Uso |
|-----------------|-----|
| `GatewaySubnet` | VPN Gateway / ExpressRoute |
| `AzureFirewallSubnet` | Azure Firewall |
| `AzureBastionSubnet` | Azure Bastion |
| `RouteServerSubnet` | Azure Route Server |

```hcl
# Ejemplo: GatewaySubnet
module "gateway_subnet" {
  source = "../../modules/subnet"

  name                 = "GatewaySubnet"  # Nombre obligatorio
  resource_group_name  = "rg-networking-prod"
  virtual_network_name = "vnet-hub-prod"
  address_prefixes     = ["10.0.0.0/27"]  # Minimo /27
}

# Ejemplo: AzureBastionSubnet
module "bastion_subnet" {
  source = "../../modules/subnet"

  name                 = "AzureBastionSubnet"  # Nombre obligatorio
  resource_group_name  = "rg-networking-prod"
  virtual_network_name = "vnet-hub-prod"
  address_prefixes     = ["10.0.1.0/26"]  # Minimo /26
}
```

## Tamanos de Subnet Recomendados

| Caso de Uso | CIDR | Hosts | Notas |
|-------------|------|-------|-------|
| GatewaySubnet | /27 | 27 | Minimo recomendado |
| AzureBastionSubnet | /26 | 59 | Minimo /26 |
| AzureFirewallSubnet | /26 | 59 | Minimo /26 |
| Web Tier | /24 | 251 | Para VMs o VMSS |
| App Tier | /24 | 251 | Para VMs o containers |
| Database Tier | /24 | 251 | Para SQL, PostgreSQL |
| Private Endpoints | /24 | 251 | Cada PE usa 1 IP |

> **Nota**: Azure reserva 5 IPs por subnet (primeras 4 y ultima).

## Recursos Creados

- `azurerm_subnet.this` - La Subnet
- `azurerm_subnet_network_security_group_association.this` - Asociacion con NSG (opcional)
- `azurerm_subnet_route_table_association.this` - Asociacion con Route Table (opcional)

## Ejemplo Completo de Topologia

```hcl
# Virtual Network
module "vnet" {
  source = "../../modules/virtual-network"

  name                = "vnet-empresa-prod"
  resource_group_name = "rg-networking-prod"
  location            = "westeurope"
  address_space       = ["10.0.0.0/16"]
}

# Subnet para Web (con NSG)
module "subnet_web" {
  source = "../../modules/subnet"

  name                      = "snet-web-prod"
  resource_group_name       = "rg-networking-prod"
  virtual_network_name      = module.vnet.name
  address_prefixes          = ["10.0.10.0/24"]
  network_security_group_id = module.nsg_web.id
  service_endpoints         = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

# Subnet para App (con delegation para App Service)
module "subnet_app" {
  source = "../../modules/subnet"

  name                 = "snet-app-prod"
  resource_group_name  = "rg-networking-prod"
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.20.0/24"]

  delegations = [
    {
      name                       = "appservice"
      service_delegation_name    = "Microsoft.Web/serverFarms"
      service_delegation_actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  ]
}

# Subnet para Private Endpoints
module "subnet_pep" {
  source = "../../modules/subnet"

  name                              = "snet-pep-prod"
  resource_group_name               = "rg-networking-prod"
  virtual_network_name              = module.vnet.name
  address_prefixes                  = ["10.0.200.0/24"]
  private_endpoint_network_policies = "Disabled"
}
```
