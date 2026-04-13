with source_data as (
    select *
    from {{ source('raw', 'inmet_weather_raw') }}
),

renamed as (
    select
        data::date as data_referencia,
        hora_referencia::time as hora_referencia,
        ltrim(meta_codigo_wmo, ';') as codigo_wmo,
        ltrim(meta_estacao, ';') as nome_estacao,
        ltrim(meta_uf, ';') as uf,
        ltrim(meta_regiao, ';') as regiao,
        nullif(replace(ltrim(meta_latitude, ';'), ',', '.'), '')::numeric(10,6) as latitude,
        nullif(replace(ltrim(meta_longitude, ';'), ',', '.'), '')::numeric(10,6) as longitude,
        nullif(replace(ltrim(meta_altitude, ';'), ',', '.'), '')::numeric(10,2) as altitude,
        nullif(replace(temperatura_do_ar_bulbo_seco_horaria, ',', '.'), '')::numeric(10,2) as temperatura_c,
        nullif(replace(umidade_relativa_do_ar_horaria, ',', '.'), '')::numeric(10,2) as umidade_pct,
        nullif(replace(precipitacao_total_horario, ',', '.'), '')::numeric(10,2) as precipitacao_mm,
        source_year,
        source_file,
        loaded_at::timestamp as loaded_at
    from source_data
)

select *
from renamed
where data_referencia is not null
