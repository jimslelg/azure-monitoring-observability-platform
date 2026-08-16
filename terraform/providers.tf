provider "azurerm" {
  features {
    resource_group {
      # Monitoring resource groups accumulate alert rules and workbooks created
      # outside Terraform (e.g. by operators testing queries); never bulldoze them.
      prevent_deletion_if_contains_resources = true
    }
  }

  # Authentication is OIDC workload identity federation from the pipeline
  # (ARM_USE_OIDC, ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID).
  # No client secrets are stored anywhere in this repository.
}
