{{
    config(
        materialized='incremental',
        unique_key='_id',
        schema='staging',
        partition_by={
            "field": "updatedat",
            "data_type": "timestamp",
            "granularity": "day"
        }
    )
}}

with source as(
    select *
    from {{ source('source', 'raw_api_vp') }}

    {% if is_incremental() %}
    where ingested_at >= timestamp_sub(current_timestamp(), interval 1 day)
    
    {% endif %}
),

flatten as (
    SELECT
      JSON_VALUE(payload, '$._id') AS _id,
      JSON_VALUE(payload, '$.user_id') AS user_id,
      JSON_VALUE(payload, '$.partner_account') AS partner_account,
      CAST(JSON_VALUE(payload, '$.is_fixed_price') AS BOOL) AS is_fixed_price,
      CAST(JSON_VALUE(payload, '$.fixed_price') AS INT64) AS fixed_price,
      CAST(JSON_VALUE(payload, '$.bonus_enabled') AS BOOL) AS bonus_enabled,
      CAST(JSON_VALUE(payload, '$.direct_payment_enabled') AS BOOL) AS direct_payment_enabled,
      CAST(JSON_VALUE(payload, '$.expected_volume') AS FLOAT64) AS expected_volume,
      CAST(JSON_VALUE(payload, '$.total_collected_volume') AS FLOAT64) AS total_collected_volume,
      JSON_VALUE(payload, '$.partner_configuration_id') AS partner_configuration_id,
      JSON_VALUE(payload, '$.country_code') AS country_code,
      TIMESTAMP(JSON_VALUE(payload, '$.createdAt')) AS createdat,
      TIMESTAMP(JSON_VALUE(payload, '$.updatedAt')) AS updatedat,
      CAST(JSON_VALUE(payload, '$.__v') AS INT64) AS version_,

      CAST(JSON_VALUE(payload, '$.partner_type.volume_partner') AS BOOL) AS partner_type_volume_partner,
      CAST(JSON_VALUE(payload, '$.partner_type.user_partner') AS BOOL) AS partner_type_user_partner,
      CAST(JSON_VALUE(payload, '$.partner_type.location_partner') AS BOOL) AS partner_type_location_partner,

      JSON_VALUE(payload, '$.partner_id') AS partner_id,
      JSON_VALUE(payload, '$.partner_referral_id') AS partner_referral_id,
      JSON_VALUE(payload, '$.partner_user_volume_id') AS partner_user_volume_id,
      JSON_VALUE(payload, '$.partner_location_id') AS partner_location_id,

      JSON_VALUE(payload, '$.contact.entity_type') AS contact_entity_type,
      JSON_VALUE(payload, '$.contact.sector_type') AS contact_sector_type,
      JSON_VALUE(payload, '$.contact.legal_name') AS contact_legal_name,
      JSON_VALUE(payload, '$.contact.contact_name') AS contact_contact_name,
      JSON_VALUE(payload, '$.contact.contact_address') AS contact_contact_address,
      JSON_VALUE(payload, '$.contact.contact_country') AS contact_contact_country,
      JSON_VALUE(payload, '$.contact.contact_region') AS contact_contact_region,
      JSON_VALUE(payload, '$.contact.contact_city') AS contact_contact_city,
      JSON_VALUE(payload, '$.contact.contact_postalcode') AS contact_contact_postalcode,
      CAST(JSON_VALUE(payload, '$.contact.contact_longitude') AS FLOAT64) AS contact_contact_longitude,
      CAST(JSON_VALUE(payload, '$.contact.contact_latitude') AS FLOAT64) AS contact_contact_latitude,
      JSON_VALUE(payload, '$.contact.contact_email') AS contact_contact_email,
      JSON_VALUE(payload, '$.contact.contact_phone') AS contact_contact_phone,
      JSON_VALUE(payload, '$.contact.contact_ktp') AS contact_contact_ktp,
      JSON_VALUE(payload, '$.contact.contact_ktp_encrypted') AS contact_contact_ktp_encrypted,
      JSON_VALUE(payload, '$.contact.contact_npwp') AS contact_contact_npwp,
      JSON_VALUE(payload, '$.contact.contact_npwp_encrypted') AS contact_contact_npwp_encrypted,
      JSON_VALUE(payload, '$.contact.sustainability_report_email') AS contact_sustainability_report_email,
      JSON_VALUE(payload, '$.contact.monthly_report_email') AS contact_monthly_report_email,

      JSON_VALUE(payload, '$.payment.bank_name') AS payment_bank_name,
      JSON_VALUE(payload, '$.payment.bank_account_number') AS payment_bank_account_number,
      JSON_VALUE(payload, '$.payment.bank_account_number_encrypted') AS payment_bank_account_number_encrypted,
      JSON_VALUE(payload, '$.payment.bank_account_name') AS payment_bank_account_name,
      JSON_VALUE(payload, '$.payment.country') AS payment_country,

      JSON_VALUE(payload, '$.language') AS language,
      CAST(JSON_VALUE(payload, '$.events') AS INT64) AS events,
      CAST(JSON_VALUE(payload, '$.reports') AS INT64) AS reports,
      CAST(JSON_VALUE(payload, '$.active') AS BOOL) AS active,
      TIMESTAMP(JSON_VALUE(payload, '$.disableAt')) AS disableAt,
      CAST(JSON_VALUE(payload, '$.balance_mistake') AS FLOAT64) AS balance_mistake,

      JSON_VALUE(payload, '$.partner_types') AS partner_types,

      JSON_VALUE(payload, '$.user._id') AS user__id,
      JSON_VALUE(payload, '$.user.name') AS user_name,
      JSON_VALUE(payload, '$.user.username') AS user_username,
      JSON_VALUE(payload, '$.user.currency') AS user_currency,
      JSON_VALUE(payload, '$.user.referral_code') AS user_referral_code,

      CAST(JSON_VALUE(payload, '$.collected_volume') AS FLOAT64) AS collected_volume

    from source
),

dedup as(
    select 
        *,
        row_number() over(
            partition by _id
            order by updatedat desc
        ) as rn
    
    from flatten
)

select * except(rn)
from dedup
where rn = 1