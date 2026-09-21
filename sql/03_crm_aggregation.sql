-- ==========================================================================
-- 03: CRM Pipeline Aggregation by Channel
-- Source: marketlytics-prototype.marketlytics.crm_leads (2,500 synthetic rows)
-- ==========================================================================

SELECT
  LOWER(utm_source)  AS source,
  LOWER(utm_medium)  AS medium,
  COUNT(*)           AS total_leads,
  COUNTIF(lifecycle_stage = 'Closed Won')                          AS closed_won_count,
  COUNTIF(lifecycle_stage = 'Closed Lost')                         AS closed_lost_count,
  SUM(IF(lifecycle_stage = 'Closed Won', deal_value, 0))           AS closed_won_revenue,
  SAFE_DIVIDE(
    COUNTIF(lifecycle_stage = 'Closed Won'),
    COUNT(*)
  )                                                                 AS lead_to_close_rate
FROM `marketlytics-prototype.marketlytics.crm_leads`
GROUP BY source, medium
ORDER BY closed_won_revenue DESC;
