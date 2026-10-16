# sub/tenant/creds come from ARM_* env vars
provider "azurerm" {
  # shared keys are off on the fslogix account
  storage_use_azuread = true

  features {
    key_vault {
      purge_soft_delete_on_destroy = !var.key_vault_purge_protection_enabled
    }
    resource_group {
      prevent_deletion_if_contains_resources = var.environment == "prod"
    }
  }
}

provider "azapi" {}

provider "azuread" {}
