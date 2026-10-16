output "resource_group_name" {
  description = "Resource group containing the deployment."
  value       = module.resource_group.name
}

output "host_pool_id" {
  description = "Resource ID of the AVD host pool."
  value       = module.host_pool.resource_id
}

output "workspace_id" {
  description = "Resource ID of the AVD workspace."
  value       = module.workspace.resource_id
}

output "session_host_names" {
  description = "Names of the deployed session hosts."
  value       = keys(module.session_hosts)
}

output "fslogix_vhd_location" {
  description = "UNC path FSLogix uses for profile containers."
  value       = local.fslogix_vhd_location
}

output "fslogix_storage_account_name" {
  description = "Storage account holding FSLogix profiles. Grant admin consent to its Entra app after the first deploy."
  value       = module.fslogix_storage.name
}

output "key_vault_name" {
  description = "Key Vault holding session host admin passwords."
  value       = module.key_vault.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace receiving AVD diagnostics."
  value       = module.log_analytics.resource_id
}
