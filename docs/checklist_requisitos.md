# Checklist de Requisitos Técnicos por Ferramenta

Legenda: **Integral** | **Parcial** | **Não realizado**

---

## Script Python (Ingestão)

| Requisito | Status | Evidência |
|-----------|--------|-----------|
| Conector de origem: File (CSV) | Integral | `ingestion/ingest_inmet.py` — faz download de ZIPs do INMET, extrai CSVs e faz parse com pandas |
| Conector de destino: PostgreSQL (schema raw) | Integral | Carga via SQLAlchemy na tabela `raw.inmet_weather_raw` |
| Sincronização full refresh ou incremental | Integral | Variável `LOAD_MODE` suporta `full_refresh` (trunca e recarrega) e `incremental` (via `raw.ingestion_log`) |
| Script containerizado | Integral | `ingestion/Dockerfile` com imagem `python:3.11-slim` |
| Orquestrado via Airflow | Integral | Task `python_ingestion_raw` na DAG `inmet_weather_pipeline` executa o script via `PythonOperator` |

---

## PostgreSQL

| Requisito | Status | Evidência |
|-----------|--------|-----------|
| Arquitetura medalhão: três schemas (raw, silver, gold) | Integral | `sql/init/01_schemas.sql` cria os três schemas |
| Tabelas raw idênticas às fontes | Integral | `raw.inmet_weather_raw` preserva todas as colunas originais dos CSVs como TEXT, com metadados adicionais |
| Tabelas gold apropriadas para visualizações | Integral | `dim_station`, `dim_date`, `dim_time`, `fact_weather_hourly` — modelo estrela completo |

---

## Great Expectations

| Requisito | Status | Evidência |
|-----------|--------|-----------|
| Suite aplicada exclusivamente sobre schema raw | Integral | `great_expectations/expectations/raw_inmet_weather_suite.json` valida `raw.inmet_weather_raw` |
| Mínimo 3 expectativas | Integral | 16 expectativas: 10 `expect_column_to_exist`, 2 `expect_column_values_to_not_be_null`, 3 `expect_column_values_to_be_between`, 1 `expect_table_row_count_to_be_between` |
| Checkpoint salvo e executável via CLI ou Python | Integral | `great_expectations/checkpoints/raw_inmet_weather_checkpoint.yml` + `great_expectations/run_checkpoint.py` executável via CLI |

---

## dbt

| Requisito | Status | Evidência |
|-----------|--------|-----------|
| Modelos stg_* (silver) | Integral | `models/staging/stg_inmet_weather.sql` — limpeza, tipagem e conversão de timezone |
| Modelos dim_* / fact_* (gold) | Integral | `dim_station`, `dim_date`, `dim_time`, `fact_weather_hourly` |
| Pelo menos 1 tabela fato e 2 dimensões | Integral | 1 fato (`fact_weather_hourly`) + 3 dimensões (`dim_station`, `dim_date`, `dim_time`) |
| Uso de surrogate keys (dbt_utils.generate_surrogate_key) | Integral | Todas as tabelas gold usam `dbt_utils.generate_surrogate_key` |
| Macro customizada | Integral | 3 macros: `precipitation_intensity_bucket`, `wind_risk_level`, `uf_to_timezone` + `generate_schema_name` |
| Testes genéricos (unique, not_null, accepted_values) | Integral | Definidos em `models/schema.yml` para colunas críticas de todas as tabelas |
| Pelo menos 2 testes singulares | Integral | `tests/assert_no_future_dates.sql` + `tests/assert_humidity_range.sql` |
| Documentação (dbt docs generate) com descrições e linhagem | Integral | `schema.yml` com descrições completas; container `dbt-docs` serve documentação na porta 8081 |

---

## Apache Airflow

| Requisito | Status | Evidência |
|-----------|--------|-----------|
| DAG com dependência explícita | Integral | `ingest_raw >> airbyte_sensor >> ge_validation >> dbt_deps >> dbt_run >> dbt_test >> dbt_docs` |
| Sensor Airbyte | Parcial | O airbyte foi implementado de forma parcial, para que ele funcione por completo teria que expor o banco local para a internet para que ele conseguisse acessar, e por se tratar de um experimento local, não vale a pena o risco de expor, mas caso contrário ele funciona normalmente com a DAG do airflow |
| GreatExpectationsOperator | Integral | Usa provider oficial quando disponível; fallback para `BashOperator` com `run_checkpoint.py` |
| BashOperator para dbt run e dbt test | Integral | Tasks `dbt_deps`, `dbt_run`, `dbt_test`, `dbt_docs_generate` |
| Tratamento de falhas (retry, alerta) | Integral | `retries: 2`, `retry_delay: 5 min`, `email_on_failure` configurável |

---

## Visualização

| Requisito | Status | Evidência |
|-----------|--------|-----------|
| Conexão com schema gold | Integral | Metabase conecta via `analytics_user` ao banco `inmet_db`, schema `gold` |
| Pelo menos 2 dashboards | Integral | 3 dashboards: (1) Volume de chuva por estação e mês, (2) Temperatura e umidade médias por dia, (3) Eventos de chuva intensa por região. Queries em `dashboards/dashboard_queries.sql` |

---

## Docker

| Requisito | Status | Evidência |
|-----------|--------|-----------|
| docker-compose.yml | Integral | Arquivo na raiz com todos os serviços |
| Serviço postgres | Integral | `postgres:16` com healthcheck e volumes persistentes |
| Serviço airflow | Integral | Imagem customizada (`airflow/Dockerfile`) com init, webserver e scheduler |
| Serviço visualização (Metabase) | Integral | `metabase/metabase:v0.50.13` com banco de metadados persistente no PostgreSQL |
| Serviço great-expectations (integrado ao Airflow) | Integral | Integrado via `requirements-airflow.txt` na imagem customizada do Airflow |
| Volumes persistentes para dados | Integral | `postgres-data/` para PostgreSQL, `metabase-data/` para Metabase |
