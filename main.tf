module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = module.naming.resource_group.name
  location         = var.location
  tags             = local.tags
  enable_telemetry = var.enable_telemetry

  role_assignments = merge(
    {
      # scaling plan
      avd_power_on_off = {
        role_definition_id_or_name = "Desktop Virtualization Power On Off Contributor"
        principal_id               = data.azuread_service_principal.avd.object_id
        principal_type             = "ServicePrincipal"
      }
      # required for sign-in on entra-joined hosts
      users_vm_login = {
        role_definition_id_or_name = "Virtual Machine User Login"
        principal_id               = var.avd_users_group_object_id
        principal_type             = "Group"
      }
    },
    var.avd_admins_group_object_id == null ? {} : {
      admins_vm_login = {
        role_definition_id_or_name = "Virtual Machine Administrator Login"
        principal_id               = var.avd_admins_group_object_id
        principal_type             = "Group"
      }
    }
  )
}

module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                = module.naming.log_analytics_workspace.name
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = local.tags
  enable_telemetry    = var.enable_telemetry

  log_analytics_workspace_sku                        = "PerGB2018"
  log_analytics_workspace_retention_in_days          = var.log_retention_days
  log_analytics_workspace_internet_ingestion_enabled = "true"
  log_analytics_workspace_internet_query_enabled     = "true"
}

locals {
  diagnostic_settings = {
    to_log_analytics = {
      name                  = "diag-to-law"
      workspace_resource_id = module.log_analytics.resource_id
    }
  }
}
