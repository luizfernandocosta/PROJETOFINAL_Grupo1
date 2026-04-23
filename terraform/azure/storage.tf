resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = { Environment = var.environment }
}

resource "azurerm_storage_container" "dags" {
  name                  = "dags"
  storage_account_name = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "dbt" {
  name                  = "dbt"
  storage_account_name = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"
  storage_account_name = azurerm_storage_account.this.name
  container_access_type = "private"
}