with base as (
    select distinct
        codigo_wmo,
        nome_estacao,
        uf,
        regiao,
        latitude,
        longitude,
        altitude
    from {{ ref('stg_inmet_weather') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['codigo_wmo']) }} as station_sk,
    codigo_wmo,
    nome_estacao,
    uf,
    regiao,
    latitude,
    longitude,
    altitude
from base
