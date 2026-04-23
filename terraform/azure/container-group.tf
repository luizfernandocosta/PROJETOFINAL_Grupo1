resource "azurerm_container_group" "airflow" {
  name                = "aci-airflow-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  restart_policy      = "Always"
  ip_address_type     = "Public"
  dns_name_label      = "airflow-${var.environment}"

  # ---------- Webserver ----------
  container {
    name   = "airflow-webserver"
    image  = var.airflow_image
    cpu    = var.container_cpu / 2
    memory = var.container_memory / 2

    ports {
      port     = 8080
      protocol = "TCP"
    }

    commands = [
      "bash", "-c",
      "airflow db migrate && airflow users create --username ${var.airflow_admin_user} --password ${var.airflow_admin_password} --firstname Admin --lastname User --role Admin --email admin@local.dev || true && airflow webserver --port 8080"
    ]

    environment_variables = {
      AIRFLOW__CORE__LOAD_EXAMPLES      = "False"
      AIRFLOW__CORE__EXECUTOR           = "LocalExecutor"
      AIRFLOW__WEBSERVER__EXPOSE_CONFIG = "True"
    }

    secure_environment_variables = {
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN = "postgresql+psycopg2://${var.postgres_admin_user}:${var.postgres_password}@${azurerm_postgresql_flexible_server.this.fqdn}:5432/airflow_db?sslmode=require"
      AIRFLOW__CORE__FERNET_KEY           = var.airflow_fernet_key
    }
  }

  # ---------- Scheduler ----------
  container {
    name   = "airflow-scheduler"
    image  = var.airflow_image
    cpu    = var.container_cpu / 2
    memory = var.container_memory / 2

    commands = ["airflow", "scheduler"]

    environment_variables = {
      AIRFLOW__CORE__LOAD_EXAMPLES = "False"
      AIRFLOW__CORE__EXECUTOR      = "LocalExecutor"
    }

    secure_environment_variables = {
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN = "postgresql+psycopg2://${var.postgres_admin_user}:${var.postgres_password}@${azurerm_postgresql_flexible_server.this.fqdn}:5432/airflow_db?sslmode=require"
      AIRFLOW__CORE__FERNET_KEY           = var.airflow_fernet_key
    }
  }

  tags = { Environment = var.environment }
}