# Projeto Final - Fundamentos de Engenharia de Dados

Pipeline ELT completo com dados meteorologicos historicos do INMET, aplicado ao contexto agricola.

---

## Sumario

1. [Contexto e Storytelling](#1-contexto-e-storytelling)
2. [Dataset](#2-dataset)
3. [Arquitetura](#3-arquitetura)
4. [Tecnologias utilizadas](#4-tecnologias-utilizadas)
5. [Estrutura do repositorio](#5-estrutura-do-repositorio)
6. [Pre-requisitos](#6-pre-requisitos)
7. [Passo a passo para executar](#7-passo-a-passo-para-executar)
8. [Modelagem dbt](#8-modelagem-dbt)
9. [Validacao com Great Expectations](#9-validacao-com-great-expectations)
10. [Dashboards no Metabase](#10-dashboards-no-metabase)
11. [Solucao de problemas comuns](#11-solucao-de-problemas-comuns)
12. [Referencias](#12-referencias)

---

## 1. Contexto e Storytelling

**Dominio:** Clima com aplicacao agricola

Uma cooperativa agricola que atua em diferentes regioes do Brasil precisa tomar decisoes operacionais diarias com base em dados climaticos confiaveis. A equipe de agronomia e operacoes depende de um painel atualizado para responder perguntas como:

- Quais regioes e estacoes registraram maior volume de chuva em determinado periodo?
- Como temperatura e umidade evoluiram ao longo do tempo por estado?
- Quais localidades registraram eventos de chuva intensa ou rajadas de vento que afetam operacoes de campo, como pulverizacao, colheita ou plantio?

O pipeline consome dados das estacoes meteorologicas automaticas do INMET (Instituto Nacional de Meteorologia) e os transforma em um modelo analitico pronto para consulta, com validacao de qualidade em todas as camadas.

---

## 2. Dataset

- **Fonte oficial:** https://portal.inmet.gov.br/dadoshistoricos
- **Formato:** arquivos ZIP anuais contendo CSVs por estacao meteorologica
- **URL de download usada pelo pipeline:** `https://portal.inmet.gov.br/uploads/dadoshistoricos/{ano}.zip`
- **Cobertura:** estacoes automaticas distribuidas por todos os estados do Brasil
- **Granularidade:** leituras horarias por estacao (temperatura, umidade, precipitacao, vento, pressao atmosferica)
- **Nota:** o dataset nao e versionado no repositorio por conta do volume. O script de ingestao faz o download automaticamente a partir da URL oficial.

---

## 3. Arquitetura

```
INMET (ZIP/CSV)
      |
      v
Python Ingestion Script
      |
      v
PostgreSQL - schema raw
(raw.inmet_weather_raw)
      |
      v
Great Expectations
(validacao da camada raw)
      |
      v
dbt - schema silver
(stg_inmet_weather)
      |
      v
dbt - schema gold
(modelo estrela)
  dim_station
  dim_date
  dim_time
  fact_weather_hourly
      |
      v
Metabase Dashboards

[ Airflow DAG orquestra todo o fluxo acima ]
[ Docker garante reproducibilidade do ambiente ]
```

---

## 4. Tecnologias utilizadas

| Tecnologia | Versao | Papel no pipeline |
|---|---|---|
| Python | 3.11 | Script de ingestao (download, parse e carga no PostgreSQL) |
| PostgreSQL | 16 | Banco principal com arquitetura medalhao (raw / silver / gold) |
| Great Expectations | 0.18.22 | Validacao de qualidade dos dados na camada raw |
| dbt-postgres | 1.8.2 | Transformacao raw -> silver -> gold, testes e documentacao |
| Apache Airflow | 2.9.3 | Orquestracao do pipeline com dependencias e tratamento de falhas |
| Metabase | v0.50.13 | Dashboards conectados ao schema gold |
| Docker / Docker Compose | v2 | Containerizacao e reproducibilidade do ambiente |

**Fluxo de execucao da DAG (Airflow):**

```
python_ingestion_raw
      |
      v
airbyte_sensor  (placeholder de dependencia)
      |
      v
great_expectations_validation
      |
      v
dbt_deps -> dbt_run -> dbt_test -> dbt_docs_generate
```

---

## 5. Estrutura do repositorio

```
PROJETOFINAL_Grupo1/
├── airflow/
│   ├── Dockerfile  # Imagem customizada com dbt e GE pre-instalados
│   ├── requirements-airflow.txt
│   └── dags/
│       └── inmet_weather_pipeline.py  # DAG principal do pipeline
├── dashboards/
│   └── dashboard_queries.sql  # Queries base para os dashboards no Metabase
├── dbt/
│   ├── profiles.yml  # Configuracao de conexao com o PostgreSQL
│   └── inmet_analytics/
│       ├── dbt_project.yml
│       ├── packages.yml
│       ├── macros/
│       │   ├── generate_schema_name.sql            # Controla schemas silver/gold
│       │   ├── precipitation_intensity_bucket.sql  # Classifica intensidade de chuva
│       │   ├── uf_to_timezone.sql                  # Converte UF para timezone brasileiro
│       │   └── wind_risk_level.sql                 # Classifica risco operacional de vento
│       ├── models/
│       │   ├── schema.yml
│       │   ├── staging/
│       │   │   └── stg_inmet_weather.sql  # Camada silver
│       │   └── marts/
│       │       ├── dim_date.sql
│       │       ├── dim_station.sql
│       │       ├── dim_time.sql
│       │       └── fact_weather_hourly.sql  # Fato principal
│       └── tests/
│           ├── assert_humidity_range.sql   # Teste singular: umidade fora de faixa
│           └── assert_no_future_dates.sql  # Teste singular: datas futuras
├── docs/
│   ├── checklist_requisitos.md
│   ├── setup_guide.md
│   └── screenshots/  # Capturas de tela para evidencias de entrega
├── great_expectations/
│   ├── great_expectations.yml
│   ├── run_checkpoint.py  # Script de validacao executavel via CLI ou Airflow
│   ├── checkpoints/
│   │   └── raw_inmet_weather_checkpoint.yml
│   └── expectations/
│       └── raw_inmet_weather_suite.json
├── ingestion/
│   ├── Dockerfile
│   ├── ingest_inmet.py  # Script de extracao e carga (EL)
│   └── requirements.txt
├── sql/init/
│   ├── 00_create_databases.sql  # Cria bancos e usuarios no PostgreSQL
│   └── 01_schemas.sql           # Cria schemas raw/silver/gold e permissoes
├── .env.example  # Variaveis de ambiente (copiar para .env)
├── .gitignore
├── docker-compose.yml
├── requirements.txt  # Dependencias para execucao local (sem Docker)
└── README.md
```

---

## 6. Pre-requisitos

A unica dependencia necessaria na maquina local e o Docker. Nao e preciso instalar Python, dbt, Airflow ou qualquer outra ferramenta separadamente.

### Windows

1. Instale o **Docker Desktop**: https://www.docker.com/products/docker-desktop
   - Habilite o backend WSL2 quando solicitado (recomendado)
2. Instale o **Git**: https://git-scm.com/download/win

### Linux (Ubuntu / Debian)

```bash
# Docker Engine
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Verificar instalacao
docker compose version

# Git
sudo apt-get install -y git
```

### macOS

```bash
brew install --cask docker
brew install git
```

---

## 7. Passo a passo para executar

### 7.1 Clonar o repositorio

```bash
git clone <URL_DO_REPOSITORIO>
cd PROJETOFINAL_Grupo1
```

### 7.2 Configurar variaveis de ambiente

```bash
cp .env.example .env
```

O arquivo `.env.example` ja possui valores padrao funcionais para execucao local. Edite o `.env` apenas se quiser personalizar senhas, portas ou os anos de ingestao:

| Variavel | Padrao | Descricao |
|---|---|---|
| `POSTGRES_USER` | `inmet_user` | Usuario principal do PostgreSQL |
| `POSTGRES_PASSWORD` | `inmet_pass` | Senha do usuario principal |
| `POSTGRES_DB` | `inmet_db` | Banco de dados principal |
| `ANALYTICS_USER` | `analytics_user` | Usuario usado pelo dbt e Metabase |
| `ANALYTICS_PASSWORD` | `analytics_pass` | Senha do analytics_user |
| `AIRFLOW_USER` | `admin` | Login da interface do Airflow |
| `AIRFLOW_PASSWORD` | `admin` | Senha da interface do Airflow |
| `INMET_YEARS` | `2026` | Anos a ingerir, separados por virgula (ex: `2026`) |
| `LOAD_MODE` | `full_refresh` | Modo de carga: `full_refresh` ou `incremental` |
| `AIRFLOW_PORT` | `8080` | Porta local do Airflow |
| `METABASE_PORT` | `3001` | Porta local do Metabase |
| `DBT_DOCS_PORT` | `8081` | Porta local da documentacao dbt |

> Se alguma porta ja estiver em uso na sua maquina, altere o valor correspondente no `.env` antes de subir os containers.

### 7.3 Subir o ambiente

```bash
docker compose up -d --build
```

Na primeira execucao, o Docker vai baixar as imagens base e construir a imagem customizada do Airflow. Isso pode levar de 3 a 5 minutos dependendo da conexao.

### 7.4 Verificar se todos os containers estao rodando

```bash
docker compose ps
```

O resultado esperado e:

```
inmet-postgres              running (healthy)
inmet-airflow-init          exited (0)          <- normal, executa uma vez e encerra
inmet-airflow-webserver     running (healthy)
inmet-airflow-scheduler     running
inmet-dbt-docs              running
inmet-metabase              running
```

Se o `airflow-webserver` demorar para ficar `healthy`, aguarde mais 1 ou 2 minutos e rode `docker compose ps` novamente.

### 7.5 Executar a ingestao inicial dos dados

O script de ingestao faz o download dos arquivos ZIP do INMET, extrai os CSVs e carrega os dados na tabela `raw.inmet_weather_raw`. Essa etapa pode ser executada de duas formas:

**Opcao A - via container isolado (recomendado para a primeira carga):**

```bash
docker compose --profile bootstrap up inmet-ingestion
```

Aguarde o container encerrar com sucesso antes de prosseguir. O log deve finalizar com:

```
[OK] Total de linhas carregadas: XXXXXXX
```

**Opcao B - via Airflow:** a tarefa `python_ingestion_raw` executa a ingestao automaticamente quando a DAG e disparada (passo 7.6).

### 7.6 Executar o pipeline no Airflow

1. Acesse http://localhost:8080 (ou a porta configurada em `AIRFLOW_PORT`)
2. Login: `admin` / `admin`
3. Localize a DAG `inmet_weather_pipeline`
4. Ative o toggle para habilitar a DAG
5. Clique no botao de execucao manual (Trigger DAG)

A DAG vai executar as tarefas na seguinte ordem:

```
python_ingestion_raw  ->  airbyte_sensor  ->  great_expectations_validation
      ->  dbt_deps  ->  dbt_run  ->  dbt_test  ->  dbt_docs_generate
```

Cada tarefa deve aparecer em verde ao completar. Em caso de falha, o Airflow tenta novamente automaticamente (2 retentativas com intervalo de 5 minutos).

**Captura de tela da execucao da DAG:**

![Airflow DAG Diagram](docs/airflow_dag_diagram.jpg)

![Airflow DAG](docs/airflow_dag.jpg)

### 7.7 Verificar o relatorio do Great Expectations

Apos a tarefa `great_expectations_validation` completar:

```bash
cat great_expectations/uncommitted/validation_results/raw_inmet_weather_checkpoint.json
```

O campo `"success": true` confirma que os dados passaram em todas as expectativas configuradas.

**Captura de tela do relatorio de validacao:**

<!-- placeholder imagem Great Expectations 
![Great Expectations Validation Report](docs/ge_validation_report.png)
-->

### 7.8 Verificar a documentacao e linhagem do dbt

Acesse http://localhost:8081 para visualizar o lineage graph e as descricoes de todos os modelos, testes e fontes.

**Captura de tela do lineage graph:**

![dbt Lineage Graph](docs/dbt_lineage.jpg)

### 7.9 Configurar o Metabase

1. Acesse http://localhost:3001 (ou a porta configurada em `METABASE_PORT`)
2. Siga o wizard de configuracao inicial do Metabase
3. Adicione a conexao com o banco de dados:
   - **Tipo:** PostgreSQL
   - **Host:** `postgres`
   - **Porta:** `5432`
   - **Banco de dados:** `inmet_db`
   - **Usuario:** `analytics_user`
   - **Senha:** `analytics_pass`
4. Crie os dashboards usando as queries disponveis em `dashboards/dashboard_queries.sql`

**Captura de tela dos dashboards:**

Mapa de Estações de Coleta
![Dashboard 1 - Mapa de Estações de Coleta](docs/metabase_dashboard_1.jpg)

Mapas de Umidade, Precipitação, Vento e Temperatura por Estado
![Dashboard 2 - Mapas de Umidade, Precipitação, Vento e Temperatura por Estado](docs/metabase_dashboard_2.jpg)

Dashboard - Monitoramento de Clima por Estado
![Dashboard 3 - Monitoramento de Clima por Estado](docs/metabase_dashboard_3.jpg)

### 7.10 Parar o ambiente

```bash
# Para os containers sem apagar os dados
docker compose down

# Para os containers e remove todos os volumes (apaga dados do Postgres e Metabase)
docker compose down -v
```

---

### Execucao local sem Docker (opcional, para desenvolvimento)

Se preferir rodar os componentes diretamente na sua maquina:

```bash
# Criar e ativar ambiente virtual
python -m venv .venv
source .venv/bin/activate       # Linux / macOS
.venv\Scripts\activate          # Windows

# Instalar dependencias
pip install -r requirements.txt

# Ingestao
python ingestion/ingest_inmet.py

# Validacao Great Expectations
python great_expectations/run_checkpoint.py

# dbt
cd dbt/inmet_analytics
dbt deps --profiles-dir ../
dbt run --profiles-dir ../
dbt test --profiles-dir ../
dbt docs generate --profiles-dir ../
dbt docs serve --profiles-dir ../
```

Certifique-se de que as variaveis de ambiente do `.env` estejam exportadas na sessao antes de executar os scripts.

---

## 8. Modelagem dbt

### Camada Silver - `stg_inmet_weather`

Modelo de staging que padroniza os dados brutos da camada raw:

- Normalizacao de nomes de colunas e tipos de dados
- Conversao de valores numericos com virgula decimal para ponto
- Tratamento de strings vazias e valores `NULL` textuais
- Conversao do timestamp UTC para horario local de cada estado via macro `uf_to_timezone`
- Filtragem de linhas sem data valida

### Camada Gold - modelo estrela

| Tabela | Tipo | Descricao |
|---|---|---|
| `dim_station` | Dimensao | Estacoes meteorologicas WMO com localizacao geografica (lat/lon, UF, regiao) |
| `dim_date` | Dimensao | Calendario com ano, mes, dia, nome do dia da semana e ano-mes |
| `dim_time` | Dimensao | Horario com hora inteira e classificacao de periodo do dia |
| `fact_weather_hourly` | Fato | Observacoes horarias com metricas de clima e classificacoes de risco |

Todas as chaves substitutas (surrogate keys) sao geradas com `dbt_utils.generate_surrogate_key`.

### Macros customizadas

| Macro | Descricao |
|---|---|
| `precipitation_intensity_bucket` | Classifica precipitacao em sem_dado, sem_chuva, chuva_fraca, chuva_moderada ou chuva_intensa |
| `wind_risk_level` | Classifica rajada de vento em sem_dado, vento_fraco, vento_moderado, vento_forte ou vento_tempestade |
| `uf_to_timezone` | Mapeia sigla de UF para o timezone IANA correspondente (ex: SP -> America/Sao_Paulo) |
| `generate_schema_name` | Garante que os modelos sejam criados nos schemas silver e gold sem prefixo do projeto |

### Testes

**Testes genericos** (definidos em `schema.yml`):
- `unique` e `not_null` nas surrogate keys e identificadores naturais
- `not_null` em colunas obrigatorias de data e hora
- `accepted_values` em colunas categoricas: `mes`, `hora_int`, `periodo_dia`, `intensidade_chuva` e `risco_vento`

**Testes singulares** (em `dbt/inmet_analytics/tests/`):
- `assert_no_future_dates.sql`: verifica se existem registros com data posterior a data atual na tabela fato
- `assert_humidity_range.sql`: verifica se existem registros com umidade fora da faixa fisica valida (0 a 100)

---

## 9. Validacao com Great Expectations

A suite `raw_inmet_weather_suite` e aplicada exclusivamente sobre a camada raw, antes de qualquer transformacao. Ela contem 16 expectativas organizadas em quatro grupos:

**Existencia de colunas obrigatorias (10 expectativas):**
`data`, `hora_referencia`, `meta_codigo_wmo`, `temperatura_do_ar_bulbo_seco_horaria`, `umidade_relativa_do_ar_horaria`, `precipitacao_total_horario`, `vento_velocidade_horaria`, `vento_direcao_horaria_graus`, `vento_rajada_maxima_horaria`, `pressao_atmosferica_ao_nivel_da_estacao_horaria`

**Valores nao nulos (2 expectativas):**
`data` e `meta_codigo_wmo` nao podem ter valores nulos

**Faixas de valores (3 expectativas):**
- Umidade entre 0 e 100 (com tolerancia de 2%)
- Temperatura entre -20 e 55 graus Celsius (com tolerancia de 2%)
- Precipitacao nao negativa (com tolerancia de 0.1%)

**Sanidade de volume (1 expectativa):**
- Contagem de linhas entre 1.000.000 e 10.000.000 (detecta downloads truncados ou duplicacoes massivas)

O checkpoint pode ser executado via CLI ou pela task `great_expectations_validation` da DAG:

```bash
python great_expectations/run_checkpoint.py
```

---

## 10. Dashboards no Metabase

Os dashboards respondem diretamente as perguntas de negocio do storytelling. As queries base estao em `dashboards/dashboard_queries.sql`.

**Dashboard 1 - Volume de chuva por estacao e mes**

Agrupa a precipitacao total por regiao, UF e estacao meteorologica. Permite identificar as regioes mais chuvosas e planejar janelas seguras para operacoes de campo.

**Dashboard 2 - Temperatura e umidade medias por dia**

Exibe a evolucao diaria de temperatura e umidade por estado. Util para monitorar condicoes ideais de pulverizacao e irrigacao.

**Dashboard 3 - Eventos de chuva intensa por regiao**

Conta os eventos classificados como `chuva_intensa` por dia e regiao. Funciona como alerta operacional para orientar a suspensao de atividades de campo em situacoes de risco climatico.

---

## 11. Solucao de problemas comuns

**Porta ja em uso**

```
Error: ports are not available: exposing port TCP 0.0.0.0:8080
```

Edite as variaveis de porta no `.env` e suba novamente:

```bash
# exemplo: trocar porta do Airflow
AIRFLOW_PORT=8082
```

```bash
docker compose up -d
```

**Airflow nao conecta no PostgreSQL**

Verifique se o container `airflow-init` encerrou com codigo 0:

```bash
docker compose logs airflow-init
```

Se houver erro de banco nao encontrado, recrie os volumes:

```bash
docker compose down -v
docker compose up -d --build
```

**Falha no download dos dados do INMET**

Verifique a conectividade com o portal:

```bash
curl -I https://portal.inmet.gov.br/uploads/dadoshistoricos/2026.zip
```

Se a URL mudou, atualize `INMET_BASE_URL` no `.env`.

**dbt falha com `relation "raw.inmet_weather_raw" does not exist`**

A ingestao precisa ter rodado antes do dbt. Certifique-se de que a tarefa `python_ingestion_raw` foi executada com sucesso no Airflow antes de `dbt_run`, ou rode a ingestao manualmente pelo passo 7.5.

**Metabase perde dashboards apos reiniciar**

Isso nao deve acontecer nessa configuracao. O banco de metadados do Metabase esta armazenado no PostgreSQL (`metabase_db`), que persiste no volume `postgres-data/`. Evite usar `docker compose down -v` em ambiente de desenvolvimento continuo.

**dbt docs nao carrega logo apos subir o ambiente**

O container `dbt-docs` executa `dbt docs generate` toda vez que inicializa. Aguarde cerca de 1 minuto apos o container subir antes de acessar http://localhost:8081.

---

## 12. Referencias

- Dataset INMET: https://portal.inmet.gov.br/dadoshistoricos
- GeoJSON dos estados brasileiros: https://github.com/giuliano-macedo/geodata-br-states

│       ├── ge_validation_report.png  # [adicionar apos execucao]