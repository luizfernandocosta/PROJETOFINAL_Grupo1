with
base as (select * from {{ ref('stg_inmet_weather') }}),
station as (select * from {{ ref('dim_station') }}),
calendar as (select * from {{ ref('dim_date') }}),
time_dim as (select * from {{ ref('dim_time') }})

select
    -- Surrogate key do evento
    {{ dbt_utils.generate_surrogate_key(['b.codigo_wmo', 'b.data_referencia', 'b.hora_referencia']) }}
        as weather_event_sk,

    -- Chaves estrangeiras
    s.station_sk,
    d.date_sk,
    t.time_sk,

    -- Dimensões de tempo (desnormalizadas para conveniência)
    b.data_referencia,
    b.data_hora_local,

    -- Métricas de temperatura e umidade
    b.temperatura_c,
    b.umidade_pct,

    -- Métricas de precipitação
    b.precipitacao_mm,
    {{ precipitation_intensity_bucket('b.precipitacao_mm') }} as intensidade_chuva,

    -- Métricas de vento
    b.vento_velocidade_ms,
    b.vento_direcao_graus,
    b.vento_rajada_ms,
    {{ wind_risk_level('b.vento_rajada_ms') }} as risco_vento,

    -- Pressão atmosférica
    b.pressao_atm_hpa,

    -- Metadados de carga
    b.source_year,
    b.source_file,
    b.loaded_at

from base as b
left join station as s on b.codigo_wmo = s.codigo_wmo
left join calendar as d on b.data_referencia = d.data_referencia
left join time_dim as t on b.hora_referencia = t.hora_referencia