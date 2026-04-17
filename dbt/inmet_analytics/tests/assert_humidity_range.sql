-- Teste singular 2: umidade fora da faixa física esperada
SELECT *
FROM {{ ref('fact_weather_hourly') }}
WHERE umidade_pct < 0 OR umidade_pct > 100