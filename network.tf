module "nsg_session_hosts" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.6.0"

  name             = "${module.naming.network_security_group.name}-hosts"
  parent_id        = module.resource_group.resource_id
  location         = var.location
  tags             = local.tags
  enable_telemetry = var.enable_telemetry

  # nothing inbound needed, AVD is reverse connect
  security_rules = {}
}

module "nat_gateway" {
  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = "0.3.2"

  name             = module.naming.nat_gateway.name
  parent_id        = module.resource_group.resource_id
  location         = var.location
  tags             = local.tags
  enable_telemetry = var.enable_telemetry

  # default outbound is off on the subnets, hosts still need egress for the agent/updates
  public_ips = {
    primary = { name = module.naming.public_ip.name }
  }
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.22.3"

  name             = module.naming.virtual_network.name
  parent_id        = module.resource_group.resource_id
  location         = var.location
  address_space    = [var.address_space]
  tags             = local.tags
  enable_telemetry = var.enable_telemetry

  subnets = {
    session_hosts = {
      name             = "${module.naming.subnet.name}-hosts"
      address_prefixes = [local.subnets.session_hosts]
      network_security_group = {
        id = module.nsg_session_hosts.resource_id
      }
      nat_gateway = {
        id = module.nat_gateway.resource_id
      }
    }
    private_endpoints = {
      name             = "${module.naming.subnet.name}-pe"
      address_prefixes = [local.subnets.private_endpoints]
    }
  }
}

module "private_dns_file" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"

  domain_name      = "privatelink.file.core.windows.net"
  parent_id        = module.resource_group.resource_id
  tags             = local.tags
  enable_telemetry = var.enable_telemetry

  virtual_network_links = {
    avd = {
      name               = "link-${module.naming.virtual_network.name}"
      virtual_network_id = module.vnet.resource_id
    }
  }
}
