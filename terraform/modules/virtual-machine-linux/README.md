# Azure Linux Virtual Machine Module

Modulo de Terraform para crear Virtual Machines Linux en Azure con soporte para SSH keys, data disks, managed identity, extensiones y boot diagnostics.

## Uso Basico

```hcl
module "vm" {
  source = "../../modules/virtual-machine-linux"

  name                = "vm-web-dev"
  resource_group_name = "rg-compute-dev"
  location            = "westeurope"
  size                = "Standard_B2s"
  subnet_id           = module.subnet.id

  admin_username = "azureadmin"
  admin_ssh_keys = [file("~/.ssh/id_rsa.pub")]
}
```

## Uso con Ubuntu 22.04 LTS

```hcl
module "vm_ubuntu" {
  source = "../../modules/virtual-machine-linux"

  name                = "vm-app-prod"
  resource_group_name = "rg-compute-prod"
  location            = "westeurope"
  size                = "Standard_D2s_v3"
  subnet_id           = module.subnet_app.id
  zone                = "1"  # Availability Zone

  admin_username                  = "azureadmin"
  disable_password_authentication = true
  admin_ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAA... user@machine"
  ]

  # Ubuntu 22.04 LTS (por defecto)
  source_image_publisher = "Canonical"
  source_image_offer     = "0001-com-ubuntu-server-jammy"
  source_image_sku       = "22_04-lts-gen2"
  source_image_version   = "latest"

  os_disk_storage_account_type = "Premium_LRS"
  os_disk_size_gb              = 64

  tags = {
    Environment = "production"
    Application = "web-server"
  }
}
```

## Uso con Red Hat Enterprise Linux

```hcl
module "vm_rhel" {
  source = "../../modules/virtual-machine-linux"

  name                = "vm-rhel-prod"
  resource_group_name = "rg-compute-prod"
  location            = "westeurope"
  size                = "Standard_D4s_v3"
  subnet_id           = module.subnet_app.id

  admin_username = "azureadmin"
  admin_ssh_keys = [file("~/.ssh/id_rsa.pub")]

  # RHEL 8
  source_image_publisher = "RedHat"
  source_image_offer     = "RHEL"
  source_image_sku       = "8-lvm-gen2"
  source_image_version   = "latest"
}
```

## Uso con Data Disks

```hcl
module "vm_con_discos" {
  source = "../../modules/virtual-machine-linux"

  name                = "vm-database-prod"
  resource_group_name = "rg-database-prod"
  location            = "westeurope"
  size                = "Standard_E4s_v3"
  subnet_id           = module.subnet_db.id
  zone                = "1"

  admin_username = "azureadmin"
  admin_ssh_keys = [file("~/.ssh/id_rsa.pub")]

  # Disco del SO
  os_disk_storage_account_type = "Premium_LRS"
  os_disk_size_gb              = 64
  os_disk_caching              = "ReadWrite"

  # Data disks adicionales
  data_disks = [
    {
      name                 = "vm-database-prod-data01"
      disk_size_gb         = 256
      storage_account_type = "Premium_LRS"
      lun                  = 0
      caching              = "ReadOnly"  # Para datos de lectura frecuente
    },
    {
      name                 = "vm-database-prod-data02"
      disk_size_gb         = 512
      storage_account_type = "Premium_LRS"
      lun                  = 1
      caching              = "None"  # Para logs transaccionales
    },
    {
      name                 = "vm-database-prod-temp"
      disk_size_gb         = 128
      storage_account_type = "StandardSSD_LRS"
      lun                  = 2
      caching              = "ReadWrite"
    }
  ]

  tags = {
    Role = "database"
  }
}
```

## Uso con Managed Identity

```hcl
module "vm_identity" {
  source = "../../modules/virtual-machine-linux"

  name                = "vm-app-prod"
  resource_group_name = "rg-compute-prod"
  location            = "westeurope"
  size                = "Standard_D2s_v3"
  subnet_id           = module.subnet_app.id

  admin_username = "azureadmin"
  admin_ssh_keys = [file("~/.ssh/id_rsa.pub")]

  # System Assigned Identity
  identity_type = "SystemAssigned"
}

# Asignar permisos a la identidad
resource "azurerm_role_assignment" "vm_storage" {
  scope                = module.storage.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = module.vm_identity.principal_id
}

resource "azurerm_role_assignment" "vm_keyvault" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.vm_identity.principal_id
}
```

## Uso con Cloud-Init

