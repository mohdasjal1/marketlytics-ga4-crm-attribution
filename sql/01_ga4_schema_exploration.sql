-- ==========================================================================
-- 01: GA4 Schema Exploration
-- Dataset: bigquery-public-data.ga4_obfuscated_sample_ecommerce
-- ==========================================================================

-- --------------------------------------------------------------------------
-- 1A: Top-level columns and types
-- --------------------------------------------------------------------------
SELECT
  column_name,
  data_type,
  is_nullable
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce`.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'events_20201101'
ORDER BY ordinal_position;


-- --------------------------------------------------------------------------
-- 1B: UNNEST event_params — extract specific keys by pivoting
-- event_params is ARRAY<STRUCT<key, value>> — one row per key after UNNEST
-- ~50-80 MB scan for one day
-- --------------------------------------------------------------------------
SELECT
  user_pseudo_id,
  event_name,
  event_timestamp,
  MAX(IF(p.key = 'page_location', p.value.string_value, NULL)) AS page_location,
  MAX(IF(p.key = 'session_engaged', p.value.string_value, NULL)) AS session_engaged,
  MAX(IF(p.key = 'engagement_time_msec', p.value.int_value, NULL)) AS engagement_time_msec
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`,
  UNNEST(event_params) AS p
GROUP BY user_pseudo_id, event_name, event_timestamp
LIMIT 100;


-- --------------------------------------------------------------------------
-- 1C: UNNEST event_params — filter to a single key (no pivot)
-- --------------------------------------------------------------------------
SELECT
  user_pseudo_id,
  p.key,
  p.value.string_value
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`,
  UNNEST(event_params) AS p
WHERE p.key = 'page_location'
LIMIT 50;


-- --------------------------------------------------------------------------
-- 1D: UNNEST items array — product-level detail for purchase/add_to_cart
-- items is ARRAY<STRUCT<item_id, item_name, ...>> — one row per item
-- ~50-80 MB scan for one day
-- --------------------------------------------------------------------------
SELECT
  event_date,
  user_pseudo_id,
  event_name,
  i.item_id,
  i.item_name,
  i.item_brand,
  i.item_category,
  i.price,
  i.quantity,
  i.price * i.quantity AS line_total
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`,
  UNNEST(items) AS i
WHERE event_name IN ('purchase', 'add_to_cart')
LIMIT 100;


-- --------------------------------------------------------------------------
-- 1E: traffic_source — flat STRUCT, no UNNEST needed, just dot-access
-- These map to GA4's UTM equivalents:
--   traffic_source.source → utm_source
--   traffic_source.medium → utm_medium
--   traffic_source.name   → utm_campaign
-- --------------------------------------------------------------------------
SELECT DISTINCT
  traffic_source.source,
  traffic_source.medium,
  traffic_source.name
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
WHERE traffic_source.source IS NOT NULL;


-- --------------------------------------------------------------------------
-- 1F: Wildcard table with _TABLE_SUFFIX — query multiple days efficiently
-- events_* matches all daily sharded tables; _TABLE_SUFFIX filters which
-- shards BigQuery actually opens (cost proportional to date range, not total)
-- ~400-600 MB scan for 7 days
-- --------------------------------------------------------------------------
SELECT
  _TABLE_SUFFIX AS event_date,
  event_name,
  COUNT(*) AS event_count,
  COUNT(DISTINCT user_pseudo_id) AS unique_users
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  _TABLE_SUFFIX BETWEEN '20201101' AND '20201107'
GROUP BY event_date, event_name
ORDER BY event_date, event_count DESC;
