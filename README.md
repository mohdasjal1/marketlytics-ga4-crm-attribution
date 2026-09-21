# MarketLytics: GA4 + CRM Closed-Loop Attribution

A data pipeline that joins **Google Analytics 4 behavioral data** (sessions, purchases) with **CRM pipeline data** (leads, closed deals, revenue) by acquisition channel — connecting top-of-funnel activity to bottom-of-funnel business outcomes.

---

## What This Proves

Most marketing analytics stops at "which channel drove clicks." This project goes further, answering questions like:

> *"Google CPC drove X sessions but only $Y in actual closed revenue, while organic drove fewer sessions but a higher close rate."*

This is **closed-loop attribution**: tying marketing engagement metrics to real, CRM-verified revenue outcomes, rather than relying on click/session volume as a proxy for business impact.

---

## Architecture

```
┌─────────────────────────────┐
│  GA4 Public Sample Dataset  │
│  (BigQuery, event-level)    │
└──────────┬──────────────────┘
           │  Wildcard tables (events_*)
           │  UNNEST event_params/items
           ▼
┌─────────────────────────────┐      ┌──────────────────────────┐
│  GA4 Session Funnel CTE     │      │  Synthetic CRM Dataset   │
│  (sessions, purchases       │      │  (Python/Faker → BigQuery)│
│   by source/medium)         │      │  2,500 leads with UTM,   │
│                             │      │  lifecycle stage, revenue │
└──────────┬──────────────────┘      └──────────┬───────────────┘
           │                                     │
           │         JOIN on source/medium        │
           └──────────────┬──────────────────────┘
                          ▼
              ┌───────────────────────┐
              │ Channel Attribution   │
              │ View (BigQuery)       │
              │                       │
              │ Sessions + Purchases  │
              │ + Leads + Revenue     │
              │ + Revenue/Session     │
              └───────────┬───────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │  Looker Studio        │
              │  Dashboard            │
              └───────────────────────┘
```

**Live Dashboard:** [[LOOKER STUDIO LINK HERE]](https://datastudio.google.com/reporting/fbfab9d7-1f77-46fe-b274-6fa81f793256)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Data Source | [GA4 BigQuery Export](https://developers.google.com/analytics/bigquery) (public obfuscated sample) |
| Warehouse | Google BigQuery (Sandbox / free tier, no billing) |
| Synthetic Data | Python 3, Faker, pandas |
| Attribution SQL | BigQuery Standard SQL (CTEs, UNNEST, wildcard tables) |
| Visualization | Looker Studio (formerly Google Data Studio) |

---

## Project Structure

```
├── README.md
├── sql/
│   ├── 01_ga4_schema_exploration.sql   # Schema inspection, UNNEST patterns, wildcard tables
│   ├── 02_ga4_session_funnel.sql       # Session-level funnel by traffic source
│   ├── 03_crm_aggregation.sql          # CRM pipeline metrics by channel
│   └── 04_channel_attribution_view.sql # Closed-loop join: GA4 + CRM
├── python/
│   └── generate_crm_data.py           # Synthetic CRM dataset generator
└── data/
    └── crm_leads_sample.csv           # First 50 rows (sample only)
```

---

## How AI Was Used

This project was built with **Claude Opus 4.7 via Antigravity IDE** as a pair-programming assistant. Direction and review were mine at every step; AI accelerated the SQL/Python generation.

| Step | Direction & Review | AI Execution |
|---|---|---|
| **GA4 schema exploration** | Identified the dataset, confirmed access with a test query, requested explanation of the nested RECORD/STRUCT schema. | Generated INFORMATION_SCHEMA queries, UNNEST examples, and explained dot-access STRUCTs vs. arrays requiring UNNEST. |
| **Funnel query** | Specified funnel stages and grouping dimensions, reviewed output to confirm COUNTIF logic was correct. | Wrote the conditional aggregation query with wildcard table syntax. |
| **Synthetic CRM data** | Provided the real GA4 traffic_source values the UTM fields needed to match, reviewed distribution output for realism. | Built the Faker script with weighted sampling, lifecycle funnel drop-off, and null-handling for deal_value/close_date. |
| **Attribution join** | Defined the closed-loop concept, specified LEFT JOIN direction and LOWER() cleaning, reviewed join keys and COALESCE logic. | Wrote the CTE-based join query and flagged the caveat around synthetic vs. causal attribution. |
| **Dashboard** | Designed the layout, chose chart types, configured Looker Studio manually. | N/A — built directly in Looker Studio. |

Every architectural decision — what to join, how to model the funnel, what the output should prove — was directed and reviewed manually before running.

---

## Known Limitations & Caveats

- **Synthetic CRM data:** The CRM dataset's UTM distribution statistically mirrors GA4's real traffic mix, but is not causally linked to actual GA4 sessions. The join is directionally realistic, not individually traced.
- **Production upgrade path:** A real system would close this loop by passing a `client_id` or `GCLID` from GA4 through to the CRM via hidden form fields, enabling true 1:1 user-level attribution.
- **Date range:** Queries use a 7-day window (Nov 1–7, 2020) from the public GA4 sample. The full dataset covers Nov 2020 – Jan 2021.
- **Free tier:** All queries run within BigQuery's free-tier quota (1 TB/month scanned). Each query scans ~50–600 MB.

---

## Quick Start

```bash
# 1. Generate CRM data
pip install faker pandas
python python/generate_crm_data.py

# 2. Upload crm_leads.csv to BigQuery (console UI or gcloud CLI)
# 3. Run SQL files in order in BigQuery console
# 4. Connect BigQuery views to Looker Studio
```
