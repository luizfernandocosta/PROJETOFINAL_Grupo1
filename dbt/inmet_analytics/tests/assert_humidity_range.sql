-- Teste singular 2: umidade fora da faixa física esperada
select *
from {{ ref('fact_weather_hourly') }}
where umidade_pct < 0
   or umidade_pct > 100
