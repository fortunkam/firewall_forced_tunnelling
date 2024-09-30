provider "azurerm" {
    subscription_id = "8f4fcf65-74bc-4770-8824-a2f5e88cb177"
    features {
        resource_group {
            prevent_deletion_if_contains_resources = false
        }
    }
}