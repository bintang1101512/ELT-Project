{{
    config(
        materialized="incremental",
        schema='gold',
        partition_by={
            "field": "ta_start_time_wib",
            "data_type": "datetime",
            "granularity": "day"
        },
        cluster_by=["name", "region", "username", "group_name"],
        unique_key="ta_id",
        on_schema_change='sync_all_columns',
        incremental_predicates=[
            "DBT_INTERNAL_DEST.ta_start_time_wib >= DATETIME_SUB(CURRENT_DATETIME(), INTERVAL 1 DAY)"
        ]
    )
}}

with base as (
    select 
        a.ta_id,
        e.name,
        e.city AS box_city,
        e.region,
        c.username,
        e.group_name,
        CASE 
            WHEN d.partner_type_volume_partner = true THEN 'Yes'
            ELSE 'No'
        END AS vp_status,
        DATETIME(a.ta_start_time, "Asia/Jakarta") AS ta_start_time_wib,
        DATETIME(a.ta_end_time, "Asia/Jakarta") AS ta_end_time_wib,
        DATETIME(a.updated_at, "Asia/Jakarta") AS updated_at,
        ROUND(DATETIME_DIFF(
            DATETIME(a.ta_end_time, "Asia/Jakarta"),
            DATETIME(a.ta_start_time, "Asia/Jakarta"),
            SECOND
        ) / 60, 2) AS duration_minute,
        a.ta_uco_volume,
        a.ta_slops_volume,
        a.ta_uco_weight,
        a.ta_slops_weight,
        a.uco_approved,
        a.amount,
        a.bonus,
        a.fare,
        a.total_amount,
        a.method,
        a.density,
        a.detail_transaction,
        a.box_brand_partner,
        a.alcohol_level,
        e.postcode AS box_postcode,
        c.full_name,
        c.user_type,
        c.email,
        c.phone_number,
        c.city AS user_city,
        c.postcode AS user_postcode,
        c.region AS user_region,
        c.referral_code,
        d.partner_account,
        d.contact_legal_name,
        CASE 
            WHEN a.user_brand_partner IS NULL 
              OR a.user_brand_partner = 'artotel' 
              OR a.user_brand_partner = 'greenbooks' 
            THEN 'ucollectapps' 
            ELSE a.user_brand_partner 
        END AS user_type_apps,
        CASE 
            WHEN c.referral_code IS NULL THEN 'no referral code' 
            ELSE c.referral_code 
        END AS referral_code_user,
        a.updated_at AS updated_at_raw  -- untuk filter incremental

    from {{ ref("stg_transaction") }} as a
    left join {{ ref("stg_user") }} as c 
        on a.ta_id = c.ta_id
    left join {{ ref("stg_box_status") }} as e
        on a.box_id = e.box_id
    left join {{ ref("stg_vp") }} as d
        on a.user_id = d.user__id

    {% if is_incremental() %}
    where 
        a.updated_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 12 HOUR)
    {% endif %}
)

select * except(updated_at_raw)
from base