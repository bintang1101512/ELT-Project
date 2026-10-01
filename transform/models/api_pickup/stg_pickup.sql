{{
    config(
        materialized='incremental',
        unique_key='pickup_id',
        schema='staging',
        partition_by={
            "field": "created_at",
            "data_type": "timestamp",
            "granularity": "day"
        },
        cluster_by=['pickup_id'],
        incremental_predicates=[
            "DBT_INTERNAL_DEST.created_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)"
        ]
    )
}}

with source as(
    select *
    from {{ source('source', 'raw_api_pickup') }}

    {% if is_incremental() %}
    where ingested_at >= timestamp_sub(current_timestamp(), interval 6 hour)
    {% endif %}
),

flatten as(
    SELECT

    JSON_VALUE(payload,'$._id') AS id,
    SAFE_CAST(JSON_VALUE(payload,'$.__v') AS FLOAT64) AS version,

    JSON_VALUE(payload,'$.status') AS status,
    JSON_VALUE(payload,'$.platform') AS platform,

    JSON_VALUE(payload,'$.pickup_id') AS pickup_id,
    JSON_VALUE(payload,'$.pickup_type') AS pickup_type,

    JSON_VALUE(payload,'$.username') AS username,
    JSON_VALUE(payload,'$.user_id') AS user_id,

    SAFE_CAST(JSON_VALUE(payload,'$.distance') AS FLOAT64) AS distance,
    SAFE_CAST(JSON_VALUE(payload,'$.price') AS FLOAT64) AS price,
    SAFE_CAST(JSON_VALUE(payload,'$.estimated_payout') AS FLOAT64) AS estimated_payout,
    SAFE_CAST(JSON_VALUE(payload,'$.estimated_uco_price') AS FLOAT64) AS estimated_uco_price,

    SAFE_CAST(JSON_VALUE(payload,'$.uco_volume') AS FLOAT64) AS uco_volume,
    SAFE_CAST(JSON_VALUE(payload,'$.uco_weight') AS FLOAT64) AS uco_weight,

    SAFE_CAST(JSON_VALUE(payload,'$.base_price') AS FLOAT64) AS base_price,

    SAFE_CAST(JSON_VALUE(payload,'$.is_return_jerrycan') AS BOOL) AS is_return_jerrycan,

    ARRAY_TO_STRING(
    ARRAY(
        SELECT JSON_VALUE(t,'$.TA_ID')
        FROM UNNEST(JSON_QUERY_ARRAY(payload,'$.transactions')) t
    ),
    ' | '
    ) AS transaction_ta_ids,

    (
    SELECT TIMESTAMP(JSON_VALUE(t,'$.TA_Start_Time'))
    FROM UNNEST(JSON_QUERY_ARRAY(payload,'$.transactions')) t
    LIMIT 1
    ) AS transaction_date,

    CAST(JSON_VALUE(payload,'$.schedule.date') AS DATE) AS schedule_date,

    SAFE.PARSE_TIME('%H:%M', JSON_VALUE(payload,'$.schedule.start')) AS schedule_start,
    SAFE.PARSE_TIME('%H:%M', JSON_VALUE(payload,'$.schedule.end')) AS schedule_end,

    JSON_VALUE(payload,'$.gd_id') AS gd_id,
    JSON_VALUE(payload,'$.mo_id') AS mo_id,
    JSON_VALUE(payload,'$.trx_id') AS trx_id,

    JSON_VALUE(payload,'$.grab_status') AS grab_status,
    JSON_VALUE(payload,'$.grab_link') AS grab_link,

    JSON_VALUE(payload,'$.failedReason') AS failed_reason,
    JSON_VALUE(payload,'$.errorReason') AS error_reason,

    -- timestamps
    TIMESTAMP(JSON_VALUE(payload,'$.createdAt')) AS created_at,
    TIMESTAMP(JSON_VALUE(payload,'$.updatedAt')) AS updated_at,
    TIMESTAMP(JSON_VALUE(payload,'$.pickup_date')) AS pickup_date,

    -- address
    JSON_VALUE(payload,'$.address.name') AS address_name,
    JSON_VALUE(payload,'$.address.city') AS address_city,
    JSON_VALUE(payload,'$.address.full_address') AS address_full_address,
    JSON_VALUE(payload,'$.address.description') AS address_description,

    SAFE_CAST(JSON_VALUE(payload,'$.address.latitude') AS FLOAT64) AS address_latitude,
    SAFE_CAST(JSON_VALUE(payload,'$.address.longitude') AS FLOAT64) AS address_longitude,

    JSON_VALUE(payload,'$.address.postal_code') AS address_postal_code,

    -- box
    JSON_VALUE(payload,'$.box._id') AS box_id,
    JSON_VALUE(payload,'$.box.name') AS box_name,
    JSON_VALUE(payload,'$.box.address') AS box_address,

    -- driver
    JSON_VALUE(payload,'$.driver.name') AS driver_name,
    JSON_VALUE(payload,'$.driver.phone') AS driver_phone,
    JSON_VALUE(payload,'$.driver.licensePlate') AS driver_license_plate,

    SAFE_CAST(JSON_VALUE(payload,'$.driver.currentLat') AS FLOAT64) AS driver_latitude,
    SAFE_CAST(JSON_VALUE(payload,'$.driver.currentLng') AS FLOAT64) AS driver_longitude,

    -- schedule


    SAFE_CAST(JSON_VALUE(payload,'$.schedule.timezone') AS FLOAT64) AS schedule_timezone,

    -- timeline
    TIMESTAMP(JSON_VALUE(payload,'$.timeline.create')) AS timeline_create,
    TIMESTAMP(JSON_VALUE(payload,'$.timeline.allocate')) AS timeline_allocate,
    TIMESTAMP(JSON_VALUE(payload,'$.timeline.pickup')) AS timeline_pickup,
    TIMESTAMP(JSON_VALUE(payload,'$.timeline.dropoff')) AS timeline_dropoff,
    TIMESTAMP(JSON_VALUE(payload,'$.timeline.completed')) AS timeline_completed,
    ingested_at
from source
),

dedup as(
select *,
    ROW_NUMBER() OVER (
    PARTITION BY pickup_id
    ORDER BY updated_at DESC
    ) AS rn
from flatten)

select * except(rn)
from dedup
where rn = 1
