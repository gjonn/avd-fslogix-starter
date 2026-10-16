# environment

variable "environment" {
  description = "Short environment name, used in resource names and tags (dev, test, prod)."
  type        = string

  validation {
    condition     = can(regex("^(dev|test|prod)$", var.environment))
    error_message = "environment must be one of: dev, test, prod."
  }
}

variable "workload" {
  description = "Short workload name, used in resource names."
  type        = string
  default     = "avd"

  validation {
    condition     = can(regex("^[a-z0-9]{2,6}$", var.workload))
    error_message = "workload must be 2-6 lowercase letters or digits."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "tags" {
  description = "Extra tags merged onto the standard tag set."
  type        = map(string)
  default     = {}
}

variable "enable_telemetry" {
  description = "Allow AVM modules to send usage telemetry to Microsoft."
  type        = bool
  default     = false
}

# entra groups (set via TF_VAR_*)

variable "avd_users_group_object_id" {
  description = "Object ID of the Entra ID group whose members can sign in to AVD and use FSLogix storage."
  type        = string
}

variable "avd_admins_group_object_id" {
  description = "Object ID of the Entra ID group that gets admin sign-in on session hosts and can set NTFS ACLs on the profile share. Leave null to skip."
  type        = string
  default     = null
}

# networking

variable "address_space" {
  description = "Address space for the AVD virtual network."
  type        = string
}

variable "subnet_newbits" {
  description = "Bits added to the VNet prefix to size each subnet (e.g. /22 + 2 = /24)."
  type        = number
  default     = 2
}

variable "availability_zones" {
  description = "Zones that session hosts are spread across. Use an empty list in regions without zones."
  type        = list(string)
  default     = ["1", "2", "3"]
}

# avd control plane

variable "host_pool_max_sessions" {
  description = "Maximum concurrent sessions per session host."
  type        = number
  default     = 8
}

variable "host_pool_load_balancer_type" {
  description = "BreadthFirst spreads users for performance; DepthFirst packs hosts to save cost."
  type        = string
  default     = "BreadthFirst"
}

variable "scaling_plan_time_zone" {
  description = "Time zone the scaling plan schedule is evaluated in."
  type        = string
  default     = "Eastern Standard Time"
}

variable "scaling_plan_schedule" {
  description = "Weekday scaling schedule. Times are HH:MM in scaling_plan_time_zone."
  type = object({
    ramp_up_start_time        = string
    peak_start_time           = string
    ramp_down_start_time      = string
    off_peak_start_time       = string
    ramp_up_min_hosts_percent = number
    ramp_down_min_hosts_pct   = number
  })
  default = {
    ramp_up_start_time        = "07:00"
    peak_start_time           = "09:00"
    ramp_down_start_time      = "17:00"
    off_peak_start_time       = "19:00"
    ramp_up_min_hosts_percent = 20
    ramp_down_min_hosts_pct   = 10
  }
}

# session hosts

variable "session_host_count" {
  description = "Number of session hosts to deploy."
  type        = number
  default     = 2
}

variable "session_host_sku" {
  description = "VM size for session hosts."
  type        = string
  default     = "Standard_D4ads_v5"
}

variable "session_host_image" {
  description = "Marketplace image for session hosts. Windows 11 multi-session images ship with FSLogix preinstalled."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-24h2-avd"
    version   = "latest"
  }
}

variable "session_host_os_disk_type" {
  description = "Managed disk type for session host OS disks."
  type        = string
  default     = "Premium_LRS"
}

variable "encryption_at_host_enabled" {
  description = "Encrypt temp and cache disks on the host. Requires the EncryptionAtHost feature to be registered on the subscription."
  type        = bool
  default     = true
}

variable "intune_enrollment_enabled" {
  description = "Enroll session hosts in Intune during Entra ID join."
  type        = bool
  default     = false
}

# fslogix storage

variable "fslogix_share_quota_gb" {
  description = "Provisioned size of the FSLogix profile share in GiB (Premium Files minimum is 100)."
  type        = number
  default     = 100
}

variable "fslogix_profile_size_mb" {
  description = "Maximum size of each FSLogix profile container in MB."
  type        = number
  default     = 30000
}

# key vault and monitoring

variable "key_vault_purge_protection_enabled" {
  description = "Purge protection on the Key Vault. Keep true in prod; false lets dev be torn down cleanly."
  type        = bool
  default     = true
}

variable "key_vault_allowed_ip_ranges" {
  description = "Public IP ranges (CIDR) allowed through the Key Vault firewall, e.g. your deployment agent."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Log Analytics retention in days."
  type        = number
  default     = 30
}
