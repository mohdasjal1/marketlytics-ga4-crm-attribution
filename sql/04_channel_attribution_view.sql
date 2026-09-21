-- ==========================================================================
-- 04: Closed-Loop Channel Attribution View
-- Joins GA4 behavioral data (sessions, purchases) with CRM pipeline data
-- (leads, closed deals, revenue) by acquisition channel.
--
-- NOTE: This join is directionally realistic for a prototype. The synthetic
-- CRM data's UTM distribution statistically mirrors GA4's real traffic mix,
-- but is not causally traced at the individual user level. In production,
-- you'd close this loop by passing client_id/GCLID from GA4 through to the
-- CRM via hidden form fields for true 1:1 attribution.
--
-- ~400-600 MB scan (GA4 side)
-- ==========================================================================

CREATE OR REPLACE VIEW `marketlytics-prototype.marketlytics.channel_attribution` AS

WITH crm AS (
  SELECT
    LOWER(utm_source)  AS source,
    LOWER(utm_medium)  AS medium,
    COUNT(*)           AS total_leads,
    COUNTIF(lifecycle_stage = 'Closed Won')                AS closed_won_count,
    COUNTIF(lifecycle_stage = 'Closed Lost')                AS closed_lost_count,
    SUM(IF(lifecycle_stage = 'Closed Won', deal_value, 0)) AS closed_won_revenue,
    SAFE_DIVIDE(
      COUNTIF(lifecycle_stage = 'Closed Won'),
      COUNT(*)
    )                                                       AS lead_to_close_rate
  FROM `marketlytics-prototype.marketlytics.crm_leads`
  GROUP BY source, medium
),

ga4 AS (
  SELECT
    LOWER(traffic_source.source) AS source,
    LOWER(traffic_source.medium) AS medium,
    COUNT(DISTINCT IF(event_name = 'session_start', user_pseudo_id, NULL)) AS sessions,
    COUNT(DISTINCT IF(event_name = 'purchase',       user_pseudo_id, NULL)) AS purchases
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201107'
    AND event_name IN ('session_start', 'purchase')
  GROUP BY source, medium
)

-- LEFT JOIN from CRM so no CRM channels are dropped, even if GA4
-- has zero sessions for that source/medium (e.g. newsletter/email)
SELECT
  crm.source,
  crm.medium,
  -- GA4 engagement metrics
  COALESCE(ga4.sessions, 0)          AS ga4_sessions,
  COALESCE(ga4.purchases, 0)         AS ga4_purchases,
  -- CRM pipeline metrics
  crm.total_leads,
  crm.closed_won_count,
  crm.closed_lost_count,
  crm.closed_won_revenue,
  crm.lead_to_close_rate,
  -- Combined closed-loop metrics
  SAFE_DIVIDE(crm.closed_won_revenue, COALESCE(ga4.sessions, 0))
    AS revenue_per_session,
  SAFE_DIVIDE(COALESCE(ga4.purchases, 0), COALESCE(ga4.sessions, 0))
    AS ga4_purchase_rate
FROM crm
LEFT JOIN ga4
  ON crm.source = ga4.source
  AND crm.medium = ga4.medium
ORDER BY crm.closed_won_revenue DESC;
