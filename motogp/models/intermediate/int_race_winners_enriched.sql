-- stg_motogp__grand_prix_events_held must be unique by circuit_name (tested); LEFT JOIN preserves wins.
select w.*, row_number() over (
           partition by w.season, w.circuit_name, w.class_name,
                        w.constructor_name, w.rider_country, w.rider_name
           order by w.source_row_id
       ) as duplicate_ordinal,
       c.circuit_country,
       case when c.circuit_name is null then false else true end as circuit_matched
from {{ ref('stg_motogp__grand_prix_race_winners') }} w
left join {{ ref('stg_motogp__grand_prix_events_held') }} c on c.circuit_name = w.circuit_name
