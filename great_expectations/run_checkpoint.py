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

MIN_EXPECTED_ROWS = int(os.getenv("GE_MIN_EXPECTED_ROWS", "100000"))
MAX_EXPECTED_ROWS = int(os.getenv("GE_MAX_EXPECTED_ROWS", "10000000"))

# Colunas obrigatórias com aliases para variações comuns de cabeçalho do INMET.
REQUIRED_COLUMNS = {
    "data": ["data"]
    ,"hora_referencia": ["hora_referencia", "hora", "hora_utc"]
    ,"meta_codigo_wmo": ["meta_codigo_wmo"]
    ,"temperatura_do_ar_bulbo_seco_horaria": ["temperatura_do_ar_bulbo_seco_horaria"]
    ,"umidade_relativa_do_ar_horaria": ["umidade_relativa_do_ar_horaria"]
    ,"precipitacao_total_horario": ["precipitacao_total_horario"]
    ,"vento_velocidade_horaria": ["vento_velocidade_horaria", "vento_velocidade_horaria_m_s"]
    ,"vento_direcao_horaria_graus": ["vento_direcao_horaria_graus", "vento_direcao_horaria_gr_gr"]
    ,"vento_rajada_maxima_horaria": ["vento_rajada_maxima_horaria", "vento_rajada_maxima_m_s"]
    ,"pressao_atmosferica_ao_nivel_da_estacao_horaria": ["pressao_atmosferica_ao_nivel_da_estacao_horaria", "pressao_atmosferica_ao_nivel_da_estacao_horaria_mb"]
    ,"source_year": ["source_year"]
}


def _resolve_column(df_columns, candidates):
    for name in candidates:
        if name in df_columns:
            return name
    return None


def _build_engine():
    host = os.environ["POSTGRES_HOST"]
    port = os.getenv("POSTGRES_PORT", "5432")
    db = os.environ["POSTGRES_DB"]
    user = os.environ["POSTGRES_USER"]
    pwd = os.environ["POSTGRES_PASSWORD"]
    uri = f"postgresql+psycopg2://{user}:{pwd}@{host}:{port}/{db}"
    return create_engine(uri)


def _get_row_count(engine):
    with engine.connect() as conn:
        result = conn.execute(text("SELECT COUNT(*) FROM raw.inmet_weather_raw"))
        return result.scalar()


def main():
    engine = _build_engine()

    # Conta total de linhas antes de puxar amostra
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
    resolved = {
        key: _resolve_column(gx_df.columns, aliases)
        for key, aliases in REQUIRED_COLUMNS.items()
    }

    numeric_cols = [
        resolved["umidade_relativa_do_ar_horaria"]
        ,resolved["temperatura_do_ar_bulbo_seco_horaria"]
        ,resolved["precipitacao_total_horario"]
    ]
    for col in numeric_cols:
        if col:
            gx_df[col] = pd.to_numeric(gx_df[col], errors="coerce")

    validations = []

    # 1. Colunas obrigatórias existem
    for canonical, aliases in REQUIRED_COLUMNS.items():
        actual_col = resolved[canonical]
        validations.append(
            gx_df.expect_column_to_exist(actual_col if actual_col else aliases[0])
        )

    # 2. Valores não nulos
    if resolved["data"]:
        validations.append(gx_df.expect_column_values_to_not_be_null(resolved["data"]))
    if resolved["meta_codigo_wmo"]:
        validations.append(gx_df.expect_column_values_to_not_be_null(resolved["meta_codigo_wmo"]))

    # 3. Umidade entre 0 e 100
    if resolved["umidade_relativa_do_ar_horaria"]:
        validations.append(
            gx_df.expect_column_values_to_be_between(
                resolved["umidade_relativa_do_ar_horaria"],
                min_value=0, max_value=100, mostly=0.98,
            )
        )

    # 4. Temperatura entre -20 e 55 °C
    if resolved["temperatura_do_ar_bulbo_seco_horaria"]:
        validations.append(
            gx_df.expect_column_values_to_be_between(
                resolved["temperatura_do_ar_bulbo_seco_horaria"],
                min_value=-20, max_value=55, mostly=0.98,
            )
        )

    # 5. Precipitação não pode ser negativa
    if resolved["precipitacao_total_horario"]:
        validations.append(
            gx_df.expect_column_values_to_be_between(
                resolved["precipitacao_total_horario"],
                min_value=0, mostly=0.999,
            )
        )

    # 6. Row count dentro da faixa esperada (Detecta downloads truncados ou duplicações massivas)
    row_count_ok = MIN_EXPECTED_ROWS <= total_rows <= MAX_EXPECTED_ROWS
    validations.append({
        "expectation_type": "expect_table_row_count_to_be_between"
        ,"success": row_count_ok
        ,"result": {"observed_value": total_rows}
        ,"kwargs": {"min_value": MIN_EXPECTED_ROWS, "max_value": MAX_EXPECTED_ROWS}
    })

    success = all(
        (v["success"] if isinstance(v, dict) else v.get("success", False))
        for v in validations
    )

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(
        json.dumps(
            {
                "checkpoint": "raw_inmet_weather_checkpoint"
                ,"success": success
                ,"timestamp_utc": datetime.utcnow().isoformat()
                ,"total_rows_in_table": total_rows
                ,"total_expectations": len(validations)
                ,"results": [
                    v if isinstance(v, dict) else v.to_json_dict()
                    for v in validations
                ]
            }
            ,ensure_ascii=False
            ,default=str
            ,indent=2
        ),
        encoding="utf-8"
    )

    if not success:
        raise AssertionError("Great Expectations encontrou violações na camada raw.")

    print(f"[OK] Validation report salvo em {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())