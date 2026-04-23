{{
    config(
        materialized='incremental',
        unique_key='ta_id',
        schema='staging',
        partition_by={
            "field": "updated_at",
            "data_type": "timestamp",
            "granularity": "day"
        },
        cluster_by=['ta_id'],
        incremental_predicates=[
            "DBT_INTERNAL_DEST.updated_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 12 HOUR)"
        ]
    )
}}

with source as (

    select *
    from {{ source('source', 'raw_api') }}

    {% if is_incremental() %}
    where ingested_at >= timestamp_sub(current_timestamp(), interval 3 hour)
    {% endif %}

),

parsed as (

    select
      JSON_VALUE(payload, '$._id') AS _id,
      JSON_VALUE(payload, '$.boxId') AS box_id,
      JSON_VALUE(payload, '$.TA_USER_ID') AS user_id,
      TRIM(JSON_VALUE(payload, '$.TA_ID')) AS ta_id,

      TIMESTAMP(JSON_VALUE(payload, '$.TA_Start_Time')) AS ta_start_time,
      TIMESTAMP(JSON_VALUE(payload, '$.TA_End_Time')) AS ta_end_time,
      TIMESTAMP(JSON_VALUE(payload, '$.createdAt')) AS created_at,
      TIMESTAMP(JSON_VALUE(payload, '$.updatedAt')) AS updated_at,

      SAFE_CAST(JSON_VALUE(payload, '$.TA_UCO_Volume') AS FLOAT64) AS ta_uco_volume,
      SAFE_CAST(JSON_VALUE(payload, '$.TA_Slops_Volume') AS FLOAT64) AS ta_slops_volume,
      SAFE_CAST(JSON_VALUE(payload, '$.TA_UCO_Weight') AS FLOAT64) AS ta_uco_weight,
      SAFE_CAST(JSON_VALUE(payload, '$.TA_Slops_Weight') AS FLOAT64) AS ta_slops_weight,
      SAFE_CAST(JSON_VALUE(payload, '$.UCO_Approved') AS BOOL) AS uco_approved,

      SAFE_CAST(JSON_VALUE(payload, '$.amount') AS FLOAT64) AS amount,
      JSON_VALUE(payload, '$.address.address') AS address_detail,
      JSON_VALUE(payload, '$.address.city') AS city,
      JSON_VALUE(payload, '$.address.country') AS country,
      JSON_VALUE(payload, '$.address.postcode') AS postcode,

      SAFE_CAST(JSON_VALUE(payload, '$.bonus') AS FLOAT64) AS bonus,
      SAFE_CAST(JSON_VALUE(payload, '$.totalAmount') AS FLOAT64) AS total_amount,
      JSON_VALUE(payload, '$.method') AS method,

      JSON_VALUE(payload, '$.extraData.alcohol_level') AS alcohol_level,
      JSON_VALUE(payload, '$.extraData.carbon_level') AS carbon_level,
      SAFE_CAST(JSON_VALUE(payload, '$.extraData.density') AS FLOAT64) AS density,
      SAFE_CAST(JSON_VALUE(payload, '$.extraData.density_blackbox') AS FLOAT64) AS density_blackbox,
      SAFE_CAST(JSON_VALUE(payload, '$.extraData.density_config') AS FLOAT64) AS density_config,
      JSON_VALUE(payload, '$.extraData.detail_transaction') AS detail_transaction,

      SAFE_CAST(JSON_VALUE(payload, '$.fare') AS FLOAT64) AS fare,
      JSON_VALUE(payload, '$.admin_id') AS admin_id,
      SAFE_CAST(JSON_VALUE(payload, '$.uco_price_per_liter') AS FLOAT64) AS uco_price_per_liter,

      JSON_VALUE(payload, '$.slug.user_brand_partner') AS user_brand_partner,
      JSON_VALUE(payload, '$.slug.box_brand_partner') AS box_brand_partner,

      ingested_at

    from source

),

filtered as (
    select * from parsed
    {% if is_incremental() %}
    where updated_at >= timestamp_sub(current_timestamp(), interval 12 hour)
    {% endif %}
),

dedup as (

    select *,
      ROW_NUMBER() OVER (
        PARTITION BY ta_id
        ORDER BY updated_at DESC, ingested_at DESC
      ) as rn
    from filtered
    where ta_id is not null

)

select * except(rn)
from dedup
where rn = 1