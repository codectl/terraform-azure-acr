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

module "identity" {
  source  = "codectl/uai/azure"
  version = "~> 1.0"

  identity = {
    name                = module.naming.user_assigned_identity.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "tasks" {
  source  = "codectl/acr/azure//modules/tasks"
  version = "~> 1.0"

  tasks = {
    say_hello = {
      agent_setting = {
        cpu = 2
      }

      platform = {
        architecture = "amd64"
        os           = "Linux"
      }

      container_registry_id = module.acr.registry.id

      encoded_step = {
        task_content = base64encode(<<EOF
        version: v1.1.0
        steps:
        - cmd: docker run --rm alpine:latest /bin/sh -c "echo 'Hello, World!'"
        EOF
        )
      }
      timer_triggers = {
        hello = {
          name     = "hello_trigger"
          schedule = "*/5 * * * *"
          enabled  = true
        }
      }
      identity = {
        type         = "UserAssigned"
        identity_ids = [module.identity.identity.id]
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
    sku                 = "Premium"
  }
}
