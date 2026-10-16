environment = "dev"
location    = "eastus2"

address_space = "10.10.0.0/22"

session_host_count     = 1
session_host_sku       = "Standard_D4ads_v5"
host_pool_max_sessions = 6

# throwaway env - no purge protection, no zones
key_vault_purge_protection_enabled = false
availability_zones                 = []
log_retention_days                 = 30

scaling_plan_schedule = {
  ramp_up_start_time        = "08:00"
  peak_start_time           = "09:00"
  ramp_down_start_time      = "16:00"
  off_peak_start_time       = "17:00"
  ramp_up_min_hosts_percent = 0
  ramp_down_min_hosts_pct   = 0
}
