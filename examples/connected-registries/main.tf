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
    name                  = module.naming.container_registry.name_unique
    location              = module.rg.groups.demo.location
    resource_group_name   = module.rg.groups.demo.name
    sku                   = "Premium"
    data_endpoint_enabled = true

    scope_maps = {
      sync = {
        actions = [
          "repositories/*/content/read",
          "repositories/*/content/write",
          "repositories/*/content/delete",
          "repositories/*/metadata/read",
          "repositories/*/metadata/write",
          "gateway/edgeregistry/config/read",
          "gateway/edgeregistry/config/write",
          "gateway/edgeregistry/message/read",
          "gateway/edgeregistry/message/write",
        ]
        tokens = {
          edge = {}
        }
      }
    }

    connected_registries = {
      edge = {
        name       = "edgeregistry"
        sync_token = "sync.edge"
        mode       = "ReadWrite"
      }
    }
  }
}
