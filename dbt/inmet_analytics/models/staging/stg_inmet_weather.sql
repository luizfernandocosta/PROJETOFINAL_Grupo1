WITH 
source_data AS (
    SELECT *
    FROM {{ source('raw', 'inmet_weather_raw') }}
),

renamed AS (
    SELECT
        LTRIM(meta_codigo_wmo, ';') AS codigo_wmo
        ,LTRIM(meta_estacao, ';') AS nome_estacao
        ,LTRIM(meta_uf, ';') AS uf
        ,LTRIM(meta_regiao, ';') AS regiao
        ,NULLIF(NULLIF(REPLACE(LTRIM(meta_latitude, ';'), ',', '.'), ''), 'NULL')::NUMERIC(10, 6) AS latitude
        ,NULLIF(NULLIF(REPLACE(LTRIM(meta_longitude, ';'), ',', '.'), ''), 'NULL')::NUMERIC(10, 6) AS longitude
        ,NULLIF(NULLIF(REPLACE(LTRIM(meta_altitude, ';'), ',', '.'), ''), 'NULL')::NUMERIC(10, 2) AS altitude
        ,data::DATE AS data_referencia
        ,hora_referencia::TIME AS hora_referencia

        -- Tempo em horário local (por estado)
        -- A macro uf_to_timezone mapeia cada UF para seu fuso horário brasileiro
        ,(
            (data::DATE::TEXT || ' ' || hora_referencia)::TIMESTAMP AT TIME ZONE 'UTC'
            AT TIME ZONE {{ uf_to_timezone("LTRIM(meta_uf, ';')") }}
            ) AS data_hora_local

        ,NULLIF(NULLIF(REPLACE(temperatura_do_ar_bulbo_seco_horaria, ',', '.'), ''), 'NULL')::NUMERIC(10, 2) AS temperatura_c
        ,NULLIF(NULLIF(REPLACE(umidade_relativa_do_ar_horaria, ',', '.'), ''), 'NULL')::NUMERIC(10, 2) AS umidade_pct
        ,NULLIF(NULLIF(REPLACE(precipitacao_total_horario, ',', '.'), ''), 'NULL')::NUMERIC(10, 2) AS precipitacao_mm
        ,NULLIF(NULLIF(REPLACE(vento_velocidade_horaria_m_s, ',', '.'), ''), 'NULL')::NUMERIC(10, 2) AS vento_velocidade_ms
        ,NULLIF(NULLIF(REPLACE(vento_direcao_horaria_gr_gr, ',', '.'), ''), 'NULL')::NUMERIC(6, 1) AS vento_direcao_graus
        ,NULLIF(NULLIF(REPLACE(vento_rajada_maxima_m_s, ',', '.'), ''), 'NULL')::NUMERIC(10, 2) AS vento_rajada_ms
        ,NULLIF(NULLIF(REPLACE(pressao_atmosferica_ao_nivel_da_estacao_horaria_mb, ',', '.'), ''), 'NULL')::NUMERIC(10, 2) AS pressao_atm_hpa
        ,source_year
        ,source_file
        ,loaded_at::TIMESTAMP AS loaded_at

    FROM source_data
)

SELECT *
FROM renamed
where data_referencia IS NOT NULL