-- Business rule: no recorded win may disappear or be multiplied in the star.
with expected as (
    select season, class_name, count(*) as expected_wins
    from {{ ref('stg_motogp__grand_prix_race_winners') }} group by season, class_name
), actual as (
    select f.season_key as season, c.class_name, sum(f.win_count) as actual_wins
    from {{ ref('fct_wins') }} f
    join {{ ref('dim_classes') }} c on c.class_key = f.class_key
    group by f.season_key, c.class_name
)
select coalesce(e.season, a.season) as season,
       coalesce(e.class_name, a.class_name) as class_name,
       e.expected_wins, a.actual_wins
from expected e full outer join actual a
    on a.season = e.season and a.class_name = e.class_name
where coalesce(e.expected_wins, 0) <> coalesce(a.actual_wins, 0)
