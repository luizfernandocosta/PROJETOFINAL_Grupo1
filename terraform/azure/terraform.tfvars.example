resource_group_name  = "rg-data-platform-dev"
location             = "Brazil South"
environment          = "dev"

# PostgreSQL
postgres_server_name = "inmet-postgres-dev"
postgres_version     = "16"
postgres_sku         = "B_Standard_B1ms"
postgres_storage_mb  = 32768
postgres_admin_user  = "inmet_user"
postgres_password    = "inmet_pass"
postgres_databases   = ["airflow_db", "inmet_db", "metabase_db"]

airflow_user = "airflow_user"

# O parametro abaixo libera um range de ips, ja que nao e recomendado expor banco de dados pro mundo externo
allowed_ip_ranges = [
  {
    name     = "seu-ip-aqui"
    start_ip = "0.0.0.0"
    end_ip   = "0.0.0.0"
  }
]

# Airflow
airflow_image          = "myregistry.azurecr.io/airflow-dbt:latest"
airflow_admin_user     = "admin"
airflow_admin_password = "admin"
airflow_fernet_key     = "fernet_key"

# Storage
storage_account_name = "stdataplatformdev"

# Container
container_cpu    = 2
container_memory = 4