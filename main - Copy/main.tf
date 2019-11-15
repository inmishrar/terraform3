variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

variable "web_server_location" {}
variable "web_server_rg" {}
variable "resource_prefix" {}
variable "web_server_address_space" {}
variable "web_server_name" {}
variable "environment" {}
variable "web_server_count" {}
variable "web_server_subnets" {
  type = "list"
}

provider "azurerm" {
  version         = "1.27"
  tenant_id       = "${var.tenant_id}"
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
}

resource "azurerm_resource_group" "web_server_rg" {
  name     = "${var.web_server_rg}"
  location = "${var.web_server_location}"
}

resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = "${var.web_server_location}"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}"
  address_space       = ["${var.web_server_address_space}"]
}

resource "azurerm_subnet" "web_server_subnet" {
  name                      = "${var.resource_prefix}-${substr(var.web_server_subnets[count.index], 0, length(var.web_server_subnets[count.index]) - 3)}-subnet"
  resource_group_name       = "${azurerm_resource_group.web_server_rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.web_server_vnet.name}"
  address_prefix            = "${var.web_server_subnets[count.index]}"
  network_security_group_id = "${azurerm_network_security_group.web_server_nsg.id}"
  count                     = "${length(var.web_server_subnets)}"
}

resource "azurerm_network_interface" "web_server_nic" {
  name                      = "${var.web_server_name}-${format("%02d",count.index)}-nic"
  location                  = "${var.web_server_location}"
  resource_group_name       = "${azurerm_resource_group.web_server_rg.name}"
  count                     = "${var.web_server_count}"

  ip_configuration {
    name                          = "${var.web_server_name}-${format("%02d",count.index)}-ip"
    subnet_id                     = "${azurerm_subnet.web_server_subnet.*.id[count.index]}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.web_server_public_ip.*.id[count.index]}"
  }
}

resource "azurerm_public_ip" "web_server_public_ip" {
  name                         = "${var.web_server_name}-${format("%02d",count.index)}-public-ip"
  location                     = "${var.web_server_location}"
  resource_group_name          = "${azurerm_resource_group.web_server_rg.name}"
  public_ip_address_allocation = "${var.environment == "production" ? "static" : "dynamic"}"
  count                        = "${var.web_server_count}"
}

resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${var.web_server_name}-nsg"
  location            = "${var.web_server_location}"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}" 
}

resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name                        = "RDP Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.web_server_rg.name}" 
  network_security_group_name = "${azurerm_network_security_group.web_server_nsg.name}" 
  count                       = "${var.environment == "production" ? 0 : 1}"
}

resource "azurerm_virtual_machine" "web_server" {
  name                         = "${var.web_server_name}-${format("%02d",count.index)}"
  location                     = "${var.web_server_location}"
  resource_group_name          = "${azurerm_resource_group.web_server_rg.name}"  
  network_interface_ids        = ["${azurerm_network_interface.web_server_nic.*.id[count.index]}"]
  vm_size                      = "Standard_B1s"
  availability_set_id          = "${azurerm_availability_set.web_server_availability_set.id}"
  count                        = "${var.web_server_count}"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.web_server_name}-${format("%02d",count.index)}-os"    
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  
  os_profile {
    computer_name      = "${var.web_server_name}-${format("%02d",count.index)}" 
    admin_username     = "webserver"
    admin_password     = "Passw0rd1234"
  }

  os_profile_windows_config {
  }

}

resource "azurerm_availability_set" "web_server_availability_set" {
  name                        = "${var.resource_prefix}-availability-set"
  location                    = "${var.web_server_location}"
  resource_group_name         = "${azurerm_resource_group.web_server_rg.name}"  
  managed                     = true
  platform_fault_domain_count = 2
}

variable "storageaccountname" {
  type        = "string"
  description = "Name of storage account"
  default     = "terraformifthen"
}

variable "lrsstorageaccount" {
  type        = "string"
  description = "LRS testing"
  default     = "true"
}

variable "lrs" {
  type        = "string"
  default     = "LRS"
}

variable "grs" {
  type        = "string"
  default     = "GRS"
}

resource "azurerm_storage_account" "testsa" {
  name                     = "${var.storageaccountname}"
  resource_group_name      = "${azurerm_resource_group.testrg.name}"
  location                 = "westus"
  account_tier             = "Standard"
  account_replication_type = "${var.lrsstorageaccount == true ? var.lrs : var.grs}"
}