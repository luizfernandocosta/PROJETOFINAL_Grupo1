{% macro wind_risk_level(rajada_col) %}
  case
    when {{ rajada_col }} is null                          then 'sem_dado'
    when {{ rajada_col }} <  10                            then 'vento_fraco'
    when {{ rajada_col }} >= 10 and {{ rajada_col }} < 20  then 'vento_moderado'
    when {{ rajada_col }} >= 20 and {{ rajada_col }} < 35  then 'vento_forte'
    else                                                        'vento_tempestade'
  end
{% endmacro %}
