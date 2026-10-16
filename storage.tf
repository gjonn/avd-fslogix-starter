# fslogix profiles: premium files, PE only, entra kerberos
module "fslogix_storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.10.0"

  name             = module.naming.storage_account.name_unique
  parent_id        = module.resource_group.resource_id
  location         = var.location
  tags             = local.tags
  enable_telemetry = var.enable_telemetry

  account_kind             = "FileStorage"
  account_tier             = "Premium"
  account_replication_type = "ZRS"

  public_network_access_enabled   = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  min_tls_version                 = "TLS1_2"

  azure_files_authentication = {
    directory_type = "AADKERB"
  }

  network_rules = {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  shares = {
    profiles = {
      name             = local.fslogix_share_name
      quota            = var.fslogix_share_quota_gb
      enabled_protocol = "SMB"

      role_assignments = merge(
        {
          users = {
            role_definition_id_or_name = "Storage File Data SMB Share Contributor"
            principal_id               = var.avd_users_group_object_id
            principal_type             = "Group"
          }
        },
        var.avd_admins_group_object_id == null ? {} : {
          admins = {
            role_definition_id_or_name = "Storage File Data SMB Share Elevated Contributor"
            principal_id               = var.avd_admins_group_object_id
            principal_type             = "Group"
          }
        }
      )
    }
  }

  private_endpoints = {
    file = {
      name                          = "${module.naming.private_endpoint.name}-file"
      subnet_resource_id            = module.vnet.subnets["private_endpoints"].resource_id
      subresource_name              = "file"
      private_dns_zone_resource_ids = [module.private_dns_file.resource_id]
    }
  }
}

# session host local admin passwords
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.12.0"

  name                = module.naming.key_vault.name_unique
  resource_group_name = module.resource_group.name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.tags
  enable_telemetry    = var.enable_telemetry

  sku_name                       = "standard"
  legacy_access_policies_enabled = false
  purge_protection_enabled       = var.key_vault_purge_protection_enabled
  soft_delete_retention_days     = 7

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = var.key_vault_allowed_ip_ranges
  }

  role_assignments = {
    deployer_secrets_officer = {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }

  diagnostic_settings = local.diagnostic_settings
}

# VM module writes secrets right after the role assignment - first apply 403s without this
resource "time_sleep" "key_vault_rbac" {
  create_duration = "60s"

  depends_on = [module.key_vault]
}
