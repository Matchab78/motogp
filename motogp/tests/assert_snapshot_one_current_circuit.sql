select circuit_name
from {{ ref('snap_circuits') }}
where dbt_valid_to is null
group by circuit_name having count(*) > 1
