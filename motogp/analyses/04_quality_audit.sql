-- Quality audit for the presentation: retain rather than hide source limitations.
select 'recorded_win_rows' as indicator, count(*) as value from {{ ref('stg_race_winners') }}
union all
select 'extra_identical_rows_after_cleaning', count(*) from {{ ref('stg_race_winners') }} where duplicate_ordinal > 1
union all
select 'missing_constructor', count(*) from {{ ref('stg_race_winners') }} where constructor_name is null
union all
select 'missing_rider_country', count(*) from {{ ref('stg_race_winners') }} where rider_country is null
union all
select 'wins_without_circuit_reference', count(*) from {{ ref('int_race_winners_enriched') }} where not circuit_matched
