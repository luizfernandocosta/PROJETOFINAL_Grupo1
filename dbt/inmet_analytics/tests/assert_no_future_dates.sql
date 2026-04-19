-- Teste singular 1: não pode haver data futura na fato
SELECT *
FROM {{ ref('fact_weather_hourly') }}
WHERE data_referencia > current_date