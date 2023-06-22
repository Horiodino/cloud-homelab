// Provider azurerm
// resource azurerm_resource_group name kube-cluster location East US
// network configuration :: vnet, subnet, security group, network interface, public ip, load balancer, availability set, virtual machine
//                      :: the vm going to communicate with each other so for all the vm we need to share the same network configuration
//                     :: if you are using in local machine then you ndoesnot need to create the network configuration because you vms are using
//                    :: the same network configuration as local machine


provider "azurerm" {
    features {}
}

// resource group
resource "azurerm_resource_group" "name" {
    name = "kube-cluster"
    location = "East US"
}

// network configuration
resource "azurerm_virtual_network" "name" {
    name = "kube-cluster-vnet"
    address_space = ["  "]
    location = azurerm_resource_group.name.location
    resource_group_name = azurerm_resource_group.name.name
}

resource "azurerm_subnet" "shared-subnet" {
    name = "kube-cluster-subnet"
    resource_group_name = azurerm_resource_group.name.name
    virtual_network_name = azurerm_virtual_network.name.name
    address_prefixes = [" "]
}

resource "azurerm_network_security_group" "security-group" {
    name = "kube-cluster-nsg"
    location = azurerm_resource_group.name.location
    resource_group_name = azurerm_resource_group.name.name
    security_rule {
        name = "kube-cluster-nsg-rule"
        priority = 1001
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "80"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
}


resource "azurerm_network_interface" "virtual-nic" {
    name = "kube-cluster-nic"
    location = azurerm_resource_group.name.location
    resource_group_name = azurerm_resource_group.name.name

    ip_configuration {
        name = "kube-cluster-nic-ip"
        subnet_id = azurerm_subnet.name.id
        private_ip_address_allocation = "dynamic"
        public_ip_address_id = azurerm_public_ip.name.id
    }
}





// output