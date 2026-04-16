import io
import os
import re
import sys
import unicodedata
import zipfile
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd
import requests
from sqlalchemy import create_engine, text


def normalize_col(name: str) -> str:
    value = unicodedata.normalize("NFKD", str(name)).encode("ascii", "ignore").decode("ascii")
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "_", value)
    value = re.sub(r"_+", "_", value)
    return value.strip("_")


def parse_years(raw_years: str) -> list[int]:
    out = []
    for token in raw_years.split(","):
        token = token.strip()
        if not token:
            continue
        out.append(int(token))
    if not out:
        raise ValueError("INMET_YEARS vazio. Exemplo esperado: 2024,2025")
    return out


def build_pg_engine() -> tuple:
    host = os.getenv("POSTGRES_HOST", "localhost")
    port = int(os.getenv("POSTGRES_PORT", "5432"))
    db   = os.getenv("POSTGRES_DB", "inmet_db")
    user = os.getenv("POSTGRES_USER", "inmet_user")
    pwd  = os.getenv("POSTGRES_PASSWORD", "inmet_pass")
    uri  = f"postgresql+psycopg2://{user}:{pwd}@{host}:{port}/{db}"
    return create_engine(uri), uri


def download_zip(base_url: str, year: int, workdir: Path) -> Path:
    workdir.mkdir(parents=True, exist_ok=True)
    url = f"{base_url.rstrip('/')}/{year}.zip"
    local_file = workdir / f"{year}.zip"
    print(f"[INFO] Download {url}")
    response = requests.get(url, timeout=120)
    response.raise_for_status()
    local_file.write_bytes(response.content)
    return local_file


def split_metadata_and_data(raw_text: str) -> tuple[dict, str]:
    lines = raw_text.splitlines()
    metadata = {}
    header_idx = None

    for idx, line in enumerate(lines[:40]):
        if ";" in line:
            parts = [normalize_col(p) for p in line.split(";")]
            first = parts[0] if parts else ""
            second = parts[1] if len(parts) > 1 else ""
            if first.startswith("data") and "hora" in second:
                header_idx = idx
                break
        if ":" in line:
            key, value = line.split(":", 1)
            metadata[normalize_col(key)] = value.strip()

    if header_idx is None:
        for idx, line in enumerate(lines):
            if ";" not in line:
                continue
            parts = [normalize_col(p) for p in line.split(";")]
            first = parts[0] if parts else ""
            second = parts[1] if len(parts) > 1 else ""
            if first.startswith("data") and "hora" in second:
                header_idx = idx
                break

    if header_idx is None:
        for idx, line in enumerate(lines):
            if line.count(";") >= 10:
                header_idx = idx
                break

    if header_idx is None:
        raise ValueError("Cabeçalho tabular não encontrado no arquivo INMET.")

    tabular_text = "\n".join(lines[header_idx:])
    return metadata, tabular_text


def ensure_raw_table_columns(engine, schema: str, table: str, columns: list[str]) -> None:
    with engine.begin() as conn:
        conn.execute(
            text(
                f"""
                CREATE TABLE IF NOT EXISTS {schema}.{table} (
                  load_row_id BIGSERIAL PRIMARY KEY
                )
                """
            )
        )
        existing_rows = conn.execute(
            text(
                """
                SELECT column_name
                FROM information_schema.columns
                WHERE table_schema = :schema AND table_name = :table
                """
            ),
            {"schema": schema, "table": table},
        ).fetchall()
        existing = {r[0] for r in existing_rows}
        for col in columns:
            if col in existing:
                continue
            conn.execute(text(f'ALTER TABLE {schema}.{table} ADD COLUMN "{col}" TEXT'))


def parse_hour(raw_value: str) -> str:
    value = (raw_value or "").upper().replace("UTC", "").strip()
    digits = re.sub(r"[^0-9]", "", value)
    if not digits:
        return None
    digits = digits.zfill(4)
    return f"{digits[:2]}:{digits[2:4]}:00"


def parse_single_csv(file_bytes: bytes, source_file: str, source_year: int) -> pd.DataFrame:
    decoded = file_bytes.decode("latin-1", errors="ignore")
    metadata, table_text = split_metadata_and_data(decoded)

    df = pd.read_csv(
        io.StringIO(table_text),
        sep=";",
        dtype=str,
        encoding="latin-1",
        engine="python",
    )

    df.columns = [normalize_col(c) for c in df.columns]
    df = df.loc[:, [c for c in df.columns if c and not c.startswith("unnamed")]]

    canonical_prefixes = {
        "data": "data",
        "hora_utc": "hora_utc",
        "hora": "hora",
        "temperatura_do_ar_bulbo_seco_horaria": "temperatura_do_ar_bulbo_seco_horaria",
        "umidade_relativa_do_ar_horaria": "umidade_relativa_do_ar_horaria",
        "precipitacao_total_horario": "precipitacao_total_horario",
    }
    rename_map = {}
    for canonical, prefix in canonical_prefixes.items():
        if canonical in df.columns:
            continue
        match = next((c for c in df.columns if c.startswith(prefix)), None)
        if match:
            rename_map[match] = canonical
    if rename_map:
        df = df.rename(columns=rename_map)

    if "data" in df.columns:
        df["data"] = pd.to_datetime(df["data"], errors="coerce").dt.date.astype("string")

    hour_col = "hora_utc" if "hora_utc" in df.columns else ("hora" if "hora" in df.columns else None)
    if hour_col:
        df["hora_referencia"] = df[hour_col].map(parse_hour)
    else:
        df["hora_referencia"] = None

    for meta_key, meta_value in metadata.items():
        df[f"meta_{meta_key}"] = meta_value

    df["source_file"] = source_file
    df["source_year"] = source_year
    df["loaded_at"] = datetime.now(timezone.utc).isoformat()
    df = df.astype("string")

    return df


