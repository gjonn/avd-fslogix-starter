data "azurerm_client_config" "current" {}

# AVD first-party SPN - scaling plan uses it to power hosts on/off
data "azuread_service_principal" "avd" {
  client_id = "9cdead84-a844-4324-93f2-b2e6bb768d07"
}

locals {
  # keeps names under length limits
  region_short = lookup({
    eastus         = "eus"
    eastus2        = "eus2"
    centralus      = "cus"
    northcentralus = "ncus"
    southcentralus = "scus"
    westus2        = "wus2"
    westus3        = "wus3"
    canadacentral  = "cac"
    uksouth        = "uks"
    westeurope     = "weu"
    northeurope    = "neu"
    australiaeast  = "aue"
  }, lower(replace(var.location, " ", "")), substr(lower(replace(var.location, " ", "")), 0, 6))

  name_suffix = [var.workload, var.environment, local.region_short]

  tags = merge({
    workload    = var.workload
    environment = var.environment
    managed_by  = "terraform"
    repository  = "avd-fslogix-starter"
  }, var.tags)

  subnets = {
    session_hosts     = cidrsubnet(var.address_space, var.subnet_newbits, 0)
    private_endpoints = cidrsubnet(var.address_space, var.subnet_newbits, 1)
  }

  # computer names max out at 15 chars
  session_host_prefix = substr(join("-", local.name_suffix), 0, 11)
  session_hosts = {
    for i in range(var.session_host_count) :
    format("%s-%02d", local.session_host_prefix, i + 1) => {
      zone = length(var.availability_zones) > 0 ? var.availability_zones[i % length(var.availability_zones)] : null
    }
  }

  fslogix_share_name = "profiles"
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.4"

  suffix = local.name_suffix
}
