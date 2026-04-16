-- =============================================================
-- 00_create_databases.sql
-- Executado automaticamente pelo PostgreSQL na primeira inicialização.
-- Cria os bancos de dados e usuários dedicados por serviço.
-- =============================================================

-- Banco principal de dados do projeto
CREATE DATABASE inmet_db;

-- Banco de metadados do Airflow (separado para não misturar com dados)
CREATE DATABASE airflow_db;

-- Banco de metadados do Metabase (evita perda de dashboards ao reiniciar)
CREATE DATABASE metabase_db;

-- Usuário dedicado para Airflow (acesso só ao airflow_db)
CREATE USER airflow_user WITH PASSWORD 'airflow_pass';
GRANT ALL PRIVILEGES ON DATABASE airflow_db TO airflow_user;

-- Usuário dedicado para analytics (dbt + Metabase → inmet_db)
CREATE USER analytics_user WITH PASSWORD 'analytics_pass';
GRANT ALL PRIVILEGES ON DATABASE inmet_db TO analytics_user;

-- Usuário dedicado para Metabase metadata DB
GRANT ALL PRIVILEGES ON DATABASE metabase_db TO analytics_user;

-- O usuário principal (inmet_user) mantém acesso total a tudo
GRANT ALL PRIVILEGES ON DATABASE inmet_db TO inmet_user;
GRANT ALL PRIVILEGES ON DATABASE airflow_db TO inmet_user;
GRANT ALL PRIVILEGES ON DATABASE metabase_db TO inmet_user;
