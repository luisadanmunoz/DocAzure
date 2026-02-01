/**
 * # Ejemplo Completo - Infraestructura Azure
 *
 * Este ejemplo demuestra como usar todos los modulos de Terraform
 * para desplegar una infraestructura completa en Azure.
 */

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Variables locales
locals {
  project     = "demo"
  environment = "dev"
  location    = "westeurope"

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

# Resource Group
module "resource_group" {
  source = "../../modules/resource-group"

  name        = "rg-${local.project}-${local.environment}"
  location    = local.location
  tags        = local.common_tags
  enable_lock = false
}

# Log Analytics Workspace
module "log_analytics" {
  source = "../../modules/log-analytics-workspace"

  name                = "law-${local.project}-${local.environment}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  retention_in_days   = 30
  tags                = local.common_tags

  solutions = [
    {
      solution_name = "VMInsights"
      publisher     = "Microsoft"
      product       = "OMSGallery/VMInsights"
    }
  ]

  create_data_collection_rule = true
}

# Virtual Network
module "vnet" {
  source = "../../modules/virtual-network"

  name                       = "vnet-${local.project}-${local.environment}"
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  address_space              = ["10.0.0.0/16"]
  dns_servers                = []
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = local.common_tags
}

# Network Security Group - Web Tier
module "nsg_web" {
  source = "../../modules/network-security-group"

  name                       = "nsg-${local.project}-web-${local.environment}"
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = local.common_tags

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
      description                = "Permitir trafico HTTPS"
    },
    {
      name                       = "AllowSSH"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "10.0.0.0/8"
      destination_address_prefix = "*"
      description                = "Permitir SSH desde red interna"
    }
  ]
}

# Network Security Group - Database Tier
module "nsg_db" {
  source = "../../modules/network-security-group"

  name                       = "nsg-${local.project}-db-${local.environment}"
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = local.common_tags

  security_rules = [
    {
      name                       = "AllowPostgres"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5432"
      source_address_prefix      = "10.0.1.0/24"
      destination_address_prefix = "*"
      description                = "Permitir PostgreSQL desde subnet web"
    }
  ]
}

# Subnet - Web Tier
module "subnet_web" {
  source = "../../modules/subnet"

  name                 = "snet-${local.project}-web-${local.environment}"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault"
  ]

  network_security_group_id = module.nsg_web.id
}

# Subnet - Database Tier
module "subnet_db" {
  source = "../../modules/subnet"

  name                 = "snet-${local.project}-db-${local.environment}"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault"
  ]

  network_security_group_id = module.nsg_db.id
}

# Storage Account
module "storage" {
  source = "../../modules/storage-account"

  name                          = "st${local.project}${local.environment}001"
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = true
  log_analytics_workspace_id    = module.log_analytics.id
  tags                          = local.common_tags

  enable_network_rules   = true
  network_default_action = "Deny"
  network_bypass         = ["AzureServices"]
  network_subnet_ids     = [module.subnet_web.id, module.subnet_db.id]

  containers = [
    {
      name        = "logs"
      access_type = "private"
    },
    {
      name        = "backups"
      access_type = "private"
    }
  ]
}

# Key Vault
module "key_vault" {
  source = "../../modules/key-vault"

  name                        = "kv-${local.project}-${local.environment}"
  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  sku_name                    = "standard"
  enable_rbac_authorization   = true
  purge_protection_enabled    = true
  soft_delete_retention_days  = 90
  log_analytics_workspace_id  = module.log_analytics.id
  tags                        = local.common_tags

  enable_network_acls    = true
  network_default_action = "Deny"
  network_bypass         = "AzureServices"
  network_subnet_ids     = [module.subnet_web.id]
}

# Linux Virtual Machine - Web Server
module "vm_web" {
  source = "../../modules/virtual-machine-linux"

  name                = "vm-${local.project}-web-${local.environment}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  size                = "Standard_B2s"
  subnet_id           = module.subnet_web.id

  admin_username                  = "azureadmin"
  disable_password_authentication = true
  admin_ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... your-ssh-key"
  ]

  source_image_publisher = "Canonical"
  source_image_offer     = "0001-com-ubuntu-server-jammy"
  source_image_sku       = "22_04-lts-gen2"
  source_image_version   = "latest"

  os_disk_storage_account_type = "Premium_LRS"
  os_disk_caching              = "ReadWrite"

  identity_type               = "SystemAssigned"
  enable_boot_diagnostics     = true
  enable_azure_monitor_agent  = true
  network_security_group_id   = module.nsg_web.id

  tags = local.common_tags

  data_disks = [
    {
      name                 = "vm-${local.project}-web-${local.environment}-data01"
      disk_size_gb         = 64
      storage_account_type = "Premium_LRS"
      lun                  = 0
      caching              = "ReadWrite"
    }
  ]
}
