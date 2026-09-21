-- ==========================================================================
-- 02: GA4 Session-Level Funnel by Traffic Source
-- Funnel: session_start → view_item → begin_checkout → purchase
-- ~400-600 MB scan for 7 days
-- ==========================================================================

SELECT
  traffic_source.source,
  traffic_source.medium,
  COUNT(DISTINCT user_pseudo_id)
    AS total_users,
  COUNT(DISTINCT IF(event_name = 'session_start',  user_pseudo_id, NULL))
    AS sessions,
  COUNT(DISTINCT IF(event_name = 'view_item',       user_pseudo_id, NULL))
    AS viewed_item,
  COUNT(DISTINCT IF(event_name = 'begin_checkout',   user_pseudo_id, NULL))
    AS began_checkout,
  COUNT(DISTINCT IF(event_name = 'purchase',         user_pseudo_id, NULL))
    AS purchased,
  -- Conversion rate: session → purchase
  SAFE_DIVIDE(
    COUNT(DISTINCT IF(event_name = 'purchase', user_pseudo_id, NULL)),
    COUNT(DISTINCT IF(event_name = 'session_start', user_pseudo_id, NULL))
  ) AS purchase_rate
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE
  _TABLE_SUFFIX BETWEEN '20201101' AND '20201107'
  AND event_name IN ('session_start', 'view_item', 'begin_checkout', 'purchase')
GROUP BY
  traffic_source.source,
  traffic_source.medium
HAVING sessions > 0
ORDER BY sessions DESC;
