# ---------- Geral ----------
variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Região Azure"
  type        = string
  default     = "Brazil South"
}

variable "environment" {
  description = "Ambiente (dev, prod)"
  type        = string
  default     = "dev"
}

# ---------- PostgreSQL ----------
variable "postgres_server_name" {
  description = "Nome do servidor PostgreSQL Flexible"
  type        = string
}

variable "postgres_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "16"
}

variable "postgres_sku" {
  description = "SKU do servidor (B_Standard_B1ms, B_Standard_D2s_v3)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "Tamanho do storage em MB"
  type        = number
  default     = 32768
}

variable "postgres_admin_user" {
  description = "Usuário administrador do PostgreSQL"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "Senha do administrador do PostgreSQL"
  type        = string
  sensitive   = true
}

variable "postgres_databases" {
  description = "Lista de bancos de dados a serem criados"
  type        = list(string)
  default     = ["airflow", "app"]
}

# ---------- Airflow (referência) ----------
variable "airflow_user" {
  description = "Usuário do Airflow para conexão ao banco"
  type        = string
  default     = "airflow_user"
}

# ---------- Rede ----------
variable "allowed_ip_ranges" {
  description = "CIDRs permitidos para acessar o PostgreSQL"
  type = list(object({
    name     = string
    start_ip = string
    end_ip   = string
  }))
  default = []
}

# ---------- Airflow ----------
variable "airflow_image" {
  description = "Imagem Docker customizada com Airflow + dbt"
  type        = string
  default     = "myregistry.azurecr.io/airflow-dbt:latest"
}

variable "airflow_admin_user"     {
  type = string
  default = "admin"
}
variable "airflow_admin_password" {
  type = string
  sensitive = true
}
variable "airflow_fernet_key"     {
  type = string
  sensitive = true
}

# ---------- Storage ----------
variable "storage_account_name" { type = string }

# ---------- Container ----------
variable "container_cpu"    {
  type = number
  default = 2
}
variable "container_memory" {
  type = number
  default = 4
}