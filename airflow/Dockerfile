# =============================================================
# airflow/Dockerfile
# Imagem customizada do Airflow com dbt e Great Expectations
# pré-instalados para evitar o pip install lento a cada start.
# =============================================================
FROM apache/airflow:2.9.3

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER airflow

# Instala dependências do projeto uma única vez no build da imagem
COPY requirements-airflow.txt /tmp/requirements-airflow.txt
RUN pip install --no-cache-dir -r /tmp/requirements-airflow.txt
