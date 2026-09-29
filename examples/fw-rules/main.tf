module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "acr" {
  source  = "codectl/acr/azure"
  version = "~> 1.0"

  registry = {
    name                = module.naming.container_registry.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    sku                 = "Premium"

    network_rule_set = {
      default_action = "Deny"
      ip_rules = {
        rule_1 = {
          ip_range = "1.0.0.0/32"
          # If single IP, you still need to put it as a range, otherwise TF will detect a change.
        }
        rule_2 = {
          ip_range = "1.0.0.1/32"
        }
      }
    }
  }
}
