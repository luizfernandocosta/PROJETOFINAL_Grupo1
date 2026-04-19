#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT 'CREATE DATABASE airflow_db'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'airflow_db')\gexec

    SELECT 'CREATE DATABASE metabase_db'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'metabase_db')\gexec

    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'airflow_user') THEN
            CREATE USER airflow_user WITH PASSWORD '${AIRFLOW_DB_PASSWORD:-airflow_pass}';
        END IF;
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'analytics_user') THEN
            CREATE USER analytics_user WITH PASSWORD '${ANALYTICS_PASSWORD:-analytics_pass}';
        END IF;
    END
    \$\$;

    GRANT ALL PRIVILEGES ON DATABASE airflow_db TO airflow_user;
    GRANT ALL PRIVILEGES ON DATABASE inmet_db TO analytics_user;
    GRANT ALL PRIVILEGES ON DATABASE metabase_db TO analytics_user;
    GRANT ALL PRIVILEGES ON DATABASE inmet_db TO inmet_user;
    GRANT ALL PRIVILEGES ON DATABASE airflow_db TO inmet_user;
    GRANT ALL PRIVILEGES ON DATABASE metabase_db TO inmet_user;
EOSQL
