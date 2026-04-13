# Checklist de Requisitos Técnicos por Ferramenta

## Airbyte/Script Python

- Conector de origem (File/DB): **Cumprido** (arquivos CSV do INMET)
- Conector destino PostgreSQL raw: **Cumprido**
- Full refresh ou incremental: **Cumprido** (`LOAD_MODE`)
- Script containerizado e orquestrado via Airflow: **Cumprido**

## PostgreSQL

- Arquitetura medalhão (raw/silver/gold): **Cumprido**
- Tabelas raw idênticas à fonte: **Parcial** (colunas normalizadas + metadados preservados)
- Tabelas gold para visualização: **Cumprido**

## Great Expectations

- Suíte na raw: **Cumprido**
- Mínimo 3 expectativas: **Cumprido**
- Checkpoint executável via CLI/Python: **Cumprido**

## dbt

- Modelos stg e dim/fact: **Cumprido**
- 1 fato + 2 dimensões: **Cumprido**
- Surrogate keys: **Cumprido**
- Macro customizada: **Cumprido**
- Testes genéricos: **Cumprido**
- Pelo menos 2 testes singulares: **Cumprido**
- Documentação com linhagem (`dbt docs`): **Cumprido**

## Airflow

- DAG com dependência explícita: **Cumprido**
- Tratamento de falhas (retry): **Cumprido**

## Visualização

- Conexão com schema gold: **Cumprido**
- Pelo menos 2 dashboards: **Cumprido** (queries prontas)

## Docker

- `docker-compose.yml` com serviços: postgres, airflow, visualização, GE integrado no Airflow: **Cumprido**
- Serviço Airbyte: **Parcial** (placeholder para evolução)
- Volumes persistentes: **Cumprido**
