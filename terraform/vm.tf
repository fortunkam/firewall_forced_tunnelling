resource "azurerm_public_ip" "vm-pip" {
    name                = "test-vm-pip"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Static"
}

resource "azurerm_network_interface" "vm-nic" {
    name                = "test-vm-nic"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.spoke_01_default.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.vm-pip.id
    }
}

resource "azurerm_virtual_machine" "vm" {
    name                  = "test-vm"
    location              = azurerm_resource_group.rg.location
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.vm-nic.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "example-os-disk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2019-Datacenter"
        version   = "latest"
    }

    os_profile {
        computer_name  = "hostname"
        admin_username = "adminuser"
        admin_password = var.admin_password
    }

    os_profile_windows_config {
        provision_vm_agent        = true
        enable_automatic_upgrades = true
    }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "auto_shutdown" {
    virtual_machine_id = azurerm_virtual_machine.vm.id
    location = azurerm_resource_group.rg.location
    enabled = true

    daily_recurrence_time = "1900"
    timezone = "UTC"

    notification_settings {
      enabled = false
    }
}