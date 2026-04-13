# Documento de Configuração do Ambiente (Passo a Passo)

## 1. Instalar pré-requisitos

1. Docker Desktop (Windows/Mac) ou Docker Engine + Docker Compose (Linux)
2. Git (opcional, para versionamento)

## 2. Clonar repositório

```bash
git clone <URL_DO_REPOSITORIO>
cd trabalho_final
```

## 3. Configurar variáveis

```bash
cp .env.example .env
```

Ajuste, se necessário:

- `POSTGRES_PASSWORD`
- `INMET_YEARS` (ex.: `2024,2025`)

## 4. Subir ambiente

```bash
docker compose up -d --build
```

## 5. Verificar containers

```bash
docker compose ps
```

Esperado: `postgres`, `airflow-webserver`, `airflow-scheduler`, `metabase` e `inmet-ingestion`.

## 6. Executar pipeline no Airflow

1. Acesse `http://localhost:8080`
2. Login: `admin` / `admin`
3. Ative a DAG `inmet_weather_pipeline`
4. Execute manualmente a DAG (botão Play)

## 7. Verificar qualidade (GE)

Arquivo de saída:

- `great_expectations/uncommitted/validation_results/raw_inmet_weather_checkpoint.json`

## 8. Verificar transformação (dbt)

No Airflow, as tasks `dbt_run`, `dbt_test` e `dbt_docs_generate` devem finalizar com sucesso.

## 9. Configurar Metabase

1. Acesse `http://localhost:3000`
2. Conecte ao PostgreSQL:
   - Host: `postgres` (ou `localhost` fora de container)
   - Port: `5432`
   - Database: `weather_dw`
   - User: `edp`
   - Password: `edp123`
3. Crie duas coleções/dashboard usando queries de `dashboards/dashboard_queries.sql`

## 10. Solução de problemas comuns

1. Porta ocupada (`5432`, `8080`, `3000`): ajuste no `docker-compose.yml`
2. Falha de conexão no Airflow: aguarde `postgres` ficar saudável e reinicie scheduler/webserver
3. Falha no download INMET: valide conexão com internet e URLs anuais
