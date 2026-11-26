select cast(source_row_id as bigint) as source_row_id,
       cast(season as integer) as season,
       nullif(trim(constructor), '') as constructor_name,
       nullif(trim(class), '') as class_name
from {{ source('motogp_raw', 'constructor_world_championship') }}
