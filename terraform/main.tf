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
resource "azurerm_resource_group" "tfresgrp" {
  name     = "tf-resgrp"
  location = "eastus"
}

# Create a virtual network
resource "azurerm_virtual_network" "tfvnet" {
    name                = "tf-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.tfresgrp.location
    resource_group_name = azurerm_resource_group.tfresgrp.name
}

# Create subnet
resource "azurerm_subnet" "tfsubnet" { 
   name                  = "tf-subnet" 
   resource_group_name   = azurerm_resource_group.tfresgrp.name 
   virtual_network_name  = azurerm_virtual_network.tfvnet.name 
   address_prefixes      = ["10.0.1.0/24"]
 }

# Create public IP
 resource "azurerm_public_ip" "tfvmpublicip" { 
   name                  = "tf-vm-public-ip" 
   location              = azurerm_resource_group.tfresgrp.location
   resource_group_name   = azurerm_resource_group.tfresgrp.name 
   allocation_method   =   "Dynamic" 
 }

 # Create Network Security Group and rule
resource "azurerm_network_security_group" "tfnsg" {
    name                = "tf-network-security-group"
    location            = azurerm_resource_group.tfresgrp.location
    resource_group_name = azurerm_resource_group.tfresgrp.name

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
resource "azurerm_network_interface" "tfnic" {
    name                      = "tf-nic"
    location                  = azurerm_resource_group.tfresgrp.location
    resource_group_name       = azurerm_resource_group.tfresgrp.name

    ip_configuration {
        name                          = "tf-nic-config"
        subnet_id                     = azurerm_subnet.tfsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.tfvmpublicip.id
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "tfnsgtonic" {
    network_interface_id      = azurerm_network_interface.tfnic.id
    network_security_group_id = azurerm_network_security_group.tfnsg.id
}

# Create vm
resource "azurerm_linux_virtual_machine" "tfvm" {
  name                = "tf-vm"
  resource_group_name = azurerm_resource_group.tfresgrp.name
  location            = azurerm_resource_group.tfresgrp.location
  size                = "Standard_A1_v2"
  admin_username      = "tfazuser"
  network_interface_ids = [azurerm_network_interface.tfnic.id]

  admin_ssh_key {
    username   = "tfazuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Print out IP address of the new VM
output "ip_address" {
  value       = azurerm_linux_virtual_machine.tfvm.public_ip_address
  description = "IP address of the new VM"
}