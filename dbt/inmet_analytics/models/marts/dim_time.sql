WITH base AS (
    SELECT DISTINCT hora_referencia
    FROM {{ ref('stg_inmet_weather') }}
    WHERE hora_referencia IS NOT NULL
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['hora_referencia']) }} AS time_sk
    ,hora_referencia
    ,EXTRACT(HOUR FROM hora_referencia)::INT AS hora_int
    ,CASE
        WHEN EXTRACT(HOUR FROM hora_referencia) BETWEEN 0 and 5 THEN 'madrugada'
        WHEN EXTRACT(HOUR FROM hora_referencia) BETWEEN 6 and 11 THEN 'manha'
        WHEN EXTRACT(HOUR FROM hora_referencia) BETWEEN 12 and 17 THEN 'tarde'
        ELSE 'noite'
        END AS periodo_dia
FROM base