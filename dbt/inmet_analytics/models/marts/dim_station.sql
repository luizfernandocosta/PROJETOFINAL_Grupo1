WITH base AS (
    SELECT DISTINCT
        codigo_wmo
        ,nome_estacao
        ,uf
        ,regiao
        ,latitude
        ,longitude
        ,altitude
    FROM {{ ref('stg_inmet_weather') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['codigo_wmo']) }} AS station_sk
    ,codigo_wmo
    ,nome_estacao
    ,uf
    ,regiao
    ,latitude
    ,longitude
    ,altitude
FROM base