```hcl
module "vm_cloudinit" {
  source = "../../modules/virtual-machine-linux"

  name                = "vm-web-prod"
  resource_group_name = "rg-compute-prod"
  location            = "westeurope"
  size                = "Standard_B2s"
  subnet_id           = module.subnet_web.id

  admin_username = "azureadmin"
  admin_ssh_keys = [file("~/.ssh/id_rsa.pub")]

  # Cloud-init para configuracion inicial
  custom_data = base64encode(<<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - nginx
      - docker.io
      - htop
    runcmd:
      - systemctl enable nginx
      - systemctl start nginx
      - usermod -aG docker azureadmin
    EOF
  )
}
```

## Uso con Azure Monitor Agent

```hcl
module "vm_monitoreada" {
  source = "../../modules/virtual-machine-linux"

  name                = "vm-monitoreada-prod"
  resource_group_name = "rg-compute-prod"
  location            = "westeurope"
  size                = "Standard_D2s_v3"
  subnet_id           = module.subnet_app.id

  admin_username = "azureadmin"
  admin_ssh_keys = [file("~/.ssh/id_rsa.pub")]

  identity_type              = "SystemAssigned"  # Requerido para AMA
  enable_azure_monitor_agent = true

  enable_boot_diagnostics            = true
  boot_diagnostics_storage_account_uri = null  # Usar managed storage
}

# Asociar Data Collection Rule
resource "azurerm_monitor_data_collection_rule_association" "vm" {
  name                    = "dcra-${module.vm_monitoreada.name}"
  target_resource_id      = module.vm_monitoreada.id
  data_collection_rule_id = module.log_analytics.data_collection_rule_id
}
```

## Uso con IP Estatica y NSG

```hcl
module "vm_estatica" {
  source = "../../modules/virtual-machine-linux"

  name                = "vm-app-prod"
  resource_group_name = "rg-compute-prod"
  location            = "westeurope"
  size                = "Standard_D2s_v3"
  subnet_id           = module.subnet_app.id

  admin_username = "azureadmin"
  admin_ssh_keys = [file("~/.ssh/id_rsa.pub")]

  # IP privada estatica
  private_ip_address_allocation = "Static"
  private_ip_address            = "10.0.2.10"

  # Asociar NSG a la NIC
  network_security_group_id = module.nsg_app.id
}
```

## Inputs

| Nombre | Descripcion | Tipo | Default | Requerido |
|--------|-------------|------|---------|-----------|
| `name` | Nombre de la VM (2-64 caracteres) | `string` | - | Si |
| `resource_group_name` | Nombre del Resource Group | `string` | - | Si |
| `location` | Region de Azure | `string` | - | Si |
| `size` | Tamano de la VM | `string` | `"Standard_B2s"` | No |
| `zone` | Availability Zone (1, 2, 3) | `string` | `null` | No |
| `subnet_id` | ID de la subnet | `string` | - | Si |

### Autenticacion

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `admin_username` | Usuario administrador | `string` | `"azureadmin"` |
| `admin_password` | Password (si no usa SSH) | `string` | `null` |
| `disable_password_authentication` | Deshabilitar password | `bool` | `true` |
| `admin_ssh_keys` | Lista de claves SSH publicas | `list(string)` | `[]` |

### Imagen

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `source_image_id` | ID de imagen personalizada | `string` | `null` |
| `source_image_publisher` | Publisher | `string` | `"Canonical"` |
| `source_image_offer` | Offer | `string` | `"0001-com-ubuntu-server-jammy"` |
| `source_image_sku` | SKU | `string` | `"22_04-lts-gen2"` |
| `source_image_version` | Version | `string` | `"latest"` |

### Disco del SO

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `os_disk_caching` | Tipo de caching | `string` | `"ReadWrite"` |
| `os_disk_storage_account_type` | Tipo de storage | `string` | `"Premium_LRS"` |
| `os_disk_size_gb` | Tamano en GB | `number` | `null` |
| `disk_encryption_set_id` | ID del Disk Encryption Set | `string` | `null` |

### Data Disks

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `data_disks` | Lista de discos adicionales | `list(object)` | `[]` |

### Identidad

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `identity_type` | Tipo de identidad | `string` | `"SystemAssigned"` |
| `identity_ids` | IDs de User Assigned | `list(string)` | `[]` |

### Extensiones

| Nombre | Descripcion | Tipo | Default |
|--------|-------------|------|---------|
| `enable_azure_monitor_agent` | Instalar AMA | `bool` | `false` |
| `enable_boot_diagnostics` | Boot diagnostics | `bool` | `true` |
| `boot_diagnostics_storage_account_uri` | URI storage | `string` | `null` |

