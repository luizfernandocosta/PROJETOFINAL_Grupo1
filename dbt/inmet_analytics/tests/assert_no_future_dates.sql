-- Teste singular 1: não pode haver data futura na fato
select *
from {{ ref('fact_weather_hourly') }}
where data_referencia > current_date
