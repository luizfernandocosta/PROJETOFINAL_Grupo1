WITH base AS (
    SELECT DISTINCT data_referencia
    FROM {{ ref('stg_inmet_weather') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['data_referencia']) }} AS date_sk
    ,data_referencia
    ,EXTRACT(YEAR FROM data_referencia)::INT AS ano
    ,EXTRACT(MONTH FROM data_referencia)::INT AS mes
    ,EXTRACT(DAY FROM data_referencia)::INT AS dia
    ,TO_CHAR(data_referencia, 'YYYY-MM') AS ano_mes
    ,TO_CHAR(data_referencia, 'Day') AS nome_dia_semana
FROM base
