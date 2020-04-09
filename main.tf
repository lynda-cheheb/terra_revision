#========================================================================================================
                    # resource groupe
#========================================================================================================
resource "azurerm_resource_group" "rg" {
  name     = "${var.name}"
  location = "${var.location}"
  tags = {
    owner = "${var.owner}"
  }
}

#=======================================================================================================
                   # VNET
#=======================================================================================================
resource "azurerm_virtual_network" "vnet" {
    name                = "${var.nameVNET}"
    location            = "${azurerm_resource_group.rg.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    address_space       = [ "10.0.0.0/16" ]
}

#=======================================================================================================
                   #SUBNET
#=======================================================================================================
resource "azurerm_subnet" "subnet" {
  name                 = "${var.nameSUBNET}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  address_prefix       = "10.0.1.0/24"
}

#======================================================================================================
                  # public IP
#======================================================================================================
resource "azurerm_public_ip" "pubip" {
  name = "${var.namePubIp}"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method = "Dynamic"
}

#=====================================================================================================
                  # NSG
#=====================================================================================================
resource "azurerm_network_security_group" "nsg" {
    name                = "${var.nameNSG}"
    location            = "${azurerm_resource_group.rg.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"

    security_rule {
        name                       = "SSH"
        priority                   = "1001"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTP"
        priority                   = "1002"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "jenkins-SHH"
        priority                   = "1003"
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

#=======================================================================================================
                  #NIC
#=======================================================================================================
resource "azurerm_network_interface" "nic" {
  name = "${var.nameNIC}"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration{
    name = "ipConfig"
    subnet_id = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${azurerm_public_ip.pubip.id}"
  }
}

#======================================================================================================
                    #VM
#======================================================================================================
resource "azurerm_virtual_machine" "vm"{
  name = "${var.nameVM}"
  location = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_interface_ids = [ "${azurerm_network_interface.nic.id}" ]
  vm_size = "${var.vmSize}"

  storage_os_disk{
    name ="myDisk1"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_image_reference{
    publisher = "OpenLogic"
    offer = "CentOS"
    sku = "7.7"
    version = "latest"
  }
  os_profile{
    computer_name = "masterLynda"
    admin_username = "lynda"
  }
  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys{
       path =  "/home/lynda/.ssh/authorized_keys"
       key_data = "${var.key_data}"
      #  key_data = file("/home/stage/.ssh/authorized_keys")
    }
  }
}
