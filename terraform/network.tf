resource "azurerm_virtual_network" "hub" {
    name                = "vnet-hub"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "spoke-01" {
    name                = "vnet-spoke-01"
    address_space       = ["10.1.0.0/16"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network_peering" "hub-to-spoke-01" {
    name                      = "hub-to-spoke-01"
    resource_group_name       = azurerm_resource_group.rg.name
    virtual_network_name      = azurerm_virtual_network.hub.name
    remote_virtual_network_id = azurerm_virtual_network.spoke-01.id
    allow_forwarded_traffic   = true
    allow_gateway_transit     = false
    use_remote_gateways       = false
}

resource "azurerm_virtual_network_peering" "spoke-01-to-hub" {
    name                      = "spoke-01-to-hub"
    resource_group_name       = azurerm_resource_group.rg.name
    virtual_network_name      = azurerm_virtual_network.spoke-01.name
    remote_virtual_network_id = azurerm_virtual_network.hub.id
    allow_forwarded_traffic   = true
    allow_gateway_transit     = false
    use_remote_gateways       = false
}

resource "azurerm_subnet" "hub_default" {
    name                 = "default"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.hub.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "bastion" {
    name                 = "AzureBastionSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.hub.name
    address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "spoke_01_default" {
    name                 = "default"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.spoke-01.name
    address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "fw-hub" {
    name                 = "AzureFirewallSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.hub.name
    address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_route_table" "hub_fw_route_table" {
    name                = "hub-fw-route-table"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_route_table" "spoke_fw_route_table" {
    name                = "spoke-fw-route-table"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_route" "hub_fw_route" {
    name                   = "hub_fw_route"
    resource_group_name    = azurerm_resource_group.rg.name
    route_table_name       = azurerm_route_table.hub_fw_route_table.name
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.fw-hub.ip_configuration[0].private_ip_address
}

resource "azurerm_route" "spoke_fw_route" {
    name                   = "spoke_fw_route"
    resource_group_name    = azurerm_resource_group.rg.name
    route_table_name       = azurerm_route_table.spoke_fw_route_table.name
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.fw-spoke.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "spoke_01_default" {
    subnet_id      = azurerm_subnet.spoke_01_default.id
    route_table_id = azurerm_route_table.spoke_fw_route_table.id
}

resource "azurerm_subnet_route_table_association" "spoke_fw_default" {
    subnet_id      = azurerm_subnet.fw-spoke.id
    route_table_id = azurerm_route_table.hub_fw_route_table.id
}

resource "azurerm_subnet" "fw-spoke" {
    name                 = "AzureFirewallSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.spoke-01.name
    address_prefixes     = ["10.1.2.0/24"]
}

resource "azurerm_subnet" "fw-mgmt-spoke" {
    name                 = "AzureFirewallManagementSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.spoke-01.name
    address_prefixes     = ["10.1.3.0/24"]
}