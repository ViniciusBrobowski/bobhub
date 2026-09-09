output "resource_group_name" {
  description = "Azure Resource Group used by the BobHub shared data layer."
  value       = azurerm_resource_group.data.name
}

output "resource_group_location" {
  description = "Azure region used by the BobHub shared data layer."
  value       = azurerm_resource_group.data.location
}

output "postgresql_fqdn" {
  description = "Azure PostgreSQL Flexible Server FQDN."
  value       = azurerm_postgresql_flexible_server.data.fqdn
}

output "postgresql_database_name" {
  description = "BobHub PostgreSQL database name."
  value       = azurerm_postgresql_flexible_server_database.bobhub.name
}