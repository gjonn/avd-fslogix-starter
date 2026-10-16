module "session_hosts" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.21.0"

  for_each = local.session_hosts

  name                = each.key
  computer_name       = each.key
  resource_group_name = module.resource_group.name
  location            = var.location
  zone                = each.value.zone
  tags                = local.tags
  enable_telemetry    = var.enable_telemetry

  os_type                    = "Windows"
  sku_size                   = var.session_host_sku
  license_type               = "Windows_Client"
  source_image_reference     = var.session_host_image
  secure_boot_enabled        = true
  vtpm_enabled               = true
  encryption_at_host_enabled = var.encryption_at_host_enabled
  boot_diagnostics           = true

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = var.session_host_os_disk_type
  }

  # needed for entra join
  managed_identities = {
    system_assigned = true
  }

  account_credentials = {
    admin_credentials = {
      username                           = "avdadmin"
      generate_admin_password_or_ssh_key = true
    }
    key_vault_configuration = {
      resource_id = module.key_vault.resource_id
      secret_configuration = {
        name = "${each.key}-admin-password"
      }
    }
    password_authentication_disabled = false
  }

  network_interfaces = {
    nic0 = {
      name = "${module.naming.network_interface.name}-${each.key}"
      ip_configurations = {
        ipconfig0 = {
          name                          = "ipconfig0"
          private_ip_subnet_resource_id = module.vnet.subnets["session_hosts"].resource_id
        }
      }
      accelerated_networking_enabled = true
    }
  }

  extensions = {
    entra_join = {
      name                       = "AADLoginForWindows"
      publisher                  = "Microsoft.Azure.ActiveDirectory"
      type                       = "AADLoginForWindows"
      type_handler_version       = "2.0"
      auto_upgrade_minor_version = true
      deploy_sequence            = 1
      settings = var.intune_enrollment_enabled ? jsonencode({
        mdmId = "0000000a-0000-0000-c000-000000000000"
      }) : null
    }
  }

  # fslogix before registration so nobody lands on an unconfigured host
  run_commands = {
    configure_fslogix = {
      name            = "configure-fslogix"
      location        = var.location
      deploy_sequence = 2
      script_source = {
        script = file("${path.module}/scripts/Set-FslogixConfig.ps1")
      }
      parameters = {
        vhd_location    = { name = "VhdLocation", value = local.fslogix_vhd_location }
        profile_size_mb = { name = "ProfileSizeMB", value = tostring(var.fslogix_profile_size_mb) }
      }
    }
    register_host = {
      name            = "register-avd-agent"
      location        = var.location
      deploy_sequence = 3
      script_source = {
        script = file("${path.module}/scripts/Register-AvdSessionHost.ps1")
      }
    }
  }

  run_commands_secrets = {
    register_host = {
      protected_parameters = {
        token = { name = "RegistrationToken", value = module.host_pool.registrationinfo_token }
      }
    }
  }

  depends_on = [
    module.fslogix_storage,
    module.vnet,
    time_sleep.key_vault_rbac,
  ]
}

locals {
  fslogix_vhd_location = "\\\\${module.fslogix_storage.name}.file.core.windows.net\\${local.fslogix_share_name}"
}
