select cast(source_row_id as bigint) as source_row_id,
       cast(season as integer) as season,
       nullif(trim(track), '') as circuit_name,
       nullif(trim(riders_nation), '') as riders_country,
       nullif(trim(class), '') as class_name
from {{ source('motogp_raw', 'same_nation_podium_lockouts') }}
