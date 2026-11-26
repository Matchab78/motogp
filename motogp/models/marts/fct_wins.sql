-- Grain: one recorded win row, not one fully identified race.
-- Same key expressions as dimensions avoid a fan-out join during fact creation.
select win_id,
       {{ stable_key(['rider_name', 'rider_country']) }} as rider_key,
       {{ stable_key(['constructor_name']) }} as constructor_key,
       {{ stable_key(['circuit_name']) }} as circuit_key,
       season as season_key,
       {{ stable_key(['class_name']) }} as class_key,
       win_count
from {{ ref('int_race_winners_enriched') }}
-- Explicit graph dependencies: dimensions must pass tests before the fact is built.
-- depends_on: {{ ref('dim_riders') }}
-- depends_on: {{ ref('dim_constructors') }}
-- depends_on: {{ ref('dim_circuits') }}
-- depends_on: {{ ref('dim_seasons') }}
-- depends_on: {{ ref('dim_classes') }}
