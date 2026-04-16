with base as (
    select distinct hora_referencia
    from {{ ref('stg_inmet_weather') }}
    where hora_referencia is not null
)

select
    {{ dbt_utils.generate_surrogate_key(['hora_referencia']) }}  as time_sk,
    hora_referencia,
    extract(hour from hora_referencia)::int                      as hora_int,
    case
        when extract(hour from hora_referencia) between  0 and  5 then 'madrugada'
        when extract(hour from hora_referencia) between  6 and 11 then 'manha'
        when extract(hour from hora_referencia) between 12 and 17 then 'tarde'
        else                                                            'noite'
    end                                                          as periodo_dia
from base
