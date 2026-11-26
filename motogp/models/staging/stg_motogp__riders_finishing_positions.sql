-- Preserve homonyms/duplicates. Do not join this model to wins on rider_name alone.
select cast(source_row_id as bigint) as source_row_id,
       nullif(trim(rider), '') as rider_name,
       nullif(trim(country), '') as rider_country,
       cast(victories as integer) as career_wins,
       cast(number_of_second as integer) as second_places,
       cast(number_of_third as integer) as third_places,
       cast(number_of_4th as integer) as fourth_places,
       cast(number_of_5th as integer) as fifth_places,
       cast(number_of_6th as integer) as sixth_places
from {{ source('motogp_raw', 'riders_finishing_positions') }}
