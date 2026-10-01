-- Tes singular: gold_layer tidak boleh menggandakan transaksi akibat join.
-- Semua join di gold_layer adalah LEFT JOIN dari stg_transaction, sehingga jumlah baris
-- gold harus sama dengan jumlah ta_id unik. Tes lulus jika tidak ada ta_id yang muncul lebih dari sekali.

select
    ta_id,
    count(*) as jumlah_baris
from {{ ref('gold_layer') }}
group by ta_id
having count(*) > 1
