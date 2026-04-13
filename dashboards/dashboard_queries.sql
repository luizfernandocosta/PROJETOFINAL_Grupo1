-- Dashboard 1: volume de chuva por estação e mês
select
  d.ano_mes,
  s.regiao,
  s.uf,
  s.nome_estacao,
  round(sum(f.precipitacao_mm)::numeric, 2) as precipitacao_total_mm,
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
  round(avg(f.temperatura_c)::numeric, 2) as temperatura_media_c,
  round(avg(f.umidade_pct)::numeric, 2) as umidade_media_pct
from gold.fact_weather_hourly f
join gold.dim_station s on f.station_sk = s.station_sk
group by 1,2
order by 1,2;

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
