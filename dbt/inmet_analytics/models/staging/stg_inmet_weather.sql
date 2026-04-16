with source_data as (
    select *
    from {{ source('raw', 'inmet_weather_raw') }}
),

renamed as (
    select
        -- Chaves de identificação
        ltrim(meta_codigo_wmo, ';')  as codigo_wmo,
        ltrim(meta_estacao,    ';')  as nome_estacao,
        ltrim(meta_uf,         ';')  as uf,
        ltrim(meta_regiao,     ';')  as regiao,

        -- Localização geográfica
        nullif(nullif(replace(ltrim(meta_latitude,  ';'), ',', '.'), ''), 'NULL')::numeric(10,6) as latitude,
        nullif(nullif(replace(ltrim(meta_longitude, ';'), ',', '.'), ''), 'NULL')::numeric(10,6) as longitude,
        nullif(nullif(replace(ltrim(meta_altitude,  ';'), ',', '.'), ''), 'NULL')::numeric(10,2) as altitude,

        -- Tempo em UTC
        data::date       as data_referencia,
        hora_referencia::time as hora_referencia,

        -- Tempo em horário local (por estado)
        -- Os dados do INMET são registrados em UTC.
        -- A macro uf_to_timezone mapeia cada UF para seu fuso horário brasileiro.
        (
            (data::date::text || ' ' || hora_referencia)::timestamp at time zone 'UTC'
            at time zone {{ uf_to_timezone(ltrim(meta_uf, ';')) }}
        ) as data_hora_local,

        -- Temperatura e umidade
        nullif(nullif(replace(temperatura_do_ar_bulbo_seco_horaria, ',', '.'), ''), 'NULL')::numeric(10,2) as temperatura_c,
        nullif(nullif(replace(umidade_relativa_do_ar_horaria,       ',', '.'), ''), 'NULL')::numeric(10,2) as umidade_pct,

        -- Precipitação
        nullif(nullif(replace(precipitacao_total_horario, ',', '.'), ''), 'NULL')::numeric(10,2) as precipitacao_mm,

        -- Vento
        nullif(nullif(replace(vento_velocidade_horaria,         ',', '.'), ''), 'NULL')::numeric(10,2) as vento_velocidade_ms,
        nullif(nullif(replace(vento_direcao_horaria_graus,      ',', '.'), ''), 'NULL')::numeric(6,1)  as vento_direcao_graus,
        nullif(nullif(replace(vento_rajada_maxima_horaria,      ',', '.'), ''), 'NULL')::numeric(10,2) as vento_rajada_ms,

        -- Pressão atmosférica
        nullif(nullif(replace(pressao_atmosferica_ao_nivel_da_estacao_horaria, ',', '.'), ''), 'NULL')::numeric(10,2) as pressao_atm_hpa,

        -- Metadados de carga
        source_year,
        source_file,
        loaded_at::timestamp as loaded_at

    from source_data
)

select *
from renamed
where data_referencia is not null