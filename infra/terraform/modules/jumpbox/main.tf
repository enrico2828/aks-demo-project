locals {
  vm_name = "${var.name_prefix}-jumpbox-vm"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.name_prefix}-jumpbox-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_network_security_rule" "allow_ssh" {
  count = var.assign_public_ip ? 1 : 0

  name                        = "Allow-SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.allowed_ssh_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# NSGs are "deny inbound" by default, but we add an explicit deny rule to make
# the security posture obvious during reviews.
resource "azurerm_network_security_rule" "deny_all_inbound" {
  name                        = "Deny-All-Inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_public_ip" "pip" {
  count = var.assign_public_ip ? 1 : 0

  name                = "${var.name_prefix}-jumpbox-pip"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"

  tags = var.tags
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.name_prefix}-jumpbox-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.assign_public_ip ? azurerm_public_ip.pip[0].id : null
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = local.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name

  size = var.vm_size

  admin_username = var.admin_username

  # SSH keys only. No password authentication.
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  # Serial Console requires Boot Diagnostics.
  boot_diagnostics {
    storage_account_uri = null
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.ssh_public_key != null && length(trimspace(var.ssh_public_key)) > 0
      error_message = "You must provide ssh_public_key (SSH keys only; password auth is disabled)."
    }

    precondition {
      condition     = var.assign_public_ip == false || length(var.allowed_ssh_cidrs) > 0
      error_message = "If assign_public_ip=true you must set allowed_ssh_cidrs (no 0.0.0.0/0 fallback)."
    }
  }
}
