import json
import os
from datetime import datetime
from pathlib import Path

import great_expectations as ge
import pandas as pd
from sqlalchemy import create_engine


REPORT_PATH = Path("/opt/project/great_expectations/uncommitted/validation_results/raw_inmet_weather_checkpoint.json")


def main() -> int:
    host = os.getenv("POSTGRES_HOST", "postgres")
    port = os.getenv("POSTGRES_PORT", "5432")
    db = os.getenv("POSTGRES_DB", "inmet_db")
    user = os.getenv("POSTGRES_USER", "inmet_user")
    pwd = os.getenv("POSTGRES_PASSWORD", "inmet_password")

    uri = f"postgresql+psycopg2://{user}:{pwd}@{host}:{port}/{db}"
    engine = create_engine(uri)

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

    # Convert numeric columns for validation
    numeric_columns = {
        "umidade_relativa_do_ar_horaria": "float64",
        "temperatura_do_ar_bulbo_seco_horaria": "float64",
    }
    
    for col, dtype in numeric_columns.items():
        if col in gx_df.columns:
            gx_df[col] = pd.to_numeric(gx_df[col], errors='coerce')

    validations = []
    validations.append(gx_df.expect_column_values_to_not_be_null("data"))

    humidity_col = "umidade_relativa_do_ar_horaria"
    if humidity_col in gx_df.columns:
        validations.append(
            gx_df.expect_column_values_to_be_between(
                humidity_col,
                min_value=0,
                max_value=100,
                mostly=0.98,
            )
        )

    temp_col = "temperatura_do_ar_bulbo_seco_horaria"
    if temp_col in gx_df.columns:
        validations.append(
            gx_df.expect_column_values_to_be_between(
                temp_col,
                min_value=-20,
                max_value=55,
                mostly=0.98,
            )
        )

    station_col = "meta_codigo_wmo"
    if station_col in gx_df.columns:
        validations.append(gx_df.expect_column_values_to_not_be_null(station_col))

    success = all(v["success"] for v in validations)

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(
        json.dumps(
            {
                "checkpoint": "raw_inmet_weather_checkpoint",
                "success": success,
                "timestamp_utc": datetime.utcnow().isoformat(),
                "total_expectations": len(validations),
                "results": validations,
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
