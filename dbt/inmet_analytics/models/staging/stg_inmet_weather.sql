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
        nullif(nullif(replace(ltrim(meta_latitude, ';'), ',', '.'), ''), 'NULL')::numeric(10,6) as latitude,
        nullif(nullif(replace(ltrim(meta_longitude, ';'), ',', '.'), ''), 'NULL')::numeric(10,6) as longitude,
        nullif(nullif(replace(ltrim(meta_altitude, ';'), ',', '.'), ''), 'NULL')::numeric(10,2) as altitude,
        nullif(nullif(replace(temperatura_do_ar_bulbo_seco_horaria, ',', '.'), ''), 'NULL')::numeric(10,2) as temperatura_c,
        nullif(nullif(replace(umidade_relativa_do_ar_horaria, ',', '.'), ''), 'NULL')::numeric(10,2) as umidade_pct,
        nullif(nullif(replace(precipitacao_total_horario, ',', '.'), ''), 'NULL')::numeric(10,2) as precipitacao_mm,
        nullif(nullif(replace(radiacao_global_kj_m2, ',', '.'), ''), 'NULL')::numeric(12,2) as radiacao_global_kj_m2,
        nullif(nullif(replace(vento_direcao_horaria_gr_gr, ',', '.'), ''), 'NULL')::numeric(10,2) as vento_direcao_gr,
        nullif(nullif(replace(vento_rajada_maxima_m_s, ',', '.'), ''), 'NULL')::numeric(10,2) as vento_rajada_max_m_s,
        nullif(nullif(replace(vento_velocidade_horaria_m_s, ',', '.'), ''), 'NULL')::numeric(10,2) as vento_velocidade_m_s,
        source_year,
        source_file,
        loaded_at::timestamp as loaded_at
    from source_data
)

select *
from renamed
where data_referencia is not null
