{% snapshot snap_circuits %}
{{ config(
    target_schema=target.schema ~ '_snapshots',
    unique_key='circuit_name',
    strategy='check',
    check_cols=['circuit_country', 'historical_events_reported'],
    invalidate_hard_deletes=True
) }}
-- No reliable updated_at in CSV: compare attributes on each execution.
select circuit_name, circuit_country, historical_events_reported
from {{ ref('stg_circuits') }}
{% endsnapshot %}
