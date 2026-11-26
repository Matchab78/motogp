select distinct {{ stable_key(['circuit_name']) }} as circuit_key,
       circuit_name, circuit_country, circuit_matched
from {{ ref('int_race_winners_enriched') }}