## Outputs

| Nombre | Descripcion |
|--------|-------------|
| `id` | ID de la VM |
| `name` | Nombre de la VM |
| `private_ip_address` | IP privada |
| `public_ip_address` | IP publica (si existe) |
| `virtual_machine_id` | VMID |
| `identity` | Informacion de identidad |
| `principal_id` | Principal ID de la identidad |
| `network_interface_id` | ID de la NIC |
| `admin_username` | Usuario administrador |
| `data_disk_ids` | IDs de data disks |

## Tamanos de VM Comunes

### Proposito General (Serie B, D)
| Tamano | vCPUs | RAM | Caso de Uso |
|--------|-------|-----|-------------|
| Standard_B1s | 1 | 1 GB | Dev/Test pequeno |
| Standard_B2s | 2 | 4 GB | Dev/Test, Web pequeno |
| Standard_B2ms | 2 | 8 GB | Web, pequenas apps |
| Standard_D2s_v3 | 2 | 8 GB | Produccion pequena |
| Standard_D4s_v3 | 4 | 16 GB | Produccion media |
| Standard_D8s_v3 | 8 | 32 GB | Produccion grande |

### Memoria Optimizada (Serie E)
| Tamano | vCPUs | RAM | Caso de Uso |
|--------|-------|-----|-------------|
| Standard_E2s_v3 | 2 | 16 GB | Bases de datos pequenas |
| Standard_E4s_v3 | 4 | 32 GB | Bases de datos medianas |
| Standard_E8s_v3 | 8 | 64 GB | SAP, SQL Server |

### Computo Optimizado (Serie F)
| Tamano | vCPUs | RAM | Caso de Uso |
|--------|-------|-----|-------------|
| Standard_F2s_v2 | 2 | 4 GB | Batch processing |
| Standard_F4s_v2 | 4 | 8 GB | Web servers |
| Standard_F8s_v2 | 8 | 16 GB | Gaming, analytics |

## Imagenes Comunes

### Ubuntu
```hcl
# Ubuntu 22.04 LTS
source_image_publisher = "Canonical"
source_image_offer     = "0001-com-ubuntu-server-jammy"
source_image_sku       = "22_04-lts-gen2"

# Ubuntu 20.04 LTS
source_image_publisher = "Canonical"
source_image_offer     = "0001-com-ubuntu-server-focal"
source_image_sku       = "20_04-lts-gen2"
```

### Red Hat
```hcl
# RHEL 8
source_image_publisher = "RedHat"
source_image_offer     = "RHEL"
source_image_sku       = "8-lvm-gen2"

# RHEL 9
source_image_publisher = "RedHat"
source_image_offer     = "RHEL"
source_image_sku       = "9-lvm-gen2"
```

### CentOS / AlmaLinux
```hcl
# AlmaLinux 8
source_image_publisher = "almalinux"
source_image_offer     = "almalinux"
source_image_sku       = "8-gen2"
```

### Debian
```hcl
# Debian 11
source_image_publisher = "Debian"
source_image_offer     = "debian-11"
source_image_sku       = "11-gen2"
```

## Tipos de Disco

| Tipo | IOPS Max | Throughput | Caso de Uso |
|------|----------|------------|-------------|
| Standard_LRS | 500 | 60 MB/s | Dev/Test, backups |
| StandardSSD_LRS | 6,000 | 750 MB/s | Web servers |
| Premium_LRS | 20,000 | 900 MB/s | Bases de datos |
| Premium_ZRS | 20,000 | 900 MB/s | HA con zonas |
| UltraSSD_LRS | 160,000 | 4,000 MB/s | SAP HANA |

## Recursos Creados

- `azurerm_network_interface.this` - Network Interface
- `azurerm_network_interface_security_group_association.this` - NSG association (opcional)
- `azurerm_linux_virtual_machine.this` - La VM
- `azurerm_managed_disk.this` - Data disks (por cada disco)
- `azurerm_virtual_machine_data_disk_attachment.this` - Disk attachments
- `azurerm_virtual_machine_extension.ama` - Azure Monitor Agent (opcional)

## Consideraciones de Seguridad

1. **SSH Keys**: Siempre usar SSH keys en lugar de passwords
2. **NSG**: Asociar NSG para controlar trafico
3. **Managed Identity**: Usar identidad para acceder a otros recursos
4. **Encryption**: Considerar disk encryption para datos sensibles
5. **Updates**: Habilitar automatic patching o Azure Update Manager
