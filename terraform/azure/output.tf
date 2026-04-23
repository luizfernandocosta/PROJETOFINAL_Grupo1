output "airflow_url" {
  description = "URL do Airflow Webserver"
  value       = "http://${azurerm_container_group.airflow.fqdn}:8080"
}

output "postgresql_fqdn" {
  description = "FQDN do PostgreSQL"
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "connection_string_warehouse" {
  description = "Connection string do banco warehouse (para dbt)"
  value       = "postgresql+psycopg2://${var.postgres_admin_user}:PASSWORD@${azurerm_postgresql_flexible_server.this.fqdn}:5432/warehouse?sslmode=require"
  sensitive   = true
}

output "storage_account_key" {
  description = "Chave do Storage Account"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "cmd_upload_dags" {
  value = "az storage blob upload-batch --account-name ${var.storage_account_name} --destination dags --source ./dags/"
}

output "cmd_upload_dbt" {
  value = "az storage blob upload-batch --account-name ${var.storage_account_name} --destination dbt --source ./dbt/"
}

output "cmd_view_airflow_logs" {
  value = "az container logs --resource-group ${var.resource_group_name} --name aci-airflow-${var.environment} --container-name airflow-scheduler --follow"
}

output "cmd_view_webserver_logs" {
  value = "az container logs --resource-group ${var.resource_group_name} --name aci-airflow-${var.environment} --container-name airflow-webserver --follow"
}