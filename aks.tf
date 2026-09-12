data "azurerm_client_config" "current" {}

locals {
  project_name = "project-x"
  environment  = "sbx"
  aks_admins = toset([
    # Whoever is running (pipeline?). Will flap, though.
    data.azurerm_client_config.current.object_id,
    # Your personal user ID: az ad signed-in-user show --query id -o tsv
    "1263d89e-4b6d-44cf-9149-75c19a3412e5",
  ])
}

resource "azurerm_resource_group" "this" {
  name     = "${local.project_name}-${local.environment}-aks"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "${local.project_name}-${local.environment}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  dns_prefix          = "${local.project_name}-${local.environment}"
  node_resource_group = "${azurerm_resource_group.this.name}-nodes"

  node_provisioning_profile {
    mode = "Manual"
  }

  default_node_pool {
    name       = "system"
    node_count = 1
    vm_size    = "Standard_D2as_v5"
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true
  azure_active_directory_role_based_access_control {
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = []
    azure_rbac_enabled     = true
  }
  local_account_disabled = true
}

resource "azurerm_role_assignment" "kube_admin" {
  for_each = local.aks_admins

  scope                = resource.azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = each.key
}
