resource "azurerm_public_ip" "fw-hub-pip" {
    name                = "fw-hub-pip"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Static"
    sku                 = "Standard"
}

resource "azurerm_firewall_policy" "fw-hub" {
    name                = "fw-hub-policy"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_firewall" "fw-hub" {
    name                = "fw-hub"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku_name            = "AZFW_VNet"
    sku_tier            = "Standard"

    ip_configuration {
        name                 = "configuration"
        subnet_id            = azurerm_subnet.fw-hub.id
        public_ip_address_id = azurerm_public_ip.fw-hub-pip.id
    }

    firewall_policy_id = azurerm_firewall_policy.fw-hub.id
}

resource "azurerm_firewall_policy_rule_collection_group" "fw-hub-rcg" {
    name               = "fw-hub-rcg"
    firewall_policy_id = azurerm_firewall_policy.fw-hub.id
    priority           = 100

    application_rule_collection {
        name     = "app-rule-collection"
        priority = 100
        action   = "Allow"

        rule {
            name        = "allow-microsoft-from-spoke"
            description = "Allow Microsoft traffic from Spoke 01"
            source_addresses = azurerm_subnet.fw-spoke.address_prefixes
            destination_fqdns = ["*.microsoft.com", "microsoft.com"]
            protocols {
                type = "Https"
                port = 443
            }
            protocols {
                type = "Http"
                port = 80
            }
        }
    }

    network_rule_collection {
        name     = "network-rule-collection"
        priority = 200
        action   = "Allow"

        rule {
            name                   = "allow-dns"
            description            = "Allow DNS traffic"
            source_addresses       = azurerm_subnet.spoke_01_default.address_prefixes
            destination_addresses  = ["*"]
            destination_ports      = ["53"]
            protocols              = ["UDP"]
        }
    }
}