# Projeto Final — Fundamentos de Engenharia de Dados

Pipeline ELT completo usando dados históricos de estações automáticas do INMET.

---

## 1. Storytelling (Domínio: Agro)

Uma cooperativa agrícola precisa planejar irrigação, manejo de solo e alertas de risco climático por região. O time de operações precisa de um painel diário confiável para responder:

1. Quais estações e regiões registraram maior volume de chuva por período?
2. Como temperatura e umidade evoluem ao longo do tempo por estado/estação?
3. Quais localidades tiveram eventos de chuva intensa ou vento forte que impactam operação de campo?

---

## 2. Dataset

- **Fonte oficial:** https://portal.inmet.gov.br/dadoshistoricos
- **Tipo:** dados históricos anuais de estações automáticas (arquivos ZIP com CSVs)
- **URL usada pelo pipeline:** `https://portal.inmet.gov.br/uploads/dadoshistoricos/{ano}.zip`

---

## 3. Arquitetura

```
INMET (ZIP/CSV)
      │
      ▼
Python Ingestion ──► PostgreSQL raw
                           │
                           ▼
                   Great Expectations
                     (validação raw)
                           │
                           ▼
                       dbt silver
                    (stg_inmet_weather)
                           │
                           ▼
                       dbt gold
                   (modelo estrela)
                     dim_station
                     dim_date
                     dim_time
                     fact_weather_hourly
                           │
                           ▼
                   Metabase Dashboards

  Airflow DAG orquestra todo o fluxo acima
```

---

## 4. Estrutura do repositório

```
PROJETOFINAL_Grupo1/
├── airflow/
│   ├── Dockerfile                  # imagem customizada com dbt + GE pré-instalados
│   ├── requirements-airflow.txt
│   └── dags/
│       └── inmet_weather_pipeline.py
├── dashboards/
│   └── dashboard_queries.sql
├── dbt/
│   ├── profiles.yml
│   └── inmet_analytics/
│       ├── dbt_project.yml
│       ├── packages.yml
│       ├── macros/
│       │   ├── generate_schema_name.sql
│       │   ├── precipitation_intensity_bucket.sql
│       │   ├── uf_to_timezone.sql
│       │   └── wind_risk_level.sql
│       ├── models/
│       │   ├── schema.yml
│       │   ├── staging/
│       │   │   └── stg_inmet_weather.sql
│       │   └── marts/
│       │       ├── dim_date.sql
│       │       ├── dim_station.sql
│       │       ├── dim_time.sql
│       │       └── fact_weather_hourly.sql
│       └── tests/
│           ├── assert_humidity_range.sql
│           └── assert_no_future_dates.sql
├── docs/
│   ├── checklist_requisitos.md
│   ├── setup_guide.md
│   └── enunciado_extraido.txt
├── great_expectations/
│   ├── great_expectations.yml
│   ├── run_checkpoint.py
│   ├── checkpoints/
│   │   └── raw_inmet_weather_checkpoint.yml
│   └── expectations/
│       └── raw_inmet_weather_suite.json
├── ingestion/
│   ├── Dockerfile
│   ├── ingest_inmet.py
│   └── requirements.txt
├── sql/init/
│   ├── 00_create_databases.sql
│   └── 01_schemas.sql
├── .env.example
├── .gitignore
├── docker-compose.yml
├── requirements.txt               # deps para desenvolvimento local (sem Docker)
└── README.md
```

---

## 5. Pré-requisitos

- Docker Desktop (Windows/macOS) ou Docker Engine + Docker Compose v2 (Linux)
- Git

> Não é necessário Python, dbt ou qualquer outra dependência instalada localmente — tudo roda dentro dos containers.

---

## 6. Como executar

### 6.1 Clonar e configurar

```bash
git clone <URL_DO_REPOSITORIO>
cd PROJETOFINAL_Grupo1

cp .env.example .env
# Edite .env se quiser mudar senhas ou anos de ingestão
```

### 6.2 Subir o ambiente

```bash
docker compose up -d --build
```

Aguarde todos os containers ficarem saudáveis (cerca de 2–3 minutos na primeira vez):

```bash
docker compose ps
```

Serviços esperados:

| Container               | URL                      | Descrição                        |
|-------------------------|--------------------------|----------------------------------|
| `inmet-postgres`        | `localhost:5432`         | PostgreSQL (raw / silver / gold) |
| `inmet-airflow-webserver` | http://localhost:8080  | Airflow UI                       |
| `inmet-airflow-scheduler` | —                      | Scheduler interno                |
| `inmet-dbt-docs`        | http://localhost:8081    | Documentação dbt com lineage     |
| `inmet-metabase`        | http://localhost:3000    | Dashboards                       |

