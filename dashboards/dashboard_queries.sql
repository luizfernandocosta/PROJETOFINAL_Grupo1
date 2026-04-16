-- Dashboard 1: volume de chuva por estação e mês
select
  d.ano_mes,
  s.regiao,
  s.uf,
  s.nome_estacao,
  round(sum(f.precipitacao_mm)::numeric, 2) as precipitacao_total_mm,
  round(avg(f.radiacao_global_kj_m2)::numeric, 2) as radiacao_media_kj_m2,
  round(avg(f.vento_velocidade_m_s)::numeric, 2) as vento_medio_m_s,
  count(*) as leituras
from gold.fact_weather_hourly f
join gold.dim_station s on f.station_sk = s.station_sk
join gold.dim_date d on f.date_sk = d.date_sk
group by 1,2,3,4
order by d.ano_mes, precipitacao_total_mm desc;

-- Dashboard 2: temperatura e umidade médias por dia
select
  f.data_referencia,
  s.uf,
  f.periodo_dia,
  round(avg(f.temperatura_c)::numeric, 2) as temperatura_media_c,
  round(avg(f.umidade_pct)::numeric, 2) as umidade_media_pct,
  round(avg(f.radiacao_global_kj_m2)::numeric, 2) as radiacao_media_kj_m2
from gold.fact_weather_hourly f
join gold.dim_station s on f.station_sk = s.station_sk
group by 1,2,3
order by 1,2,3;

-- Dashboard 2b: contagem de chuva intensa (alerta operacional)
select
  f.data_referencia,
  s.regiao,
  count(*) as eventos_chuva_intensa
from gold.fact_weather_hourly f
join gold.dim_station s on f.station_sk = s.station_sk
where f.intensidade_chuva = 'chuva_intensa'
group by 1,2
order by 1,3 desc;

-- Dashboard 3: rosas dos ventos simplificada por UF
select
  s.uf,
  f.direcao_vento_cardinal,
  round(avg(f.vento_velocidade_m_s)::numeric, 2) as vento_medio_m_s,
  round(max(f.vento_rajada_max_m_s)::numeric, 2) as rajada_max_m_s,
  count(*) as leituras
from gold.fact_weather_hourly f
join gold.dim_station s on f.station_sk = s.station_sk
group by 1,2
order by 1,5 desc;

-- Dashboard 4: risco operacional (chuva intensa + vento forte)
select
  f.data_referencia,
  s.nome_estacao,
  s.uf,
  f.hora_utc,
  f.intensidade_chuva,
  f.intensidade_vento,
  f.precipitacao_mm,
  f.vento_velocidade_m_s,
  f.vento_rajada_max_m_s,
  f.fator_rajada
from gold.fact_weather_hourly f
join gold.dim_station s on f.station_sk = s.station_sk
where f.intensidade_chuva in ('chuva_moderada', 'chuva_intensa')
  and f.intensidade_vento in ('moderado', 'forte')
order by f.data_referencia desc, f.hora_utc desc, f.fator_rajada desc nulls last;
