WITH
base AS (SELECT * FROM {{ ref('stg_inmet_weather') }})
,station AS (SELECT * FROM {{ ref('dim_station') }})
,calendar AS (SELECT * FROM {{ ref('dim_date') }})
,time_dim AS (SELECT * FROM {{ ref('dim_time') }})

SELECT
    {{ dbt_utils.generate_surrogate_key(['b.codigo_wmo', 'b.data_referencia', 'b.hora_referencia']) }} AS weather_event_sk
    ,s.station_sk
    ,d.date_sk
    ,t.time_sk
    ,b.data_referencia
    ,b.data_hora_local
    ,b.temperatura_c
    ,b.umidade_pct
    ,b.precipitacao_mm
    ,{{ precipitation_intensity_bucket('b.precipitacao_mm') }} AS intensidade_chuva
    ,b.vento_velocidade_ms
    ,b.vento_direcao_graus
    ,b.vento_rajada_ms
    ,{{ wind_risk_level('b.vento_rajada_ms') }} AS risco_vento
    ,b.pressao_atm_hpa
    ,b.source_year
    ,b.source_file
    ,b.loaded_at
FROM base AS b

LEFT JOIN station AS s 
ON b.codigo_wmo = s.codigo_wmo

LEFT JOIN calendar AS d 
ON b.data_referencia = d.data_referencia

LEFT JOIN time_dim AS t 
ON b.hora_referencia = t.hora_referencia