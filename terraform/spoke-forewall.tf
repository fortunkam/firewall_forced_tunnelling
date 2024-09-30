resource "azurerm_public_ip" "fw-spoke-pip" {
    name                = "fw-spoke-pip"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Static"
    sku                 = "Standard"
}

resource "azurerm_firewall_policy" "fw-spoke" {
    name                = "fw-spoke-policy"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_firewall" "fw-spoke" {
    name                = "fw-spoke"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku_name            = "AZFW_VNet"
    sku_tier            = "Standard"

    ip_configuration {
        name                 = "configuration"
        subnet_id            = azurerm_subnet.fw-spoke.id
    }

    management_ip_configuration {
        name                 = "mgmt-configuration"
        subnet_id            = azurerm_subnet.fw-mgmt-spoke.id
        public_ip_address_id = azurerm_public_ip.fw-spoke-pip.id
    }

    firewall_policy_id = azurerm_firewall_policy.fw-spoke.id
}

resource "azurerm_firewall_policy_rule_collection_group" "fw-spoke-rcg" {
    name               = "fw-spoke-rcg"
    firewall_policy_id = azurerm_firewall_policy.fw-spoke.id
    priority           = 100

    application_rule_collection {
        name     = "app-rule-collection"
        priority = 100
        action   = "Deny"

        rule {
            name        = "allow-microsoft-from-spoke"
            description = "Allow Microsoft traffic from Spoke 01"
            source_addresses = azurerm_subnet.spoke_01_default.address_prefixes
            destination_fqdns = ["account.microsoft.com"]
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

    application_rule_collection {
        name     = "app-rule-collection-allow"
        priority = 150
        action   = "Allow"

        rule {
            name        = "allow-microsoft-from-spoke"
            description = "Allow Microsoft traffic from Spoke 01"
            source_addresses = azurerm_subnet.spoke_01_default.address_prefixes
            destination_fqdns = ["*.microsoft.com"]
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
}

