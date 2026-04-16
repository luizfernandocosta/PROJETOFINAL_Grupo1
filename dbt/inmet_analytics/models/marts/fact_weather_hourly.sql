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
    extract(hour from b.hora_referencia)::int as hora_utc,
    case
        when extract(hour from b.hora_referencia) between 0 and 5 then 'madrugada'
        when extract(hour from b.hora_referencia) between 6 and 11 then 'manha'
        when extract(hour from b.hora_referencia) between 12 and 17 then 'tarde'
        else 'noite'
    end as periodo_dia,
    b.temperatura_c,
    b.umidade_pct,
    b.precipitacao_mm,
    {{ precipitation_intensity_bucket('b.precipitacao_mm') }} as intensidade_chuva,
    b.radiacao_global_kj_m2,
    case
        when b.radiacao_global_kj_m2 is null then 'sem_dado'
        when b.radiacao_global_kj_m2 = 0 then 'sem_radiacao'
        when b.radiacao_global_kj_m2 < 800 then 'radiacao_baixa'
        when b.radiacao_global_kj_m2 < 2400 then 'radiacao_media'
        else 'radiacao_alta'
    end as faixa_radiacao,
    b.vento_direcao_gr,
    case
        when b.vento_direcao_gr is null then 'sem_dado'
        when b.vento_direcao_gr >= 337.5 or b.vento_direcao_gr < 22.5 then 'N'
        when b.vento_direcao_gr < 67.5 then 'NE'
        when b.vento_direcao_gr < 112.5 then 'E'
        when b.vento_direcao_gr < 157.5 then 'SE'
        when b.vento_direcao_gr < 202.5 then 'S'
        when b.vento_direcao_gr < 247.5 then 'SO'
        when b.vento_direcao_gr < 292.5 then 'O'
        else 'NO'
    end as direcao_vento_cardinal,
    b.vento_velocidade_m_s,
    b.vento_rajada_max_m_s,
    case
        when b.vento_velocidade_m_s is null then 'sem_dado'
        when b.vento_velocidade_m_s < 2 then 'calmo'
        when b.vento_velocidade_m_s < 6 then 'fraco'
        when b.vento_velocidade_m_s < 10 then 'moderado'
        else 'forte'
    end as intensidade_vento,
    case
        when b.vento_velocidade_m_s is null or b.vento_velocidade_m_s = 0 then null
        else round((b.vento_rajada_max_m_s / b.vento_velocidade_m_s)::numeric, 2)
    end as fator_rajada,
    b.source_year,
    b.source_file,
    b.loaded_at
from base b
left join station s
    on b.codigo_wmo = s.codigo_wmo
left join calendar d
    on b.data_referencia = d.data_referencia
