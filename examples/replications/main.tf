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

    georeplications = {
      sea = {
        location                        = "southeastasia"
        global_endpoint_routing_enabled = false
      }
      eus = {
        location                        = "eastus"
        global_endpoint_routing_enabled = false
      }
      eus2 = {
        location                        = "eastus2"
        global_endpoint_routing_enabled = true
      }
    }
  }
}
