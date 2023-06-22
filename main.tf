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


resource "azurerm_public_ip" "public-ip" {
    name = "kube-cluster-pip"
    location = azurerm_resource_group.name.location
    resource_group_name = azurerm_resource_group.name.name
    allocation_method = "Dynamic"
}



resource "azurerm_lb" "load-balancer" {
    name = "kube-cluster-lb"
    location = azurerm_resource_group.name.location
    resource_group_name = azurerm_resource_group.name.name
    sku = "Standard"
}

// i dont know how to explain it  but here is the explanation from the web
# By configuring backend address pools, you can define the set of resources that will receive the traffic load balanced by the Azure Load Balancer,
#  allowing for efficient distribution and scaling of network traffic across your application infrastructure.
resource "azurerm_lb_backend_address_pool" "backend-pool" {
    name = "kube-cluster-lb-pool"
    resource_group_name = azurerm_resource_group.name.name
    loadbalancer_id = azurerm_lb.name.id
}


// it is used to check the health of the vms 
resource "azurerm_lb_probe" "health-check-probe" {
    name = "kube-cluster-lb-probe"
    resource_group_name = azurerm_resource_group.name.name
    loadbalancer_id = azurerm_lb.name.id
    port = 80
    protocol = "TCP"
}


// load balancer rule :: it is used to distribute the traffic across the vms simply a load balancer rule is used to distribute the traffic across the vms
resource "azurerm_lb_rule" "load-balancer-rule" {
    name = "kube-cluster-lb-rule"
    resource_group_name = azurerm_resource_group.name.name
    loadbalancer_id = azurerm_lb.name.id
    backend_address_pool_id = azurerm_lb_backend_address_pool.name.id
    backend_port = 80
    frontend_ip_configuration_id = azurerm_lb.name.frontend_ip_configuration[0].id
    frontend_port = 80
    protocol = "TCP"
    probe_id = azurerm_lb_probe.name.id
}



// in simple words it is used to distribute the vms across the different hardware like if one hardware is down then it will not affect the other hardware
resource "azurerm_availability_set" "availability-set" {
    name = "kube-cluster-availability-set"
    location = azurerm_resource_group.name.location
    resource_group_name = azurerm_resource_group.name.name
}


resource "azurerm_virtual_machine" "virtual-machine" {
    name = "kube-cluster-vm"
    location = azurerm_resource_group.name.location
    resource_group_name = azurerm_resource_group.name.name
    network_interface_ids = [azurerm_network_interface.name.id]
    vm_size = "Standard_B2s"
    availability_set_id = azurerm_availability_set.name.id

    // delete os disk and data disk on termination when you delete the vm then it will delete the os disk and data disk also
    delete_os_disk_on_termination = true
    delete_data_disks_on_termination = true
    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "16.04-LTS"
        version = "latest"
    }
    storage_os_disk {
        name = "kube-cluster-os-disk"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
    }
    os_profile {
        computer_name = "kube-cluster-vm"
    }
    os_profile_linux_config {
        disable_password_authentication = false
    }
    tags = {
        environment = "dev"
    }
}




// output