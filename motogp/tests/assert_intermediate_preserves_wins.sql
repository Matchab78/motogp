-- Check exact row membership and measure after the circuit LEFT JOIN.
select coalesce(s.win_id, i.win_id) as win_id
from {{ ref('stg_motogp__grand_prix_race_winners') }} s
full outer join {{ ref('int_race_winners_enriched') }} i on i.win_id = s.win_id
where s.win_id is null or i.win_id is null or s.win_count <> i.win_count