> **Porta ocupada?** Edite as variáveis `AIRFLOW_PORT`, `METABASE_PORT` ou `DBT_DOCS_PORT` no `.env` antes de subir.

### 6.3 Executar o pipeline

1. Acesse o Airflow em http://localhost:8080
2. Login: `admin` / `admin` (configurável no `.env`)
3. Ative e execute a DAG `inmet_weather_pipeline`

Ordem das tasks:

```
python_ingestion_raw
      │
      ▼
airbyte_sensor  (placeholder de dependência)
      │
      ▼
great_expectations_validation
      │
      ▼
dbt_deps ► dbt_run ► dbt_test ► dbt_docs_generate
```

### 6.4 Execução manual (fora do Docker)

```bash
# Instalar deps de desenvolvimento
pip install -r requirements.txt

# Ingestão
python ingestion/ingest_inmet.py

# Validação GE
python great_expectations/run_checkpoint.py

# dbt
cd dbt/inmet_analytics
dbt deps
dbt run --profiles-dir ../
dbt test --profiles-dir ../
dbt docs generate --profiles-dir ../
dbt docs serve --profiles-dir ../
```

---

## 7. Modelagem dbt

### Silver — `stg_inmet_weather`

Padronização de tipos, normalização de nomes, conversão UTC → horário local por estado via macro `uf_to_timezone`, inclusão de colunas de vento e pressão atmosférica.

### Gold — modelo estrela

| Tabela                | Tipo      | Descrição                                     |
|-----------------------|-----------|-----------------------------------------------|
| `dim_station`         | Dimensão  | Estações meteorológicas WMO (lat/lon, UF)     |
| `dim_date`            | Dimensão  | Calendário (ano, mês, dia, dia da semana)     |
| `dim_time`            | Dimensão  | Horário (hora, período do dia)                |
| `fact_weather_hourly` | Fato      | Observações horárias com métricas e alertas   |

**Macros customizadas:**
- `precipitation_intensity_bucket` — classifica intensidade de chuva
- `wind_risk_level` — classifica risco operacional de vento pela rajada
- `uf_to_timezone` — converte UF para timezone brasileiro
- `generate_schema_name` — controla schemas silver/gold

---

## 8. Great Expectations

Suite aplicada na camada `raw` com 16 expectativas:

- Existência das 11 colunas obrigatórias do schema INMET
- `data` e `meta_codigo_wmo` não nulos
- Umidade entre 0 e 100 (`mostly=0.98`)
- Temperatura entre -20 e 55 °C (`mostly=0.98`)
- Precipitação não negativa (`mostly=0.999`)
- Row count entre 1.000.000 e 10.000.000 (sanity check de download)

Checkpoint: `raw_inmet_weather_checkpoint`
Relatório: `great_expectations/uncommitted/validation_results/raw_inmet_weather_checkpoint.json`

---

## 9. Dashboards (Metabase)

Conecte o Metabase ao PostgreSQL (`inmet-postgres`, porta 5432, banco `inmet_db`, usuário `analytics_user`).

Queries base em `dashboards/dashboard_queries.sql`:

- **Dashboard 1:** Volume de chuva por estação, região e mês
- **Dashboard 2:** Temperatura e umidade médias por dia e estado
- **Dashboard 2b:** Eventos de chuva intensa por dia e região (alerta operacional)

---

## 10. Solução de problemas comuns

| Problema | Causa provável | Solução |
|---|---|---|
| Porta 3000/8080/5432 ocupada | Outro serviço usando a porta | Edite `METABASE_PORT`, `AIRFLOW_PORT`, `POSTGRES_PORT` no `.env` |
| Airflow não conecta no Postgres | Banco `airflow_db` não criado | Verifique se `sql/init/00_create_databases.sql` rodou; recriar volume com `docker compose down -v` |
| Falha no download do INMET | Sem internet / URL incorreta | Confirme `INMET_BASE_URL` no `.env` e conectividade |
| dbt falha no `dbt run` | Postgres não tem dados | Execute `python_ingestion_raw` antes no Airflow |
| Metabase perde dashboards ao reiniciar | Banco H2 embutido | Já resolvido: usamos `metabase_db` no Postgres |

---

## 11. Evidências para entrega final

Incluir no repositório antes da entrega:

1. Capturas de tela dos dashboards em funcionamento
2. Captura do relatório de validação GE (JSON ou HTML)
3. Captura da linhagem no `dbt docs` (lineage graph)
4. Vídeo de demonstração (até 7 min)


# 12. Referencias
Dados de GeoJSON: 
https://github.com/giuliano-macedo/geodata-br-states