{% macro precipitation_intensity_bucket(precip_col) %}
  CASE
    WHEN {{ precip_col }} IS NULL THEN 'sem_dado'
    WHEN {{ precip_col }} = 0 THEN 'sem_chuva'
    WHEN {{ precip_col }} > 0 and {{ precip_col }} <=  5 THEN 'chuva_fraca'
    WHEN {{ precip_col }} > 5 and {{ precip_col }} <= 25 THEN 'chuva_moderada'
    ELSE 'chuva_intensa'
    END
{% endmacro %}