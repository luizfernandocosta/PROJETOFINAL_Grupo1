with base as (
    select *
    from {{ ref('stg_inmet_weather') }}
),
station as (
    select * from {{ ref('dim_station') }}
),
calendar as (
    select * from {{ ref('dim_date') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['b.codigo_wmo','b.data_referencia','b.hora_referencia']) }} as weather_event_sk,
    s.station_sk,
    d.date_sk,
    b.data_referencia,
    b.hora_referencia,
    b.temperatura_c,
    b.umidade_pct,
    b.precipitacao_mm,
    {{ precipitation_intensity_bucket('b.precipitacao_mm') }} as intensidade_chuva,
    b.source_year,
    b.source_file,
    b.loaded_at
from base b
left join station s
    on b.codigo_wmo = s.codigo_wmo
left join calendar d
    on b.data_referencia = d.data_referencia
