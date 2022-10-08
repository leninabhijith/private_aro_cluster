terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.45.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.1"
    }
  }
  /*backend "azurerm" {
    resource_group_name  = "Backend_rg"
    storage_account_name = "backendsa01"
    container_name       = "tfstate"
    key                  = "support-infra.tfstate"
  }*/
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}