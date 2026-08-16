# terraform init -backend-config=environments/prod.backend.hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "stamoptfstateprod"
container_name       = "tfstate"
key                  = "amop-prod.tfstate"
use_oidc             = true
use_azuread_auth     = true
