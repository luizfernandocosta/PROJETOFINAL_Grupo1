# Contribuições da Equipe - Pipeline INMET

Este documento especifica a atuação de cada integrante do grupo no projeto de data engineering da pipeline de dados meteorológicos do INMET.

---

## Membros da Equipe

### 1. **Breno Tostes de Gomes Garcia**

**Rol Principal:** Arquitetura e Estruturação Inicial

**Contribuições:**
- Estruturação inicial do projeto que serviu como base para toda a evolução
- Criação do esqueleto/scaffolding do repositório
- Definição da arquitetura geral e padrões do projeto
- Estabelecimento da base sobre a qual toda a equipe desenvolveu

**Artefatos Principais:**
- Estrutura inicial de diretórios e organização do projeto
- Configuração base de containerização e orquestração

---

### 2. **Christian Andrade Mendes**

**Rol Principal:** Testes, Debugging e Documentação da Pipeline

**Contribuições:**
- Testes de execução da pipeline completa
- Correção de bugs de execução identificados durante os testes
- Documentação técnica da pipeline
- Validação do fluxo de processamento end-to-end

**Artefatos Principais:**
- Documentação da pipeline (setup_guide.md, README.md)
- Testes de execução e cenários validados
- Correções de bugs críticos na execução

---

### 3. **Guilherme Sérgio dos Santos**

**Rol Principal:** dbt, Dashboards e Integração Metabase

**Contribuições:**
- Implementação e solução completa do dbt
- Integração com Metabase
- Criação dos dashboards analíticos
- Documentação dos modelos de dados e dashboards
- Design do modelo estrela (star schema)

**Artefatos Principais:**
- `dbt/inmet_analytics/` — modelos staging (stg_*) e gold (dim_*, fact_*)
- `dbt/inmet_analytics/macros/` — macros customizadas para transformações
- `dbt/inmet_analytics/models/schema.yml` — documentação e testes dos modelos
- `dashboards/dashboard_queries.sql` — queries dos dashboards
- Configuração Metabase e visualizações

---

### 4. **Isabella Abreu Comelli**

**Rol Principal:** Integração de Dashboards, Testes, Documentação e Apresentações

**Contribuições:**
- Construção da integração com serviço de dashboards
- Testes de execução do sistema integrado
- Documentação técnica e de usuário
- Correção de bugs encontrados durante testes
- Preparação e entrega de apresentações

**Artefatos Principais:**
- Documentação técnica (`docs/`)
- Testes de integração
- Apresentações e demos do projeto
- Documentação de ambiente e setup

---

### 5. **Luiz Fernando Leal Costa**

**Rol Principal:** Ingestão de Dados, Conexões de Banco e Evoluções Arquiteturais

**Contribuições:**
- Implementação da ingestão de dados da fonte INMET
- Conexão e integração com PostgreSQL
- Evolução do sistema com Airbyte
- Construção do fluxo completo da pipeline
- Garantia da integridade do pipeline de dados

**Artefatos Principais:**
- `ingestion/ingest_inmet.py` — script de ingestão de dados do INMET
- `ingestion/Dockerfile` — containerização da ingestão
- Configuração de conexões PostgreSQL (`sql/init/`)
- Integração com Airbyte
- `airflow/dags/inmet_weather_pipeline.py` — orquestração via Airflow

---

## Resumo de Responsabilidades

| Membro | Foco Principal | Componentes-Chave |
|--------|--------------------------|-------------------|
| **Breno** | Arquitetura & Base | Estrutura do projeto, scaffolding |
| **Christian** | QA & Testes & Docs | Pipeline execution, debugging |
| **Guilherme** | dbt & Analytics | Transformações, dashboards, Metabase |
| **Isabella** | Integração & Apresentação | Dashboard integration, docs, demos |
| **Luiz** | Data Ingestion & Fluxo | Ingestão INMET, PostgreSQL, Airflow |

---

## Stack Técnico Implementado

- **Orquestração:** Apache Airflow
- **Ingestão:** Python + Airbyte
- **Data Warehouse:** PostgreSQL (Arquitetura Medalhão)
- **Transformações:** dbt
- **Qualidade de Dados:** Great Expectations
- **Visualização:** Metabase
- **Containerização:** Docker & Docker Compose
