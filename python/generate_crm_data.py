"""
Generate synthetic CRM leads dataset for GA4 join prototype.
Dependencies: pip install faker pandas
"""
import random
from datetime import datetime, timedelta
from faker import Faker
import pandas as pd

fake = Faker()
Faker.seed(42)
random.seed(42)

NUM_ROWS = 2500

# ---------------------------------------------------------------------------
# UTM source/medium combos with weights mirroring real GA4 traffic distribution
# Each entry: (utm_source, utm_medium, weight, [campaign_names])
# ---------------------------------------------------------------------------
UTM_COMBOS = [
    ("google",                              "organic",  0.40, ["(organic)", "(not set)", "organic_blog"]),
    ("(direct)",                            "(none)",   0.25, ["(direct)", "(not set)"]),
    ("shop.googlemerchandisestore.com",     "referral", 0.10, ["merch_store_referral", "partner_link"]),
    ("<Other>",                             "referral", 0.08, ["social_share", "community_post", "partner_blog"]),
    ("google",                              "cpc",      0.10, ["brand_search_q4", "holiday_promo", "retargeting_nov"]),
    ("(data deleted)",                      "(data deleted)", 0.04, ["(data deleted)"]),
    ("newsletter",                          "email",    0.03, ["nov_digest", "black_friday_blast", "year_end_recap"]),
]

utm_sources  = [c[0] for c in UTM_COMBOS]
utm_mediums  = [c[1] for c in UTM_COMBOS]
weights      = [c[2] for c in UTM_COMBOS]
campaign_map = {(c[0], c[1]): c[3] for c in UTM_COMBOS}

# ---------------------------------------------------------------------------
# Lifecycle stage weights — realistic funnel drop-off
# ---------------------------------------------------------------------------
STAGES = ["Lead", "MQL", "SQL", "Opportunity", "Closed Won", "Closed Lost"]
STAGE_WEIGHTS = [0.35, 0.25, 0.15, 0.10, 0.08, 0.07]

# ---------------------------------------------------------------------------
# Date range: Nov 1 2020 – Jan 31 2021 (overlaps GA4 sample data)
# ---------------------------------------------------------------------------
DATE_START = datetime(2020, 11, 1)
DATE_END   = datetime(2021, 1, 31)
DATE_RANGE_DAYS = (DATE_END - DATE_START).days

# ---------------------------------------------------------------------------
# Generate rows
# ---------------------------------------------------------------------------
rows = []
for i in range(1, NUM_ROWS + 1):
    idx = random.choices(range(len(UTM_COMBOS)), weights=weights, k=1)[0]
    src, med = utm_sources[idx], utm_mediums[idx]
    campaign = random.choice(campaign_map[(src, med)])

    stage = random.choices(STAGES, weights=STAGE_WEIGHTS, k=1)[0]

    created = DATE_START + timedelta(days=random.randint(0, DATE_RANGE_DAYS))

    deal_value = None
    if stage in ("Opportunity", "Closed Won", "Closed Lost"):
        deal_value = round(random.uniform(50, 5000), 2)

    close_date = None
    if stage in ("Closed Won", "Closed Lost"):
        close_date = created + timedelta(days=random.randint(7, 90))

    rows.append({
        "lead_id":         f"LEAD-{i:05d}",
        "created_date":    created.strftime("%Y-%m-%d"),
        "contact_name":    fake.name(),
        "contact_email":   fake.email(),
        "utm_source":      src,
        "utm_medium":      med,
        "utm_campaign":    campaign,
        "lifecycle_stage": stage,
        "deal_value":      deal_value,
        "close_date":      close_date.strftime("%Y-%m-%d") if close_date else None,
    })

df = pd.DataFrame(rows)

# ---------------------------------------------------------------------------
# Save CSV
# ---------------------------------------------------------------------------
CSV_PATH = "crm_leads.csv"
df.to_csv(CSV_PATH, index=False)
print(f"[OK] Saved {len(df)} rows to {CSV_PATH}\n")

# ---------------------------------------------------------------------------
# Data quality checks
# ---------------------------------------------------------------------------
print("=" * 60)
print("LIFECYCLE STAGE DISTRIBUTION")
print("=" * 60)
stage_counts = df["lifecycle_stage"].value_counts()
stage_pct = df["lifecycle_stage"].value_counts(normalize=True).mul(100).round(1)
print(pd.DataFrame({"count": stage_counts, "pct": stage_pct}))

print("\n" + "=" * 60)
print("UTM SOURCE / MEDIUM COMBINATIONS")
print("=" * 60)
utm_counts = df.groupby(["utm_source", "utm_medium"]).size().reset_index(name="count")
utm_counts["pct"] = (utm_counts["count"] / len(df) * 100).round(1)
utm_counts = utm_counts.sort_values("count", ascending=False)
print(utm_counts.to_string(index=False))

print("\n" + "=" * 60)
print("CAMPAIGN DISTRIBUTION (top 15)")
print("=" * 60)
print(df["utm_campaign"].value_counts().head(15))

print("\n" + "=" * 60)
print("DEAL VALUE STATS (non-null only)")
print("=" * 60)
print(df["deal_value"].describe())

print(f"\nNull deal_value rows: {df['deal_value'].isna().sum()} / {len(df)}")
print(f"Null close_date rows: {df['close_date'].isna().sum()} / {len(df)}")
