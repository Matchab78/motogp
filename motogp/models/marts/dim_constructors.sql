-- Null remains a distinct member via its stable key; label is only for display.
select distinct {{ stable_key(['constructor_name']) }} as constructor_key,
       constructor_name,
       coalesce(constructor_name, 'Constructeur inconnu') as constructor_label
from {{ ref('int_race_winners_enriched') }}
