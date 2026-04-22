{% macro wind_risk_level(rajada_col) %}
  CASE
    WHEN {{ rajada_col }} IS NULL THEN 'sem_dado'
    WHEN {{ rajada_col }} <  10 THEN 'vento_fraco'
    WHEN {{ rajada_col }} >= 10 AND {{ rajada_col }} < 20 THEN 'vento_moderado'
    WHEN {{ rajada_col }} >= 20 AND {{ rajada_col }} < 35 THEN 'vento_forte'
    ELSE 'vento_tempestade'
    END
{% endmacro %}