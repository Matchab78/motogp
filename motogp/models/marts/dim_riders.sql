select distinct {{ stable_key(['rider_name', 'rider_country']) }} as rider_key,
       rider_name, rider_country
from {{ ref('int_race_winners_enriched') }}
