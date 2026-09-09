resource "azurerm_postgresql_flexible_server" "data" {
  name                = "psql-bobhub-v03-shared-data"
  resource_group_name = azurerm_resource_group.data.name
  location            = azurerm_resource_group.data.location

  version = "16"

  administrator_login    = "bobhubadmin"
  administrator_password = var.postgresql_admin_password

  sku_name = "B_Standard_B1ms"

  storage_mb   = 32768
  storage_tier = "P4"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = false

  public_network_access_enabled = true

  authentication {
    password_auth_enabled         = true
    active_directory_auth_enabled = false
  }

  lifecycle {
    ignore_changes = [
      zone
    ]
  }

  tags = {
    project     = "BobHub"
    version     = "v0.3.0"
    environment = var.environment
    component   = "shared-data"
    managed-by  = "Terraform"
  }
}

resource "azurerm_postgresql_flexible_server_database" "bobhub" {
  name      = "bobhub"
  server_id = azurerm_postgresql_flexible_server.data.id

  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "oci_backend" {
  name      = "allow-oci-backend"
  server_id = azurerm_postgresql_flexible_server.data.id

  start_ip_address = var.oci_nat_public_ip
  end_ip_address   = var.oci_nat_public_ip
}
