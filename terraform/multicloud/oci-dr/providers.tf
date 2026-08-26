terraform {
  cloud {
    organization = "bobhub-oci"

    workspaces {
      name = "bobhub-v03-oci-dr"
    }
  }

  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 8.0, < 9.0"
    }
  }
}

provider "oci" {
  config_file_profile = "DEFAULT"
}