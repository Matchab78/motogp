select cast(source_row_id as bigint) as source_row_id,
       nullif(trim(track), '') as circuit_name,
       nullif(trim(country), '') as circuit_country,
       cast(times as integer) as historical_events_reported
from {{ source('motogp_raw', 'grand_prix_events_held') }}
