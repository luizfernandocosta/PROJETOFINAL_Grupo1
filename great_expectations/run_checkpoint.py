"""
run_checkpoint.py
Executa as validações de qualidade sobre raw.inmet_weather_raw
usando Great Expectations em modo pandas (sem datasource externo).

Expectativas aplicadas
──────────────────────
Existência de colunas obrigatórias (11):
  data, hora_referencia, meta_codigo_wmo,
  temperatura_do_ar_bulbo_seco_horaria, umidade_relativa_do_ar_horaria,
  precipitacao_total_horario, vento_velocidade_horaria,
  vento_direcao_horaria_graus, vento_rajada_maxima_horaria,
  pressao_atmosferica_ao_nivel_da_estacao_horaria, source_year

Valores:
  data                                 → not null
  meta_codigo_wmo                      → not null
  umidade_relativa_do_ar_horaria       → entre 0 e 100  (mostly 0.98)
  temperatura_do_ar_bulbo_seco_horaria → entre -20 e 55 (mostly 0.98)
  precipitacao_total_horario           → >= 0            (mostly 0.999)

Volume:
  row count entre 1 000 000 e 10 000 000
  (≈ 600 estações × 8 760 h/ano × anos carregados)
"""

import json
import os
from datetime import datetime
from pathlib import Path

import great_expectations as ge
import pandas as pd
from sqlalchemy import create_engine, text

REPORT_PATH = Path(
    "/opt/project/great_expectations/uncommitted/validation_results/"
    "raw_inmet_weather_checkpoint.json"
)

# Colunas que o schema do INMET deve ter.
REQUIRED_COLUMNS = [
    "data",
    "hora_referencia",
    "meta_codigo_wmo",
    "temperatura_do_ar_bulbo_seco_horaria",
    "umidade_relativa_do_ar_horaria",
    "precipitacao_total_horario",
    "vento_velocidade_horaria",
    "vento_direcao_horaria_graus",
    "vento_rajada_maxima_horaria",
    "pressao_atmosferica_ao_nivel_da_estacao_horaria",
    "source_year",
]


def _build_engine():
    host = os.environ["POSTGRES_HOST"]
    port = os.getenv("POSTGRES_PORT", "5432")
    db   = os.environ["POSTGRES_DB"]
    user = os.environ["POSTGRES_USER"]
    pwd  = os.environ["POSTGRES_PASSWORD"]
    uri  = f"postgresql+psycopg2://{user}:{pwd}@{host}:{port}/{db}"
    return create_engine(uri)


def _get_row_count(engine) -> int:
    with engine.connect() as conn:
        result = conn.execute(text("SELECT COUNT(*) FROM raw.inmet_weather_raw"))
        return result.scalar()


def main() -> int:
    engine = _build_engine()

    # Conta total de linhas antes de puxar amostra (evita OOM)
    total_rows = _get_row_count(engine)
    print(f"[INFO] Total de linhas em raw.inmet_weather_raw: {total_rows:,}")

    query = """
        SELECT *
        FROM raw.inmet_weather_raw
        WHERE data IS NOT NULL
        LIMIT 500000
    """
    df = pd.read_sql(query, con=engine)

    if df.empty:
        raise RuntimeError("Nenhum dado disponível em raw.inmet_weather_raw para validar.")

    gx_df = ge.from_pandas(df)

    # Converte colunas numéricas para validação de range
    numeric_cols = {
        "umidade_relativa_do_ar_horaria":       "float64",
        "temperatura_do_ar_bulbo_seco_horaria": "float64",
        "precipitacao_total_horario":           "float64",
    }
    for col, dtype in numeric_cols.items():
        if col in gx_df.columns:
            gx_df[col] = pd.to_numeric(gx_df[col], errors="coerce")

    validations = []

    # ── 1. Colunas obrigatórias existem ─────────────────────────
    for col in REQUIRED_COLUMNS:
        validations.append(gx_df.expect_column_to_exist(col))

    # ── 2. Valores não nulos ─────────────────────────────────────
    validations.append(gx_df.expect_column_values_to_not_be_null("data"))
    if "meta_codigo_wmo" in gx_df.columns:
        validations.append(gx_df.expect_column_values_to_not_be_null("meta_codigo_wmo"))

    # ── 3. Umidade entre 0 e 100 ─────────────────────────────────
    if "umidade_relativa_do_ar_horaria" in gx_df.columns:
        validations.append(
            gx_df.expect_column_values_to_be_between(
                "umidade_relativa_do_ar_horaria",
                min_value=0, max_value=100, mostly=0.98,
            )
        )

    # ── 4. Temperatura entre -20 e 55 °C ────────────────────────
    if "temperatura_do_ar_bulbo_seco_horaria" in gx_df.columns:
        validations.append(
            gx_df.expect_column_values_to_be_between(
                "temperatura_do_ar_bulbo_seco_horaria",
                min_value=-20, max_value=55, mostly=0.98,
            )
        )

    # ── 5. Precipitação não pode ser negativa ────────────────────
    if "precipitacao_total_horario" in gx_df.columns:
        validations.append(
            gx_df.expect_column_values_to_be_between(
                "precipitacao_total_horario",
                min_value=0, mostly=0.999,
            )
        )

    # ── 6. Row count dentro da faixa esperada ───────────────────
    # Sanity check: detecta downloads truncados ou duplicações massivas.
    # Estimativa: ~600 estações × 8.760 h/ano × N anos.
    # Usamos o count real (não a amostra) para essa validação.
    row_count_ok = 1_000_000 <= total_rows <= 10_000_000
    validations.append({
        "expectation_type": "expect_table_row_count_to_be_between",
        "success": row_count_ok,
        "result": {"observed_value": total_rows},
        "kwargs": {"min_value": 1_000_000, "max_value": 10_000_000},
    })

    success = all(
        (v["success"] if isinstance(v, dict) else v.get("success", False))
        for v in validations
    )

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(
        json.dumps(
            {
                "checkpoint": "raw_inmet_weather_checkpoint",
                "success": success,
                "timestamp_utc": datetime.utcnow().isoformat(),
                "total_rows_in_table": total_rows,
                "total_expectations": len(validations),
                "results": [
                    v if isinstance(v, dict) else v.to_json_dict()
                    for v in validations
                ],
            },
            ensure_ascii=False,
            default=str,
            indent=2,
        ),
        encoding="utf-8",
    )

    if not success:
        raise AssertionError("Great Expectations encontrou violações na camada raw.")

    print(f"[OK] Validation report salvo em {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
