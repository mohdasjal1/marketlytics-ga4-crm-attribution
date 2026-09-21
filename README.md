# MarketLytics: GA4 + CRM Closed-Loop Attribution Prototype

> **Built overnight** as a fast data engineering prototype for a Data Solutions Associate interview.  
> This is a conceptual validation of GA4/CRM/BigQuery integration — not a polished production system.

---

## What This Proves

Most marketing analytics stops at "which channel drove clicks." This prototype goes further — joining **Google Analytics 4 behavioral data** (sessions, purchases) with **CRM pipeline data** (leads, closed deals, revenue) by acquisition channel to answer:

> *"Google CPC drove X sessions but only $Y in actual closed revenue, while organic drove fewer sessions but a higher close rate."*

This is **closed-loop attribution**: connecting top-of-funnel activity to bottom-of-funnel business outcomes.

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

**Live Dashboard:** [LOOKER STUDIO LINK HERE]

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

This project was built with **Claude Opus 4.7 via Antigravity IDE** as a pair-programming assistant. Here's specifically how AI was used at each step, and what I directed/reviewed:

| Step | My Role (Direction & Review) | AI Role (Execution) |
|---|---|---|
| **GA4 schema exploration** | I identified the dataset and confirmed access with a test query. Asked AI to explain the nested RECORD/STRUCT schema. | Generated INFORMATION_SCHEMA queries, UNNEST examples, and explained the difference between dot-access STRUCTs vs arrays requiring UNNEST. |
| **Funnel query** | I specified the funnel stages and grouping dimensions. Reviewed output to confirm COUNTIF logic was correct. | Wrote the conditional aggregation query with wildcard table syntax. |
| **Synthetic CRM data** | I provided the exact GA4 traffic_source values the UTM fields needed to match. Reviewed the distribution outputs to verify realism. | Built the Faker script with weighted sampling, lifecycle funnel drop-off, and null-handling for deal_value/close_date. |
| **Attribution join** | I defined the "closed-loop" concept and specified LEFT JOIN direction + LOWER() cleaning. Reviewed the join keys and COALESCE logic. | Wrote the CTE-based join query and suggested the interview caveat about synthetic vs. causal attribution. |
| **Dashboard** | I designed the layout, chose chart types, and configured Looker Studio manually. | N/A — dashboard was built entirely by me in Looker Studio. |

**Key point:** AI accelerated SQL/Python generation, but every architectural decision (what to join, how to model the funnel, what the output should prove) was mine. I reviewed all output before running it.

---

## Known Limitations & Caveats

- **Synthetic CRM data:** The CRM dataset's UTM distribution statistically mirrors GA4's real traffic mix, but is not causally linked to actual GA4 sessions. The join is directionally realistic, not individually traced.
- **Production upgrade path:** In a real system, you'd close this loop by passing a `client_id` or `GCLID` from GA4 through to the CRM via hidden form fields, enabling true 1:1 user-level attribution.
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

---

*Built September 2026 · Karachi, Pakistan*
