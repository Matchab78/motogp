-- stg_circuits must be unique by circuit_name (tested); LEFT JOIN preserves wins.
select w.*, c.circuit_country,
       case when c.circuit_name is null then false else true end as circuit_matched
from {{ ref('stg_race_winners') }} w
left join {{ ref('stg_circuits') }} c on c.circuit_name = w.circuit_name
