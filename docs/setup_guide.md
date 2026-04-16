# Guia de Configuração do Ambiente

Este documento descreve o passo a passo completo para instalar, configurar e executar o pipeline do zero em uma máquina com apenas SO e softwares básicos.

---

## Pré-requisitos

### Windows

1. Instale o **Docker Desktop**: https://www.docker.com/products/docker-desktop
   - Habilite WSL2 quando solicitado (recomendado)
2. Instale o **Git**: https://git-scm.com/download/win

### Linux (Ubuntu/Debian)

```bash
# Docker Engine
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Docker Compose v2 (já incluso no Docker Engine recente)
docker compose version

# Git
sudo apt-get install -y git
```

### macOS

```bash
# Instale Docker Desktop via site oficial ou Homebrew:
brew install --cask docker
brew install git
```

---

## Passo 1 — Clonar o repositório

```bash
git clone <URL_DO_REPOSITORIO>
cd PROJETOFINAL_Grupo1
```

---

## Passo 2 — Configurar variáveis de ambiente

```bash
cp .env.example .env
```

O arquivo `.env.example` contém todas as variáveis com valores padrão funcionais. Edite apenas se quiser customizar:

| Variável | Padrão | Descrição |
|---|---|---|
| `POSTGRES_USER` | `inmet_user` | Usuário principal do PostgreSQL |
| `POSTGRES_PASSWORD` | `inmet_pass` | Senha do usuário principal |
| `POSTGRES_DB` | `inmet_db` | Banco de dados principal |
| `ANALYTICS_USER` | `analytics_user` | Usuário do dbt e Metabase |
| `ANALYTICS_PASSWORD` | `analytics_pass` | Senha do analytics_user |
| `AIRFLOW_USER` | `admin` | Login da UI do Airflow |
| `AIRFLOW_PASSWORD` | `admin` | Senha da UI do Airflow |
| `INMET_YEARS` | `2024,2025` | Anos a ingerir (separados por vírgula) |
| `LOAD_MODE` | `full_refresh` | Modo de carga: `full_refresh` ou `incremental` |
| `AIRFLOW_PORT` | `8080` | Porta local do Airflow |
| `METABASE_PORT` | `3000` | Porta local do Metabase |
| `DBT_DOCS_PORT` | `8081` | Porta local da documentação dbt |

> **Porta ocupada?** Altere `AIRFLOW_PORT`, `METABASE_PORT` ou `DBT_DOCS_PORT` no `.env` antes de subir.

---

## Passo 3 — Subir o ambiente

```bash
docker compose up -d --build
```

Na primeira execução o Docker irá:
1. Baixar as imagens base (~2–3 min dependendo da internet)
2. Construir a imagem customizada do Airflow com dbt + Great Expectations pré-instalados
3. Inicializar o PostgreSQL com os bancos e schemas necessários
4. Inicializar o Airflow (criar banco de metadados + usuário admin)

---

## Passo 4 — Verificar containers

```bash
docker compose ps
```

Todos os serviços devem aparecer como `running` ou `healthy`:

```
inmet-postgres              running (healthy)
inmet-airflow-init          exited (0)         ← normal, roda uma vez e sai
inmet-airflow-webserver     running (healthy)
inmet-airflow-scheduler     running
inmet-dbt-docs              running
inmet-metabase              running
```

---

## Passo 5 — Executar o pipeline no Airflow

1. Acesse http://localhost:8080 (ou a porta configurada em `AIRFLOW_PORT`)
2. Login: `admin` / `admin`
3. Localize a DAG `inmet_weather_pipeline`
4. Ative o toggle (Enable) e clique no botão ▶ (Trigger DAG)

A DAG executará as seguintes tasks em ordem:

```
python_ingestion_raw
      ↓
airbyte_sensor  (placeholder de dependência)
      ↓
great_expectations_validation
      ↓
dbt_deps → dbt_run → dbt_test → dbt_docs_generate
```

---

## Passo 6 — Verificar a validação do Great Expectations

Após a task `great_expectations_validation` completar:

```bash
cat great_expectations/uncommitted/validation_results/raw_inmet_weather_checkpoint.json
```

O campo `"success": true` confirma que os dados passaram em todas as 16 expectativas.

---

## Passo 7 — Verificar a documentação do dbt

Acesse http://localhost:8081 para ver o lineage graph e as descrições de todos os modelos.

---

## Passo 8 — Configurar o Metabase

1. Acesse http://localhost:3000 (ou a porta configurada em `METABASE_PORT`)
2. Siga o wizard de configuração inicial
3. Adicione uma conexão de banco de dados:
   - **Tipo:** PostgreSQL
   - **Host:** `postgres` (dentro do Docker) ou `localhost` (fora)
   - **Porta:** `5432`
   - **Banco:** `inmet_db`
   - **Usuário:** `analytics_user`
   - **Senha:** `analytics_pass`
4. Crie os dashboards usando as queries em `dashboards/dashboard_queries.sql`

---

## Passo 9 — Parar o ambiente

```bash
# Para os containers sem apagar dados
docker compose down

# Para os containers E apaga todos os volumes (dados do Postgres, Metabase)
docker compose down -v
```

---

## Solução de problemas

### Porta já em uso

```
Error: ports are not available: exposing port TCP 0.0.0.0:3000
```

Edite o `.env` e altere a porta antes de subir novamente:

```bash
# .env
METABASE_PORT=3001
```

```bash
docker compose up -d
```

### Airflow não conecta no Postgres

Verifique se o `airflow-init` completou com sucesso:

```bash
docker compose logs airflow-init
```

Se houver erro de banco não encontrado, recrie os volumes e suba novamente:

```bash
docker compose down -v
docker compose up -d --build
```

### Falha no download dos dados do INMET

Verifique conectividade com o portal:

```bash
curl -I https://portal.inmet.gov.br/uploads/dadoshistoricos/2024.zip
```

Se a URL mudou, atualize `INMET_BASE_URL` no `.env`.

### dbt falha com "relation does not exist"

A ingestão precisa ter rodado antes do dbt. Execute a task `python_ingestion_raw` no Airflow antes de `dbt_run`.

### Metabase perde dashboards após restart

Não ocorre mais — o banco de metadados do Metabase está armazenado no PostgreSQL (`metabase_db`), que persiste no volume `postgres-data/`.
