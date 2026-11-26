-- Preserve all source rows, including apparent duplicates. Never infer a race ID.
with cleaned as (
    select cast(season as integer) as season,
           nullif(trim(circuit), '') as circuit_name,
           nullif(trim(class), '') as class_name,
           nullif(trim(constructor), '') as constructor_name,
           nullif(trim(country), '') as rider_country,
           nullif(trim(rider), '') as rider_name
    from {{ source('motogp_raw', 'grand_prix_race_winners') }}
), numbered as (
    select *, row_number() over (
        partition by season, circuit_name, class_name, constructor_name, rider_country, rider_name
        order by season
    ) as duplicate_ordinal
    from cleaned
)
select {{ stable_key(['season', 'circuit_name', 'class_name', 'constructor_name', 'rider_country', 'rider_name', 'duplicate_ordinal']) }} as win_id,
       *, 1 as win_count
from numbered