def ingest_year(year: int, base_url: str, engine, load_mode: str, workdir: Path) -> int:
    zip_path = download_zip(base_url, year, workdir)
    loaded_rows = 0
    already_loaded_files = set()

    if load_mode == "incremental":
        with engine.begin() as conn:
            existing = conn.execute(
                text(
                    """
                    SELECT source_file
                    FROM raw.ingestion_log
                    WHERE source_year = :source_year
                      AND status = 'success'
                    """
                ),
                {"source_year": year},
            ).fetchall()
        already_loaded_files = {row[0] for row in existing}

    with zipfile.ZipFile(zip_path, "r") as zf:
        csv_files = [n for n in zf.namelist() if n.lower().endswith(".csv")]
        for csv_name in csv_files:
            if load_mode == "incremental" and csv_name in already_loaded_files:
                continue
            with zf.open(csv_name) as f:
                df = parse_single_csv(f.read(), source_file=csv_name, source_year=year)
                if df.empty:
                    continue
                ensure_raw_table_columns(engine, "raw", "inmet_weather_raw", list(df.columns))
                df.to_sql(
                    name="inmet_weather_raw",
                    schema="raw",
                    con=engine,
                    if_exists="append",
                    index=False,
                    method="multi",
                    chunksize=5000,
                )
                loaded_rows += len(df)
                with engine.begin() as conn:
                    conn.execute(
                        text(
                            """
                            INSERT INTO raw.ingestion_log(load_mode, source_year, source_file, rows_loaded, status, details)
                            VALUES(:load_mode, :source_year, :source_file, :rows_loaded, 'success', :details)
                            """
                        ),
                        {
                            "load_mode": load_mode,
                            "source_year": year,
                            "source_file": csv_name,
                            "rows_loaded": int(len(df)),
                            "details": "Arquivo processado com sucesso.",
                        },
                    )
                if load_mode == "incremental":
                    already_loaded_files.add(csv_name)

    return loaded_rows


def truncate_raw(engine):
    with engine.begin() as conn:
        conn.execute(text("TRUNCATE TABLE raw.inmet_weather_raw"))


def ensure_schemas(engine):
    ddl = """
    CREATE SCHEMA IF NOT EXISTS raw;
    CREATE SCHEMA IF NOT EXISTS silver;
    CREATE SCHEMA IF NOT EXISTS gold;

    CREATE TABLE IF NOT EXISTS raw.ingestion_log (
      ingestion_id BIGSERIAL PRIMARY KEY,
      loaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      load_mode VARCHAR(30) NOT NULL,
      source_year INTEGER NOT NULL,
      source_file TEXT NOT NULL,
      rows_loaded INTEGER NOT NULL,
      status VARCHAR(30) NOT NULL,
      details TEXT
    );
    """
    with engine.begin() as conn:
        conn.execute(text(ddl))


def main() -> int:
    years    = parse_years(os.getenv("INMET_YEARS", "2024,2025"))
    load_mode = os.getenv("LOAD_MODE", "full_refresh").strip().lower()
    base_url  = os.getenv("INMET_BASE_URL", "https://portal.inmet.gov.br/uploads/dadoshistoricos")
    workdir   = Path(os.getenv("WORKDIR", "/tmp/inmet"))

    engine, uri = build_pg_engine()
    print(f"[INFO] Conectando em: {uri}")
    ensure_schemas(engine)

    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
    except Exception as exc:
        print(f"[ERRO] Falha ao conectar no PostgreSQL: {exc}")
        return 1

    if load_mode == "full_refresh":
        try:
            truncate_raw(engine)
            print("[INFO] Tabela raw.inmet_weather_raw truncada (full_refresh).")
        except Exception:
            print("[INFO] Tabela raw.inmet_weather_raw ainda não existe. Continuando.")

    total_rows = 0
    for year in years:
        try:
            total_rows += ingest_year(year, base_url, engine, load_mode, workdir)
            print(f"[INFO] Ano {year} processado.")
        except Exception as exc:
            with engine.begin() as conn:
                conn.execute(
                    text(
                        """
                        INSERT INTO raw.ingestion_log(load_mode, source_year, source_file, rows_loaded, status, details)
                        VALUES(:load_mode, :source_year, :source_file, 0, 'error', :details)
                        """
                    ),
                    {
                        "load_mode": load_mode,
                        "source_year": year,
                        "source_file": f"{year}.zip",
                        "details": str(exc)[:5000],
                    },
                )
            print(f"[ERRO] Falha ao processar {year}: {exc}")
            return 1

    print(f"[OK] Total de linhas carregadas: {total_rows}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
