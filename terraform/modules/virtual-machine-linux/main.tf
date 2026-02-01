/**
 * # Azure Linux Virtual Machine Module
 *
 * Modulo reutilizable para crear VMs Linux en Azure.
 * Incluye configuracion de discos, identidad, extensiones y boot diagnostics.
 */

# Network Interface
resource "azurerm_network_interface" "this" {
  name                = "${var.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.default_tags, var.tags)

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = var.public_ip_address_id
  }
}

# Asociacion NIC con NSG
resource "azurerm_network_interface_security_group_association" "this" {
  count = var.network_security_group_id != null ? 1 : 0

  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = var.network_security_group_id
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.size
  admin_username                  = var.admin_username
  disable_password_authentication = var.disable_password_authentication
  admin_password                  = var.disable_password_authentication ? null : var.admin_password
  computer_name                   = coalesce(var.computer_name, var.name)
  custom_data                     = var.custom_data
  user_data                       = var.user_data
  encryption_at_host_enabled      = var.encryption_at_host_enabled
  patch_mode                      = var.patch_mode
  provision_vm_agent              = var.provision_vm_agent
  zone                            = var.zone
  tags                            = merge(var.default_tags, var.tags)

  network_interface_ids = [azurerm_network_interface.this.id]

  # SSH Key
  dynamic "admin_ssh_key" {
    for_each = var.admin_ssh_keys
    content {
      username   = var.admin_username
      public_key = admin_ssh_key.value
    }
  }

  # OS Disk
  os_disk {
    name                      = "${var.name}-osdisk"
    caching                   = var.os_disk_caching
    storage_account_type      = var.os_disk_storage_account_type
    disk_size_gb              = var.os_disk_size_gb
    disk_encryption_set_id    = var.disk_encryption_set_id
    write_accelerator_enabled = var.os_disk_write_accelerator_enabled
  }

  # Source Image
  dynamic "source_image_reference" {
    for_each = var.source_image_id == null ? [1] : []
    content {
      publisher = var.source_image_publisher
      offer     = var.source_image_offer
      sku       = var.source_image_sku
      version   = var.source_image_version
    }
  }

  source_image_id = var.source_image_id

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }

  # Boot Diagnostics
  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }
}

# Data Disks
resource "azurerm_managed_disk" "this" {
  for_each = { for d in var.data_disks : d.name => d }

  name                   = each.value.name
  location               = var.location
  resource_group_name    = var.resource_group_name
  storage_account_type   = each.value.storage_account_type
  create_option          = lookup(each.value, "create_option", "Empty")
  disk_size_gb           = each.value.disk_size_gb
  disk_encryption_set_id = var.disk_encryption_set_id
  zone                   = var.zone
  tags                   = merge(var.default_tags, var.tags)
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  for_each = { for d in var.data_disks : d.name => d }

  managed_disk_id    = azurerm_managed_disk.this[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = each.value.lun
  caching            = lookup(each.value, "caching", "ReadWrite")
}

# Azure Monitor Agent Extension
resource "azurerm_virtual_machine_extension" "ama" {
  count = var.enable_azure_monitor_agent ? 1 : 0

  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  tags                       = var.tags
}
