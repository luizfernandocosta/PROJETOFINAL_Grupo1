from __future__ import annotations
import os
import subprocess
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator

GE_PROVIDER_AVAILABLE = True
try:
    from airflow.providers.great_expectations.operators.great_expectations import GreatExpectationsOperator
except Exception:
    GE_PROVIDER_AVAILABLE = False

    class GreatExpectationsOperator(BashOperator):
        """Fallback: executa run_checkpoint.py via bash quando o provider não está instalado."""

        def __init__(self, *args, **kwargs):
            kwargs.pop("data_context_root_dir", None)
            kwargs.pop("checkpoint_name", None)
            super().__init__(*args, **kwargs)


def run_ingestion_script():
    env = os.environ.copy()
    command = ["python", "/opt/project/ingestion/ingest_inmet.py"]
    subprocess.run(command, env=env, check=True)


default_args = {
    "owner": "data_eng_group",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="inmet_weather_pipeline",
    default_args=default_args,
    description="Pipeline ELT INMET: ingestao -> GE -> dbt run -> dbt test -> dbt docs",
    schedule="0 6 * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["inmet", "weather", "edp"],
) as dag:

    ingest_raw = PythonOperator(
        task_id="python_ingestion_raw",
        python_callable=run_ingestion_script,
    )

    # Placeholder de dependência, em uma evolução futura pode ser substituído pelo operador do Airbyte
    airbyte_sensor = EmptyOperator(task_id="airbyte_sensor")

    if GE_PROVIDER_AVAILABLE:
        ge_validation = GreatExpectationsOperator(
            task_id="great_expectations_validation",
            data_context_root_dir="/opt/project/great_expectations",
            checkpoint_name="raw_inmet_weather_checkpoint",
            fail_task_on_validation_failure=True,
        )
    else:
        ge_validation = GreatExpectationsOperator(
            task_id="great_expectations_validation",
            bash_command="python /opt/project/great_expectations/run_checkpoint.py",
        )

    dbt_deps = BashOperator(
        task_id="dbt_deps",
        bash_command="cd /opt/project/dbt/inmet_analytics && dbt deps --profiles-dir /opt/project/dbt",
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command="cd /opt/project/dbt/inmet_analytics && dbt run --profiles-dir /opt/project/dbt",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command="cd /opt/project/dbt/inmet_analytics && dbt test --profiles-dir /opt/project/dbt",
    )

    dbt_docs = BashOperator(
        task_id="dbt_docs_generate",
        bash_command="cd /opt/project/dbt/inmet_analytics && dbt docs generate --profiles-dir /opt/project/dbt",
    )

    ingest_raw >> airbyte_sensor >> ge_validation >> dbt_deps >> dbt_run >> dbt_test >> dbt_docs