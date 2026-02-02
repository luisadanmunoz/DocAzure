# Azure Network Security Group Module

Modulo de Terraform para crear Network Security Groups (NSG) en Azure con reglas de seguridad dinamicas y configuracion de diagnosticos.

## Uso Basico

```hcl
module "nsg" {
  source = "../../modules/network-security-group"

  name                = "nsg-web-dev"
  resource_group_name = "rg-networking-dev"
  location            = "westeurope"
}
```

## Uso con Reglas de Seguridad

```hcl
module "nsg_web" {
  source = "../../modules/network-security-group"

  name                = "nsg-web-prod"
  resource_group_name = "rg-networking-prod"
  location            = "westeurope"

  security_rules = [
    {
      name                       = "AllowHTTPS"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Permitir trafico HTTPS desde Internet"
    },
    {
      name                       = "AllowHTTP"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Permitir trafico HTTP (redirige a HTTPS)"
    },
    {
      name                       = "DenyAllInbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Denegar todo el trafico no permitido explicitamente"
    }
  ]

  tags = {
    Environment = "production"
    Tier        = "web"
  }
}
```

## Uso con Rangos de Puertos Multiples

```hcl
module "nsg_app" {
  source = "../../modules/network-security-group"

  name                = "nsg-app-prod"
  resource_group_name = "rg-networking-prod"
  location            = "westeurope"

  security_rules = [
    {
      name                       = "AllowAppPorts"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "8443", "9090"]  # Multiples puertos
      source_address_prefix      = "10.0.1.0/24"             # Solo desde subnet web
      destination_address_prefix = "*"
      description                = "Permitir puertos de aplicacion desde web tier"
    },
    {
      name                       = "AllowManagement"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefixes    = ["10.0.100.0/24", "172.16.0.0/24"]  # Multiples origenes
      destination_address_prefix = "*"
      description                = "Permitir SSH/RDP desde redes de gestion"
    }
  ]
}
```

## Uso con Service Tags

```hcl
module "nsg_backend" {
  source = "../../modules/network-security-group"

  name                = "nsg-backend-prod"
  resource_group_name = "rg-networking-prod"
  location            = "westeurope"

  security_rules = [
    {
      name                       = "AllowAzureLoadBalancer"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"  # Service Tag
      destination_address_prefix = "*"
      description                = "Permitir health probes del Load Balancer"
    },
    {
      name                       = "AllowAzureBastion"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
      description                = "Permitir conexiones desde Bastion"
    },
    {
      name                       = "AllowStorageOutbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "Storage.WestEurope"  # Service Tag regional
      description                = "Permitir acceso a Storage en West Europe"
    }
  ]
}
```

## Uso con Diagnosticos

```hcl
module "nsg_monitoreado" {
  source = "../../modules/network-security-group"

  name                       = "nsg-critico-prod"
  resource_group_name        = "rg-networking-prod"
  location                   = "westeurope"
  log_analytics_workspace_id = module.log_analytics.id

  security_rules = [
    # ... reglas ...
  ]
}
```

## Inputs

| Nombre | Descripcion | Tipo | Default | Requerido |
|--------|-------------|------|---------|-----------|
| `name` | Nombre del NSG (2-80 caracteres) | `string` | - | Si |
| `resource_group_name` | Nombre del Resource Group | `string` | - | Si |
| `location` | Region de Azure | `string` | - | Si |
| `security_rules` | Lista de reglas de seguridad | `list(object)` | `[]` | No |
| `log_analytics_workspace_id` | ID para diagnosticos | `string` | `null` | No |
| `tags` | Tags adicionales | `map(string)` | `{}` | No |
| `default_tags` | Tags por defecto | `map(string)` | `{ManagedBy = "Terraform"}` | No |

### Estructura de security_rules

