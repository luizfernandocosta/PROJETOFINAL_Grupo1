-- Dashboard 1: volume de chuva por estação e mês
SELECT
  d.ano_mes
  ,s.regiao
  ,s.uf
  ,s.nome_estacao
  ,ROUND(SUM(f.precipitacao_mm)::NUMERIC, 2) AS precipitacao_total_mm
  ,COUNT(*) AS leituras
FROM gold.fact_weather_hourly AS f

JOIN gold.dim_station AS s
ON f.station_sk = s.station_sk

JOIN gold.dim_date AS d
ON f.date_sk = d.date_sk

GROUP BY 1, 2, 3, 4

ORDER BY d.ano_mes, precipitacao_total_mm DESC;

-- Dashboard 2: temperatura e umidade médias por dia
SELECT
  f.data_referencia
  ,s.uf
  ,ROUND(AVG(f.temperatura_c)::NUMERIC, 2) AS temperatura_media_c
  ,ROUND(AVG(f.umidade_pct)::NUMERIC, 2) AS umidade_media_pct
FROM gold.fact_weather_hourly AS f

JOIN gold.dim_station AS s
ON f.station_sk = s.station_sk

GROUP BY 1, 2

ORDER BY 1, 2;

-- Dashboard 3: contagem de chuva intensa (alerta operacional)
SELECT
  f.data_referencia
  ,s.regiao
  ,COUNT(*) AS eventos_chuva_intensa
FROM gold.fact_weather_hourly AS f

JOIN gold.dim_station AS s
ON f.station_sk = s.station_sk

WHERE f.intensidade_chuva = 'chuva_intensa'

GROUP BY 1, 2

ORDER BY 1, 3 DESC;