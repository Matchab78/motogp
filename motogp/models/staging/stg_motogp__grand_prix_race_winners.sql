-- Une ligne importée correspond à une victoire enregistrée, sans dédoublonnage.
select cast(source_row_id as text) as win_id,
       cast(source_row_id as bigint) as source_row_id,
       cast(season as integer) as season,
       nullif(trim(circuit), '') as circuit_name,
       nullif(trim(class), '') as class_name,
       nullif(trim(constructor), '') as constructor_name,
       nullif(trim(country), '') as rider_country,
       nullif(trim(rider), '') as rider_name,
       1 as win_count
from {{ source('motogp_raw', 'grand_prix_race_winners') }}
