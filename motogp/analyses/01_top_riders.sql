-- Question 1 : quels pilotes ont le plus de victoires enregistrées par saison et catégorie ?
-- Grain de restitution : saison, catégorie, nom du pilote (pays source fusionnés explicitement).
with totals as (
    select s.season, c.class_name, r.rider_name, sum(f.win_count) as wins
    from {{ ref('fct_wins') }} f
    join {{ ref('dim_seasons') }} s on s.season_key = f.season_key
    join {{ ref('dim_classes') }} c on c.class_key = f.class_key
    join {{ ref('dim_riders') }} r on r.rider_key = f.rider_key
    group by s.season, c.class_name, r.rider_name
), ranked as (
    select *, rank() over (partition by season, class_name order by wins desc) as win_rank
    from totals
)
select * from ranked where win_rank <= 3
order by season desc, class_name, win_rank, rider_name
