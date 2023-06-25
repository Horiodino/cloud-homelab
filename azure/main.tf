// Provider azurerm
// resource azurerm_resource_group name kube-cluster location East US
// network configuration :: vnet, subnet, security group, network interface, public ip, load balancer, availability set, virtual machine
//                      :: the vm going to communicate with each other so for all the vm we need to share the same network configuration
//                     :: if you are using in local machine then you ndoesnot need to create the network configuration because you vms are using
//                    :: the same network configuration as local machine
//
// Provider azurerm
provider "azurerm" {
  features {}
}

// Resource group
resource "azurerm_resource_group" "home-lab" {
  name     = "kube-cluster"
  location = "eastus"
}

// Network configuration
resource "azurerm_virtual_network" "vnet" {
  name                = "kube-cluster-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.home-lab.location
  resource_group_name = azurerm_resource_group.home-lab.name
}

resource "azurerm_subnet" "shared-subnet" {
  name                 = "kube-cluster-subnet"
  resource_group_name  = azurerm_resource_group.home-lab.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "security-group" {
  name                = "kube-cluster-nsg"
  location            = azurerm_resource_group.home-lab.location
  resource_group_name = azurerm_resource_group.home-lab.name

  security_rule {
    name                       = "kube-cluster-nsg-rule"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  // Add SSH rule
  security_rule {
    name                       = "ssh-rule"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet-nsg-association" {
  subnet_id                 = azurerm_subnet.shared-subnet.id
  network_security_group_id = azurerm_network_security_group.security-group.id
}

resource "azurerm_public_ip" "lb-public-ip" {
  name                = "kube-cluster-lb-public-ip"
  location            = azurerm_resource_group.home-lab.location
  resource_group_name = azurerm_resource_group.home-lab.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "kube-cluster-nic"
  location            = azurerm_resource_group.home-lab.location
  resource_group_name = azurerm_resource_group.home-lab.name

  ip_configuration {
    name                          = "kube-cluster-nic-ip"
    subnet_id                     = azurerm_subnet.shared-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lb-public-ip.id
  }
}

resource "azurerm_availability_set" "availability-set" {
  name                = "kube-cluster-availability-set"
  location            = azurerm_resource_group.home-lab.location
  resource_group_name = azurerm_resource_group.home-lab.name
  platform_fault_domain_count   = 2
  platform_update_domain_count = 2
}

resource "azurerm_lb" "lb" {
  name                = "kube-cluster-lb"
  location            = azurerm_resource_group.home-lab.location
  resource_group_name = azurerm_resource_group.home-lab.name
  sku                 = "Basic"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "kube-cluster-vm"
  location            = azurerm_resource_group.home-lab.location
  resource_group_name = azurerm_resource_group.home-lab.name
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  availability_set_id = azurerm_availability_set.availability-set.id

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "kube-cluster-os-disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}


// create 2nd vm 

resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "kube-cluster-node-1"
  location            = azurerm_resource_group.home-lab.location
  resource_group_name = azurerm_resource_group.home-lab.name
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  availability_set_id = azurerm_availability_set.availability-set.id

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "kube-cluster-os-disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}


// 3rd vm

resource "azurerm_linux_virtual_machine" "vm3" {
  name                = "kube-cluster-node-2"
  location            = azurerm_resource_group.home-lab.location
  resource_group_name = azurerm_resource_group.home-lab.name
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  availability_set_id = azurerm_availability_set.availability-set.id

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name              = "kube-cluster-os-disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}