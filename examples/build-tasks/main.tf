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
  }
}

module "tasks" {
  source  = "codectl/acr/azure//modules/tasks"
  version = "~> 1.0"

  tasks = {
    build_nginx = {
      container_registry_id = module.acr.registry.id

      platform = {
        os           = "Linux"
        architecture = "amd64"
      }

      encoded_step = {
        task_content = base64encode(<<-EOF
        version: v1.1.0
        steps:
        - cmd: bash:latest bash -c "echo 'FROM nginx:alpine' > Dockerfile"
        - build: -t $Registry/nginx:latest .
        - push:
        - $Registry/nginx:latest
        EOF
        )
      }
    }
  }
}
