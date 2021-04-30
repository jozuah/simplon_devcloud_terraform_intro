#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Variable custom ma_region 
variable "ma_region" {
    type = string
    default= "eastus"
}

#ici "resource_group_terraform" est un nom interne pour terraform
resource "azurerm_resource_group" "resource_group_terraform" {
    #nom qui apparait dans azure
  name     = "josh_resource_group_terraform"
  #location = "East US"
  location = "${var.ma_region}"
}

#On appelle le resource groupe créé precedement pour creer le virtual network
resource "azurerm_virtual_network" "virtual_network_terraform" {
  name                = "virtualNetwork1"
  location            = azurerm_resource_group.resource_group_terraform.location
  resource_group_name = azurerm_resource_group.resource_group_terraform.name
  address_space       = ["10.0.0.0/16"]
}

# resource "azurerm_ssh_public_key" "example" {
#   name                = "example"
#   resource_group_name = "example"
#   location            = "West Europe"
#   public_key          = file("~/.ssh/id_rsa.pub")
# }
resource "azurerm_subnet" "subnet_terraform" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.resource_group_terraform.name
  virtual_network_name = azurerm_virtual_network.virtual_network_terraform.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "network_interface_terraform" {
    count = 3
  name                = "nic${count.index}"
  location            = azurerm_resource_group.resource_group_terraform.location
  resource_group_name = azurerm_resource_group.resource_group_terraform.name

  ip_configuration {
    name                          = "ip${count.index}"
    subnet_id                     = azurerm_subnet.subnet_terraform.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "virtual_machine_terraform" {
    count = length(azurerm_network_interface.network_interface_terraform)
  name                = "machine${count.index}"
  resource_group_name = azurerm_resource_group.resource_group_terraform.name
  location            = azurerm_resource_group.resource_group_terraform.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.network_interface_terraform[count.index].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "public_ip_terraform" {
  count = 3
  name                = "PublicIp${count.index}"
  resource_group_name = azurerm_resource_group.resource_group_terraform.name
  location            = azurerm_resource_group.resource_group_terraform.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}
output "virtual_net" {
    value = azurerm_virtual_network.virtual_network_terraform
}


