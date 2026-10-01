-- Tes singular: durasi transaksi tidak boleh negatif.
-- Tes lulus jika query ini mengembalikan 0 baris.
-- NULL diabaikan: transaksi yang belum selesai (ta_end_time kosong) tidak punya durasi.

select
    ta_id,
    ta_start_time_wib,
    ta_end_time_wib,
    duration_minute
from {{ ref('gold_layer') }}
where duration_minute < 0
