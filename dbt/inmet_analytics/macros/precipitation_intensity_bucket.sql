{% macro precipitation_intensity_bucket(precip_col) %}
  case
    when {{ precip_col }} is null                           then 'sem_dado'
    when {{ precip_col }} = 0                               then 'sem_chuva'
    when {{ precip_col }} > 0 and {{ precip_col }} <=  5   then 'chuva_fraca'
    when {{ precip_col }} > 5 and {{ precip_col }} <= 25   then 'chuva_moderada'
    else                                                         'chuva_intensa'
  end
{% endmacro %}
