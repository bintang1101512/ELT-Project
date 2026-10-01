select
    ta_id,
    count(*) as jumlah_baris
from {{ ref('gold_layer') }}
group by ta_id
having count(*) > 1
