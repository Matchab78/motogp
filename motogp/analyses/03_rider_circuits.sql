-- Question 3 : sur quels circuits chaque pilote gagne-t-il le plus, par catégorie ?
-- Les pays inconnus d'un même nom sont regroupés, sans rapprochement entre fichiers.
with totals as (
    select r.rider_name, c.class_name, t.circuit_name, t.circuit_country,
           sum(f.win_count) as wins
    from {{ ref('fct_wins') }} f
    join {{ ref('dim_riders') }} r on r.rider_key = f.rider_key
    join {{ ref('dim_classes') }} c on c.class_key = f.class_key
    join {{ ref('dim_circuits') }} t on t.circuit_key = f.circuit_key
    group by r.rider_name, c.class_name, t.circuit_name, t.circuit_country
), ranked as (
    select *, dense_rank() over (partition by rider_name, class_name order by wins desc) as circuit_rank
    from totals
)
select * from ranked where circuit_rank <= 3
order by rider_name, class_name, circuit_rank, circuit_name
