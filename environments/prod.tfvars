environment = "prod"
location    = "eastus2"

address_space = "10.20.0.0/22"

session_host_count     = 4
session_host_sku       = "Standard_D8ads_v5"
host_pool_max_sessions = 10

key_vault_purge_protection_enabled = true
availability_zones                 = ["1", "2", "3"]
log_retention_days                 = 90
intune_enrollment_enabled          = true
