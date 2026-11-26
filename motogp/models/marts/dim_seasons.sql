select distinct season as season_key, season,
       cast(floor(season / 10.0) * 10 as integer) as decade
from {{ ref('int_race_winners_enriched') }}
