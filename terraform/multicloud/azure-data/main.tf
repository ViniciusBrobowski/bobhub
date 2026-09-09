resource "azurerm_resource_group" "data" {
  name     = "rg-bobhub-v03-data"
  location = var.location

  tags = {
    project     = "BobHub"
    version     = "v0.3.0"
    environment = var.environment
    component   = "shared-data"
    managed_by  = "terraform"
  }
}