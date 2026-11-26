select distinct {{ stable_key(['class_name']) }} as class_key, class_name
from {{ ref('int_race_winners_enriched') }}
