terraform {
  cloud {
    organization = "bobhub-azure-data"

    workspaces {
      name = "bobhub-v03-azure-data"
    }
  }

  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}