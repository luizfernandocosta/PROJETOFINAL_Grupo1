with base as (
    select distinct data_referencia
    from {{ ref('stg_inmet_weather') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['data_referencia']) }}  as date_sk,
    data_referencia,
    extract(year  from data_referencia)::int                     as ano,
    extract(month from data_referencia)::int                     as mes,
    extract(day   from data_referencia)::int                     as dia,
    to_char(data_referencia, 'YYYY-MM')                          as ano_mes,
    to_char(data_referencia, 'Day')                              as nome_dia_semana
from base
