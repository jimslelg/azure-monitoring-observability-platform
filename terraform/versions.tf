terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110, < 4.0"
    }
  }

  # State lives in Azure Storage; values are injected per environment by the
  # pipeline (terraform init -backend-config=...) so no environment names are
  # hard-coded here.
  backend "azurerm" {}
}
