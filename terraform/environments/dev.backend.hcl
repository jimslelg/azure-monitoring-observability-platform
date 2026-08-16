# terraform init -backend-config=environments/dev.backend.hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "stamoptfstatedev"
container_name       = "tfstate"
key                  = "amop-dev.tfstate"
use_oidc             = true
use_azuread_auth     = true
