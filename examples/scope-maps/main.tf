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

module "kv" {
  source  = "codectl/kv/azure"
  version = "~> 1.0"

  vault = {
    name                = module.naming.key_vault.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    secrets = {
      random_string = {
        token2-1 = {
          length          = 24
          special         = false
          expiration_date = "2027-08-22T17:57:36+08:00"
        }
        token2-2 = {
          length          = 24
          special         = false
          expiration_date = "2027-08-22T17:57:36+08:00"
        }
      }
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
    vault               = module.kv.vault.id
    sku                 = "Premium"

    scope_maps = {
      prd = {
        actions = [
          "repositories/repo1/content/read",
          "repositories/repo1/content/write"
        ]
        tokens = {
          token1 = {
            # generated from module
            expiry = "2027-02-22T17:57:36+08:00"
          }
          token2 = {
            # generated outside module
            expiry = "2027-08-22T17:57:36+08:00"
            secret = {
              password1 = module.kv.secrets.token2-1.value
              password2 = module.kv.secrets.token2-2.value
            }
          }
        }
      }
    }
  }
}
