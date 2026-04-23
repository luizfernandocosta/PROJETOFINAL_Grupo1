# ---------- Resource Group ----------
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ---------- PostgreSQL Flexible Server ----------
resource "azurerm_postgresql_flexible_server" "this" {
  name                   = var.postgres_server_name
  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  version                = var.postgres_version
  administrator_login    = var.postgres_admin_user
  administrator_password = var.postgres_password

  sku_name   = var.postgres_sku
  storage_mb = var.postgres_storage_mb
  zone       = "1"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ---------- Firewall Rules ----------
resource "azurerm_postgresql_flexible_server_firewall_rule" "rules" {
  for_each = { for rule in var.allowed_ip_ranges : rule.name => rule }

  name             = each.value.name
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
}

# Permitir acesso de serviços Azure (ex: App Service, AKS)
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# ---------- Databases ----------
resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each  = toset(var.postgres_databases)

  name      = each.value
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# ---------- Configurações do Servidor ----------
resource "azurerm_postgresql_flexible_server_configuration" "log_connections" {
  name      = "log_connections"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_checkpoints" {
  name      = "log_checkpoints"
  server_id = azurerm_postgresql_flexible_server.this.id
  value     = "on"
}