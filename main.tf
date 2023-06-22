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



// output