{% macro stable_key(columns) -%}
md5(
{%- for col in columns %}
    case when {{ col }} is null then '-1:'
         else cast(length(cast({{ col }} as text)) as text) || ':' || cast({{ col }} as text) end
    {%- if not loop.last %} || '|' || {% endif %}
{%- endfor %}
)
{%- endmacro %}
