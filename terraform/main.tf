locals {
  vars = jsondecode(file("${path.module}/../.tfvars.json"))
}

#configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = local.vars.vm_resource_group_name
  location = local.vars.location
  tags     = {}
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "vm-vnet"
  address_space       = [local.vars.vm_vnet_address_space]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.vars.vm_subnet_address_prefixes]
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = "vm-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = local.vars.vm_public_ip_allocation_method
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsgroup" {
  name                = "network-security-group"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                = "vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "vm-nic-config"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = local.vars.vm_public_ip_allocation_method
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsgroup2nic" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsgroup.id
}

# Create vm
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = local.vars.vm_name
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = local.vars.vm_size
  admin_username        = local.vars.vm_admin_user
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = local.vars.vm_admin_user
    public_key = file(local.vars.vm_admin_ssh_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = local.vars.image_publisher
    offer     = local.vars.image_offer
    sku       = local.vars.image_sku
    version   = "latest"
  }
}

# Print out IP address of the new VM
output "ip_address" {
  value       = azurerm_linux_virtual_machine.vm.public_ip_address
  description = "IP address of the new VM"
}