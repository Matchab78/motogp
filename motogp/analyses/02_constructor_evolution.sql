-- Question 2 : comment évolue la part des victoires de chaque constructeur ?
-- Grille annuelle par catégorie : les années sans victoire du constructeur valent zéro.
with bounds as (
    select f.class_key, min(s.season) as first_season, max(s.season) as last_season
    from {{ ref('fct_wins') }} f join {{ ref('dim_seasons') }} s on s.season_key = f.season_key
    group by f.class_key
), pairs as (
    select distinct class_key, constructor_key from {{ ref('fct_wins') }}
), yearly as (
    select class_key, constructor_key, season_key, sum(win_count) as wins
    from {{ ref('fct_wins') }} group by class_key, constructor_key, season_key
), grid as (
    select p.class_key, p.constructor_key, s.season, coalesce(y.wins, 0) as wins
    from pairs p join bounds b on b.class_key = p.class_key
    join {{ ref('dim_seasons') }} s on s.season between b.first_season and b.last_season
    left join yearly y on y.class_key = p.class_key and y.constructor_key = p.constructor_key
        and y.season_key = s.season_key
), shares as (
    select *, round(100.0 * wins / nullif(sum(wins) over (partition by class_key, season), 0), 2)
        as win_share_pct
    from grid
), compared as (
    select *, lag(win_share_pct) over (partition by class_key, constructor_key order by season)
        as previous_share_pct
    from shares
)
select x.season, c.class_name, d.constructor_label, x.wins, x.win_share_pct,
       x.previous_share_pct, x.win_share_pct - x.previous_share_pct as change_percentage_points
from compared x
join {{ ref('dim_classes') }} c on c.class_key = x.class_key
join {{ ref('dim_constructors') }} d on d.constructor_key = x.constructor_key
order by c.class_name, d.constructor_label, x.season
