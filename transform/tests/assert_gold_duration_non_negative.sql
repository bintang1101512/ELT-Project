select
    ta_id,
    ta_start_time_wib,
    ta_end_time_wib,
    duration_minute
from {{ ref('gold_layer') }}
where duration_minute < 0
