module "host_pool" {
  source  = "Azure/avm-res-desktopvirtualization-hostpool/azurerm"
  version = "0.5.0"

  virtual_desktop_host_pool_name                = module.naming.virtual_desktop_host_pool.name
  virtual_desktop_host_pool_resource_group_name = module.resource_group.name
  resource_group_name                           = module.resource_group.name
  location                                      = var.location
  tags                                          = local.tags
  enable_telemetry                              = var.enable_telemetry

  virtual_desktop_host_pool_friendly_name            = "AVD ${upper(var.environment)}"
  virtual_desktop_host_pool_type                     = "Pooled"
  virtual_desktop_host_pool_load_balancer_type       = var.host_pool_load_balancer_type
  virtual_desktop_host_pool_maximum_sessions_allowed = var.host_pool_max_sessions
  virtual_desktop_host_pool_preferred_app_group_type = "Desktop"
  virtual_desktop_host_pool_start_vm_on_connect      = true
  virtual_desktop_host_pool_validate_environment     = var.environment != "prod"

  # entra join + SSO. turn off drive/clipboard redirection for regulated tenants
  virtual_desktop_host_pool_custom_rdp_properties = {
    use_multimon = 1
    custom_properties = {
      targetisaadjoined = "i:1"
      enablerdsaadauth  = "i:1"
    }
  }

  virtual_desktop_host_pool_scheduled_agent_updates = {
    enabled  = true
    timezone = var.scaling_plan_time_zone
    schedule = [{
      day_of_week = "Saturday"
      hour_of_day = 2
    }]
  }

  diagnostic_settings = local.diagnostic_settings
}

module "application_group" {
  source  = "Azure/avm-res-desktopvirtualization-applicationgroup/azurerm"
  version = "0.3.0"

  virtual_desktop_application_group_name                = module.naming.virtual_desktop_application_group.name
  virtual_desktop_application_group_resource_group_name = module.resource_group.name
  virtual_desktop_application_group_host_pool_id        = module.host_pool.resource_id
  virtual_desktop_application_group_type                = "Desktop"
  virtual_desktop_application_group_friendly_name       = "Desktop"
  location                                              = var.location
  virtual_desktop_application_group_tags                = local.tags
  enable_telemetry                                      = var.enable_telemetry

  role_assignments = {
    users = {
      role_definition_id_or_name = "Desktop Virtualization User"
      principal_id               = var.avd_users_group_object_id
      principal_type             = "Group"
    }
  }

  diagnostic_settings = local.diagnostic_settings
}

module "workspace" {
  source  = "Azure/avm-res-desktopvirtualization-workspace/azurerm"
  version = "0.3.0"

  virtual_desktop_workspace_name                = module.naming.virtual_desktop_workspace.name
  virtual_desktop_workspace_resource_group_name = module.resource_group.name
  virtual_desktop_workspace_friendly_name       = "Workspace ${upper(var.environment)}"
  location                                      = var.location
  virtual_desktop_workspace_tags                = local.tags
  enable_telemetry                              = var.enable_telemetry

  diagnostic_settings = local.diagnostic_settings
}

# workspace AVM doesn't do the app group association
resource "azurerm_virtual_desktop_workspace_application_group_association" "desktop" {
  workspace_id         = module.workspace.resource_id
  application_group_id = module.application_group.resource_id
}

module "scaling_plan" {
  source  = "Azure/avm-res-desktopvirtualization-scalingplan/azurerm"
  version = "0.3.0"

  virtual_desktop_scaling_plan_name                = module.naming.virtual_desktop_scaling_plan.name
  virtual_desktop_scaling_plan_resource_group_name = module.resource_group.name
  virtual_desktop_scaling_plan_time_zone           = var.scaling_plan_time_zone
  location                                         = var.location
  virtual_desktop_scaling_plan_tags                = local.tags
  enable_telemetry                                 = var.enable_telemetry

  virtual_desktop_scaling_plan_schedule = [{
    name                                 = "weekdays"
    days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                   = var.scaling_plan_schedule.ramp_up_start_time
    ramp_up_load_balancing_algorithm     = "BreadthFirst"
    ramp_up_minimum_hosts_percent        = var.scaling_plan_schedule.ramp_up_min_hosts_percent
    ramp_up_capacity_threshold_percent   = 60
    peak_start_time                      = var.scaling_plan_schedule.peak_start_time
    peak_load_balancing_algorithm        = var.host_pool_load_balancer_type
    ramp_down_start_time                 = var.scaling_plan_schedule.ramp_down_start_time
    ramp_down_load_balancing_algorithm   = "DepthFirst"
    ramp_down_minimum_hosts_percent      = var.scaling_plan_schedule.ramp_down_min_hosts_pct
    ramp_down_capacity_threshold_percent = 90
    ramp_down_force_logoff_users         = false
    ramp_down_stop_hosts_when            = "ZeroSessions"
    ramp_down_wait_time_minutes          = 30
    ramp_down_notification_message       = "You will be signed out in 30 minutes. Please save your work."
    off_peak_start_time                  = var.scaling_plan_schedule.off_peak_start_time
    off_peak_load_balancing_algorithm    = "DepthFirst"
  }]

  virtual_desktop_scaling_plan_host_pool = [{
    hostpool_id          = module.host_pool.resource_id
    scaling_plan_enabled = true
  }]

  diagnostic_settings = local.diagnostic_settings

  # power on/off role lives in the RG module
  depends_on = [module.resource_group]
}
