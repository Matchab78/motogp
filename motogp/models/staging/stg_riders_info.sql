-- Keep original name order. Automated inversion of multi-part names is unsafe.
-- No join to the star until a verified rider mapping is available.
select nullif(trim(rider), '') as source_rider_name,
       cast(victories as integer) as career_wins,
       cast(second_places as numeric) as second_places,
       cast(third_places as numeric) as third_places,
       cast(pole_positions_1974_2022 as numeric) as pole_positions_1974_2022,
       cast(race_fastest_lap_to_2022 as numeric) as fastest_laps_to_2022,
       cast(world_championships as numeric) as world_championships
from {{ source('motogp_raw', 'riders_info') }}