```hcl
security_rules = [
  {
    name                         = string           # Requerido
    priority                     = number           # Requerido: 100-4096
    direction                    = string           # Requerido: "Inbound" o "Outbound"
    access                       = string           # Requerido: "Allow" o "Deny"
    protocol                     = string           # Requerido: "Tcp", "Udp", "Icmp", "*"
    source_port_range            = string           # Opcional: "80", "*", "1024-65535"
    source_port_ranges           = list(string)     # Opcional: ["80", "443"]
    destination_port_range       = string           # Opcional
    destination_port_ranges      = list(string)     # Opcional
    source_address_prefix        = string           # Opcional: CIDR, Service Tag, "*"
    source_address_prefixes      = list(string)     # Opcional
    destination_address_prefix   = string           # Opcional
    destination_address_prefixes = list(string)     # Opcional
    description                  = string           # Opcional
  }
]
```

## Outputs

| Nombre | Descripcion |
|--------|-------------|
| `id` | ID del Network Security Group |
| `name` | Nombre del NSG |
| `location` | Region del NSG |
| `resource_group_name` | Resource Group del NSG |
| `security_rules` | Mapa de reglas configuradas |

## Service Tags Comunes

| Service Tag | Descripcion |
|-------------|-------------|
| `Internet` | Todo el espacio de IPs publicas |
| `VirtualNetwork` | Espacio de direcciones de la VNet + peered |
| `AzureLoadBalancer` | Health probes del Load Balancer |
| `AzureTrafficManager` | IPs de Traffic Manager |
| `Storage` | Azure Storage (global) |
| `Storage.WestEurope` | Storage en region especifica |
| `Sql` | Azure SQL (global) |
| `AzureCosmosDB` | Cosmos DB |
| `AzureKeyVault` | Key Vault |
| `EventHub` | Event Hubs |
| `ServiceBus` | Service Bus |
| `AzureActiveDirectory` | Azure AD |
| `AzureMonitor` | Azure Monitor |
| `AzureBackup` | Azure Backup |
| `GatewayManager` | VPN/Application Gateway management |
| `AzureBastionSubnet` | Azure Bastion |

## Reglas por Defecto de Azure

Azure incluye reglas implicitas que no se pueden eliminar:

### Inbound
| Prioridad | Nombre | Origen | Destino | Accion |
|-----------|--------|--------|---------|--------|
| 65000 | AllowVnetInBound | VirtualNetwork | VirtualNetwork | Allow |
| 65001 | AllowAzureLoadBalancerInBound | AzureLoadBalancer | * | Allow |
| 65500 | DenyAllInBound | * | * | Deny |

### Outbound
| Prioridad | Nombre | Origen | Destino | Accion |
|-----------|--------|--------|---------|--------|
| 65000 | AllowVnetOutBound | VirtualNetwork | VirtualNetwork | Allow |
| 65001 | AllowInternetOutBound | * | Internet | Allow |
| 65500 | DenyAllOutBound | * | * | Deny |

## Plantillas de NSG por Tier

### NSG para Web Tier

```hcl
security_rules = [
  {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  },
  {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
]
```

### NSG para App Tier

```hcl
security_rules = [
  {
    name                       = "AllowFromWebTier"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "8443"]
    source_address_prefix      = "10.0.1.0/24"  # Web tier subnet
    destination_address_prefix = "*"
  },
  {
    name                       = "AllowHealthProbes"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
]
```

### NSG para Database Tier

```hcl
security_rules = [
  {
    name                       = "AllowSQLFromAppTier"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"  # SQL Server
    source_address_prefix      = "10.0.2.0/24"  # App tier subnet
    destination_address_prefix = "*"
  },
  {
    name                       = "AllowPostgresFromAppTier"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"  # PostgreSQL
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "*"
  },
  {
    name                       = "DenyInternetInbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
]
```

## Recursos Creados

- `azurerm_network_security_group.this` - El NSG
- `azurerm_network_security_rule.this` - Reglas de seguridad (por cada regla)
- `azurerm_monitor_diagnostic_setting.this` - Diagnosticos (opcional)

## Logs de Diagnostico

Cuando se habilitan diagnosticos, se capturan:

- **NetworkSecurityGroupEvent** - Eventos de NSG (reglas aplicadas)
- **NetworkSecurityGroupRuleCounter** - Contadores de reglas (hits por regla)

Estos logs son utiles para:
- Auditar trafico permitido/denegado
- Troubleshooting de conectividad
- Analisis de seguridad
- Cumplimiento normativo
