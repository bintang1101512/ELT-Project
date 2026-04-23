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
            "DBT_INTERNAL_DEST.updated_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 12 hour)"
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

flatten as (

    SELECT
      JSON_VALUE(payload, '$._id') AS _id,
      TRIM(JSON_VALUE(payload, '$.TA_ID')) AS ta_id,

      JSON_VALUE(u, '$.name') AS full_name,
      JSON_VALUE(u, '$.username') AS username,
      JSON_VALUE(u, '$.user_type') AS user_type,
      JSON_VALUE(u, '$.email') AS email,
      JSON_VALUE(u, '$.phone.number') AS phone_number,
      JSON_VALUE(u, '$.address') AS address,
      JSON_VALUE(u, '$.city') AS city,
      JSON_VALUE(u, '$.postcode') AS postcode,
      JSON_VALUE(u, '$.region') AS region,
      JSON_VALUE(u, '$.country') AS country,
      JSON_VALUE(u, '$.currency') AS currency,
      JSON_VALUE(u, '$.referral_code') AS referral_code,

      TIMESTAMP(JSON_VALUE(payload, '$.createdAt')) AS created_at,
      TIMESTAMP(JSON_VALUE(payload, '$.updatedAt')) AS updated_at,

      ingested_at

    FROM source,
    UNNEST(JSON_QUERY_ARRAY(payload, '$.user')) AS u

),

filtered as (
    select * from flatten
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