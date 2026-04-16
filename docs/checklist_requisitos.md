# Checklist de Requisitos Técnicos por Ferramenta

## Airbyte / Script Python

- [x] Conector de origem (File CSV): **Cumprido** — script Python lê ZIPs anuais do portal INMET
- [x] Conector destino PostgreSQL `raw`: **Cumprido** — `raw.inmet_weather_raw`
- [x] Full refresh ou incremental: **Cumprido** — controlado por `LOAD_MODE` no `.env`
- [x] Script containerizado e orquestrado via Airflow: **Cumprido** — `inmet-ingestion` + task `python_ingestion_raw`

## PostgreSQL

- [x] Arquitetura medalhão (`raw` / `silver` / `gold`): **Cumprido** — `sql/init/01_schemas.sql`
- [x] Bancos separados por serviço (`inmet_db`, `airflow_db`, `metabase_db`): **Cumprido** — `sql/init/00_create_databases.sql`
- [~] Tabelas `raw.*` idênticas à fonte: **Parcial** — colunas normalizadas para snake_case + metadados de carga adicionados (`source_file`, `source_year`, `loaded_at`)
- [x] Tabelas gold apropriadas para visualização: **Cumprido** — modelo estrela completo

## Great Expectations

- [x] Suite aplicada exclusivamente sobre `raw`: **Cumprido**
- [x] Mínimo 3 expectativas: **Cumprido** — 16 expectativas implementadas
- [x] `expect_column_to_exist` para 11 colunas obrigatórias: **Cumprido**
- [x] `expect_column_values_to_not_be_null` em `data` e `meta_codigo_wmo`: **Cumprido**
- [x] `expect_column_values_to_be_between` para umidade, temperatura e precipitação: **Cumprido**
- [x] Precipitação não pode ser negativa: **Cumprido** (`min_value=0, mostly=0.999`)
- [x] Row count dentro de faixa esperada: **Cumprido** (1.000.000 – 10.000.000)
- [x] Checkpoint executável via CLI/Python: **Cumprido** — `great_expectations/run_checkpoint.py`

## dbt

- [x] Modelos `stg_*` (silver): **Cumprido** — `stg_inmet_weather`
- [x] Modelos `dim_*` / `fact_*` (gold): **Cumprido** — `dim_station`, `dim_date`, `dim_time`, `fact_weather_hourly`
- [x] 1 tabela fato + 2 dimensões (mínimo): **Cumprido** — 1 fato + 3 dimensões
- [x] Surrogate keys com `dbt_utils.generate_surrogate_key`: **Cumprido** em todos os modelos gold
- [x] Macro customizada usada em modelo gold: **Cumprido** — `precipitation_intensity_bucket`, `wind_risk_level`, `uf_to_timezone`
- [x] Testes genéricos (`unique`, `not_null`, `accepted_values`): **Cumprido** — `schema.yml`
- [x] Pelo menos 2 testes singulares: **Cumprido** — `assert_no_future_dates.sql`, `assert_humidity_range.sql`
- [x] Documentação com linhagem (`dbt docs generate`): **Cumprido** — servida em `localhost:8081`
- [x] `dim_time` separando hora do fato: **Cumprido** — `dim_time.sql` + FK `time_sk` no fato
- [x] Conversão UTC → horário local por estado: **Cumprido** — coluna `data_hora_local` na staging via macro `uf_to_timezone`
- [x] Dados de vento e pressão explorados: **Cumprido** — `vento_velocidade_ms`, `vento_direcao_graus`, `vento_rajada_ms`, `pressao_atm_hpa` na staging e no fato com macro `wind_risk_level`

## Airflow

- [x] DAG com dependência explícita: **Cumprido** — `ingestion → airbyte_sensor → GE → dbt_deps → dbt_run → dbt_test → dbt_docs_generate`
- [x] Tratamento de falhas (retry): **Cumprido** — `retries=2`, `retry_delay=5min`
- [x] `dbt docs serve` removido da DAG: **Cumprido** — servido como container dedicado `inmet-dbt-docs`

## Visualização

- [x] Conexão com schema `gold`: **Cumprido** — Metabase aponta para `inmet_db`
- [x] Pelo menos 2 dashboards: **Cumprido** — queries base em `dashboards/dashboard_queries.sql`

## Docker

- [x] `docker-compose.yml` com todos os serviços: **Cumprido** — `postgres`, `airflow-init`, `airflow-webserver`, `airflow-scheduler`, `dbt-docs`, `metabase`, `inmet-ingestion`
- [x] Airflow com imagem customizada (deps pré-instaladas): **Cumprido** — `airflow/Dockerfile`
- [x] Volumes persistentes: **Cumprido** — `postgres-data/`, `metabase-data/`
- [x] Metabase com banco de metadados externalizado no Postgres: **Cumprido** — `metabase_db`
- [x] Portas configuráveis via `.env`: **Cumprido** — `AIRFLOW_PORT`, `METABASE_PORT`, `DBT_DOCS_PORT`
- [~] Serviço Airbyte: **Parcial** — placeholder para evolução futura; ingestão via script Python
