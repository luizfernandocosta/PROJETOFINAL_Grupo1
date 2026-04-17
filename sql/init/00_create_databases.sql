-- Cria os bancos de dados e usuários dedicados por serviço

CREATE DATABASE inmet_db;

CREATE DATABASE airflow_db;

CREATE DATABASE metabase_db;

CREATE USER airflow_user WITH PASSWORD 'airflow_pass';
GRANT ALL PRIVILEGES ON DATABASE airflow_db TO airflow_user;

CREATE USER analytics_user WITH PASSWORD 'analytics_pass';
GRANT ALL PRIVILEGES ON DATABASE inmet_db TO analytics_user;

GRANT ALL PRIVILEGES ON DATABASE metabase_db TO analytics_user;

GRANT ALL PRIVILEGES ON DATABASE inmet_db TO inmet_user;
GRANT ALL PRIVILEGES ON DATABASE airflow_db TO inmet_user;
GRANT ALL PRIVILEGES ON DATABASE metabase_db TO inmet_user;