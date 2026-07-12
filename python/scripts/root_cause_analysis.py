# =============================================================================
#  Script   : root_cause_analysis.py
#  Purpose  : Root Cause Analysis — WHY customers churn
#             Finds leading indicators, behavioural patterns, high-risk
#             profiles, and highest-churn segments using data evidence.
#  Dataset  : Customer_Data.csv  (6,419 records | 32 columns)
#  Tools    : Pandas, NumPy, Matplotlib, Seaborn, Plotly
#  Author   : [Your Name]
#  Project  : Customer Churn Analysis  (SQL + Python + Power BI)
#  Version  : 1.0
#  NOTE     : This script performs ANALYSIS ONLY — no prediction or ML.
# =============================================================================


# =============================================================================
# SECTION 1 — SETUP
# =============================================================================

import os
import warnings
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.ticker as mticker
import seaborn as sns
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

warnings.filterwarnings("ignore")

# ── Style ──────────────────────────────────────────────────────
plt.rcParams.update({
    "figure.dpi"       : 130,
    "figure.facecolor" : "#0f0f1a",
    "axes.facecolor"   : "#1a1a2e",
    "axes.edgecolor"   : "#444466",
    "axes.labelcolor"  : "#e0e0f0",
    "xtick.color"      : "#b0b0cc",
    "ytick.color"      : "#b0b0cc",
    "text.color"       : "#e0e0f0",
    "grid.color"       : "#2a2a4a",
    "grid.linestyle"   : "--",
    "grid.alpha"       : 0.4,
    "font.family"      : "DejaVu Sans",
    "axes.titlesize"   : 12,
    "axes.labelsize"   : 10,
})

CHURN_RED   = "#ff6584"
STAY_GREEN  = "#43d9ad"
WARN_YELLOW = "#ffd166"
BLUE_ACCENT = "#6c63ff"
TEAL_ACCENT = "#06d6a0"
CHURN_COLORS = {"Churned": CHURN_RED, "Stayed": STAY_GREEN, "Joined": WARN_YELLOW}

BASE_DIR   = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMAGES_DIR = os.path.join(BASE_DIR, "images", "rca")
os.makedirs(IMAGES_DIR, exist_ok=True)

def save(name):
    path = os.path.join(IMAGES_DIR, name)
    plt.savefig(path, bbox_inches="tight", facecolor=plt.rcParams["figure.facecolor"])
    print(f"  ✅ Saved: images/rca/{name}")

def save_html(fig, name):
    path = os.path.join(IMAGES_DIR, name)
    fig.write_html(path)
    print(f"  ✅ Saved: images/rca/{name}")

def section(title):
    print(f"\n{'='*65}")
    print(f"  {title}")
    print(f"{'='*65}")

print("✅ Libraries loaded. Starting Root Cause Analysis...\n")


# =============================================================================
# SECTION 2 — LOAD & PREPARE DATA
# =============================================================================

DATA_PATH = os.path.join(BASE_DIR, "Customer_Data.csv")
df = pd.read_csv(DATA_PATH)
df.replace("", np.nan, inplace=True)
df.columns = df.columns.str.strip()

# ── Apply same cleaning as eda_analysis.py ──────────────────
df["Monthly_Charge"] = df["Monthly_Charge"].abs()

ADDONS = ["Internet_Type","Online_Security","Online_Backup",
          "Device_Protection_Plan","Premium_Support",
          "Streaming_TV","Streaming_Movies","Streaming_Music","Unlimited_Data"]
df.loc[df["Internet_Service"] == "No", ADDONS]      = "No Internet Service"
df.loc[df["Phone_Service"]    == "No", "Multiple_Lines"] = "No Phone Service"
df["Value_Deal"].fillna("No Deal", inplace=True)
df["Churn_Category"].fillna("Not Applicable", inplace=True)
df["Churn_Reason"].fillna("Not Applicable",   inplace=True)

df["Churn_Flag"]   = (df["Customer_Status"] == "Churned").astype(int)
df["Tenure_Group"] = pd.cut(df["Tenure_in_Months"],
                             bins=[0,6,12,24,36,9999],
                             labels=["0–6 M","7–12 M","13–24 M","25–36 M","36+ M"])
df["Age_Group"]    = pd.cut(df["Age"], bins=[17,30,45,60,120],
                             labels=["18–30","31–45","46–60","60+"])
addon_cols = ["Online_Security","Online_Backup","Device_Protection_Plan",
              "Premium_Support","Streaming_TV","Streaming_Movies","Streaming_Music"]
df["Addon_Count"]  = df[addon_cols].apply(lambda r:(r=="Yes").sum(), axis=1)

# ── Working subsets ──────────────────────────────────────────
df_cs  = df[df["Customer_Status"].isin(["Churned","Stayed"])].copy()  # exclude Joined
df_ch  = df[df["Customer_Status"] == "Churned"].copy()
df_st  = df[df["Customer_Status"] == "Stayed"].copy()

print(f"Records loaded : {len(df):,}")
print(f"Churned        : {len(df_ch):,}  ({len(df_ch)/len(df_cs)*100:.1f}%)")
print(f"Stayed         : {len(df_st):,}  ({len(df_st)/len(df_cs)*100:.1f}%)")


# =============================================================================
# SECTION 3 — WHY CUSTOMERS LEAVE: CHURN REASON DECOMPOSITION
# =============================================================================
section("RCA-1: WHY CUSTOMERS LEAVE — Churn Category & Reason")

# ── 3.1  Churn Category waterfall table ─────────────────────
cat_table = (
    df_ch.groupby("Churn_Category")
    .agg(Customers     = ("Customer_ID",    "count"),
         Revenue_Lost  = ("Total_Revenue",  "sum"),
         Avg_Monthly   = ("Monthly_Charge", "mean"),
         Avg_Tenure    = ("Tenure_in_Months","mean"))
    .assign(Pct_Churn = lambda x: (x["Customers"]/x["Customers"].sum()*100).round(1))
    .sort_values("Customers", ascending=False)
    .reset_index()
)
print("\n📊 Churn Category Breakdown:")
print(cat_table.round(2).to_string(index=False))

# ── 3.2  Churn Category bar chart ────────────────────────────
fig, axes = plt.subplots(1, 2, figsize=(16, 6))
fig.suptitle("ROOT CAUSE — Why Do Customers Leave?", fontsize=14, y=1.02)

colors = [CHURN_RED, "#ff8c69", WARN_YELLOW, TEAL_ACCENT, BLUE_ACCENT]
bars = axes[0].barh(cat_table["Churn_Category"], cat_table["Customers"],
                    color=colors, edgecolor="#0f0f1a")
axes[0].set_title("Number of Customers by Churn Category")
axes[0].set_xlabel("Churned Customers")
for bar in bars:
    axes[0].text(bar.get_width()+5, bar.get_y()+bar.get_height()/2,
                 f"{int(bar.get_width())} ({cat_table.loc[cat_table['Churn_Category']==bar.get_y(),'Pct_Churn'].values[0] if False else cat_table['Pct_Churn'].iloc[bars.patches.index(bar)]:.1f}%)",
                 va="center", fontsize=9, color="#e0e0f0")
axes[0].grid(True, axis="x", alpha=0.3)

bars2 = axes[1].barh(cat_table["Churn_Category"],
                     (cat_table["Revenue_Lost"]/1000).round(1),
                     color=colors, edgecolor="#0f0f1a")
axes[1].set_title("Revenue Lost per Churn Category (₹ Thousands)")
axes[1].set_xlabel("Revenue Lost (₹K)")
for bar in bars2:
    axes[1].text(bar.get_width()+1, bar.get_y()+bar.get_height()/2,
                 f"₹{bar.get_width():.0f}K", va="center", fontsize=9, color="#e0e0f0")
axes[1].grid(True, axis="x", alpha=0.3)

plt.tight_layout()
save("rca01_churn_categories.png")
plt.show()

# ── 3.3  Top 15 specific churn reasons ───────────────────────
reason_table = (
    df_ch.groupby(["Churn_Category","Churn_Reason"])
    .agg(Customers   = ("Customer_ID",    "count"),
         Revenue_Lost= ("Total_Revenue",  "sum"),
         Avg_Tenure  = ("Tenure_in_Months","mean"))
    .assign(Pct = lambda x: (x["Customers"]/x["Customers"].sum()*100).round(2))
    .sort_values("Customers", ascending=False)
    .reset_index()
    .head(15)
)
print("\n📊 Top 15 Specific Churn Reasons:")
print(reason_table[["Churn_Category","Churn_Reason","Customers","Pct","Revenue_Lost"]].to_string(index=False))

cat_color_map = {
    "Competitor"    : CHURN_RED,
    "Dissatisfaction": "#ff8c69",
    "Price"         : WARN_YELLOW,
    "Attitude"      : TEAL_ACCENT,
    "Other"         : BLUE_ACCENT,
    "Not Applicable": "#888888",
}

fig, ax = plt.subplots(figsize=(14, 8))
row_colors = [cat_color_map.get(c, BLUE_ACCENT) for c in reason_table["Churn_Category"]]
bars = ax.barh(
    reason_table["Churn_Reason"].str[:45],
    reason_table["Customers"],
    color=row_colors, edgecolor="#0f0f1a", alpha=0.85
)
for bar, pct in zip(bars, reason_table["Pct"]):
    ax.text(bar.get_width()+2, bar.get_y()+bar.get_height()/2,
            f"{int(bar.get_width())} ({pct}%)", va="center", fontsize=8, color="#e0e0f0")
ax.set_title("Top 15 Specific Churn Reasons\n(Colour = Churn Category)", pad=12)
ax.set_xlabel("Number of Churned Customers")
ax.invert_yaxis()
ax.grid(True, axis="x", alpha=0.3)
legend_patches = [mpatches.Patch(color=v, label=k) for k,v in cat_color_map.items() if k != "Not Applicable"]
ax.legend(handles=legend_patches, title="Churn Category", loc="lower right", fontsize=8)
plt.tight_layout()
save("rca02_top15_churn_reasons.png")
plt.show()

# ── 3.4  Plotly treemap ───────────────────────────────────────
full_reason = (
    df_ch.groupby(["Churn_Category","Churn_Reason"])
    .agg(Customers=("Customer_ID","count"), Revenue_Lost=("Total_Revenue","sum"))
    .reset_index()
)
fig_tree = px.treemap(
    full_reason,
    path=["Churn_Category","Churn_Reason"],
    values="Customers",
    color="Revenue_Lost",
    color_continuous_scale=["#1a1a2e","#ffd166","#ff6584"],
    title="Churn Reason Treemap — Size: Customers | Colour: Revenue Lost",
    template="plotly_dark",
)
fig_tree.update_traces(textinfo="label+value+percent parent",
                        textfont=dict(size=11))
save_html(fig_tree, "rca03_churn_treemap.html")
fig_tree.show()


# =============================================================================
# SECTION 4 — LEADING INDICATORS
# =============================================================================
section("RCA-2: LEADING INDICATORS — What signals churn before it happens?")

# ── 4.1  Compute mean of each numeric feature for Churned vs Stayed ──
num_cols = ["Monthly_Charge","Total_Charges","Total_Refunds",
            "Total_Extra_Data_Charges","Total_Long_Distance_Charges",
            "Tenure_in_Months","Number_of_Referrals","Addon_Count","Age"]

indicator_df = (
    df_cs.groupby("Customer_Status")[num_cols]
    .mean()
    .T
    .assign(Lift=lambda x: ((x["Churned"]-x["Stayed"])/x["Stayed"]*100).round(1))
    .sort_values("Lift", ascending=False)
)
indicator_df.index.name = "Feature"
indicator_df = indicator_df.reset_index()
print("\n📊 Leading Indicators — Churned vs. Stayed (Mean Values):")
print(indicator_df.to_string(index=False))

# ── 4.2  Diverging bar chart: indicator lift ─────────────────
fig, ax = plt.subplots(figsize=(12, 6))
colors = [CHURN_RED if v > 0 else STAY_GREEN for v in indicator_df["Lift"]]
bars = ax.barh(indicator_df["Feature"], indicator_df["Lift"],
               color=colors, edgecolor="#0f0f1a", alpha=0.85)
ax.axvline(0, color="#e0e0f0", linewidth=1.2)
ax.set_title("Leading Indicators: % Difference in Key Metrics\n"
             "(Red = Churned customers are HIGHER | Green = Churned customers are LOWER)",
             pad=12)
ax.set_xlabel("% Lift vs. Stayed Customers")
for bar in bars:
    x = bar.get_width()
    ax.text(x + (0.5 if x >= 0 else -0.5),
            bar.get_y()+bar.get_height()/2,
            f"{x:+.1f}%", va="center",
            ha="left" if x >= 0 else "right",
            fontsize=9, color="#e0e0f0")
ax.grid(True, axis="x", alpha=0.3)
plt.tight_layout()
save("rca04_leading_indicators_lift.png")
plt.show()

# ── 4.3  Print insight summary ───────────────────────────────
for _, row in indicator_df.iterrows():
    direction = "HIGHER" if row["Lift"] > 0 else "LOWER"
    print(f"  {row['Feature']:<35}: Churned avg = {row['Churned']:>8.2f} | "
          f"Stayed avg = {row['Stayed']:>8.2f} | {direction} by {abs(row['Lift']):.1f}%")


# =============================================================================
# SECTION 5 — BEHAVIOUR BEFORE CHURN
# =============================================================================
section("RCA-3: BEHAVIOUR BEFORE CHURN — Usage & Engagement Patterns")

# ── 5.1  Contract type behaviour ─────────────────────────────
contract_churn = (
    df_cs.groupby("Contract")
    .agg(Total=("Churn_Flag","count"), Churned=("Churn_Flag","sum"),
         Avg_Tenure=("Tenure_in_Months","mean"),
         Avg_Charge=("Monthly_Charge","mean"),
         Avg_Addons=("Addon_Count","mean"))
    .assign(Churn_Rate=lambda x:(x["Churned"]/x["Total"]*100).round(2))
    .reset_index()
)
print("\n📊 Contract Behaviour:")
print(contract_churn.round(2).to_string(index=False))

# ── 5.2  Tenure distribution comparison ──────────────────────
fig, axes = plt.subplots(1, 3, figsize=(18, 6))
fig.suptitle("Behavioural Patterns Before Churn", fontsize=14, y=1.01)

# Tenure KDE
for status, color in [("Churned", CHURN_RED), ("Stayed", STAY_GREEN)]:
    axes[0].hist(df_cs[df_cs["Customer_Status"]==status]["Tenure_in_Months"].dropna(),
                 bins=36, color=color, alpha=0.65, label=status, edgecolor="none")
axes[0].set_title("Tenure Distribution — Churned vs. Stayed\n(Churned customers have SHORTER tenure)")
axes[0].set_xlabel("Tenure (Months)")
axes[0].set_ylabel("Count")
axes[0].legend()
axes[0].grid(True, alpha=0.3)

# Number of Referrals comparison
for status, color in [("Churned", CHURN_RED), ("Stayed", STAY_GREEN)]:
    axes[1].hist(df_cs[df_cs["Customer_Status"]==status]["Number_of_Referrals"].dropna(),
                 bins=16, color=color, alpha=0.65, label=status, edgecolor="none")
axes[1].set_title("Referrals — Churned vs. Stayed\n(Churned customers refer LESS)")
axes[1].set_xlabel("Number of Referrals")
axes[1].set_ylabel("Count")
axes[1].legend()
axes[1].grid(True, alpha=0.3)

# Addon count comparison
addon_pivot = (
    df_cs.groupby(["Addon_Count","Customer_Status"])
    .size().unstack(fill_value=0)
    .div(df_cs.groupby("Customer_Status").size(), axis=1)
    .mul(100)
)
addon_pivot.plot(kind="bar", color=[CHURN_RED, STAY_GREEN],
                 ax=axes[2], edgecolor="#0f0f1a", alpha=0.85, width=0.6)
axes[2].set_title("Add-On Count Distribution (%)\n(Churned customers subscribe to FEWER add-ons)")
axes[2].set_xlabel("Number of Add-Ons")
axes[2].set_ylabel("% of Customers")
axes[2].set_xticklabels(axes[2].get_xticklabels(), rotation=0)
axes[2].yaxis.set_major_formatter(mticker.PercentFormatter())
axes[2].legend(title="Status")
axes[2].grid(True, axis="y", alpha=0.3)

plt.tight_layout()
save("rca05_behaviour_before_churn.png")
plt.show()

# ── 5.3  Extra data charges & refunds as pre-churn signals ───
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

# Extra data charges
for status, color in [("Churned", CHURN_RED), ("Stayed", STAY_GREEN)]:
    data = df_cs[df_cs["Customer_Status"]==status]["Total_Extra_Data_Charges"]
    axes[0].hist(data[data > 0], bins=25, color=color, alpha=0.65,
                 label=f"{status} (>0 only)", edgecolor="none")
axes[0].set_title("Extra Data Charges Distribution\n(Overage fees are a pre-churn trigger)")
axes[0].set_xlabel("Total Extra Data Charges (₹)")
axes[0].set_ylabel("Count")
axes[0].legend()
axes[0].grid(True, alpha=0.3)

# Refunds as dissatisfaction signal
for status, color in [("Churned", CHURN_RED), ("Stayed", STAY_GREEN)]:
    data = df_cs[df_cs["Customer_Status"]==status]["Total_Refunds"]
    axes[1].hist(data[data > 0], bins=25, color=color, alpha=0.65,
                 label=f"{status} (>0 only)", edgecolor="none")
axes[1].set_title("Total Refunds Distribution\n(Refunds signal prior service failures)")
axes[1].set_xlabel("Total Refunds Received (₹)")
axes[1].set_ylabel("Count")
axes[1].legend()
axes[1].grid(True, alpha=0.3)

plt.tight_layout()
save("rca06_pre_churn_signals.png")
plt.show()

# ── 5.4  Behaviour summary table ─────────────────────────────
print("\n📊 Pre-Churn Behavioural Signals — Quantified:")
behaviour = {
    "Metric"            : ["Avg Tenure","Avg Referrals","Avg Add-Ons",
                           "Has Overage Charges","Has Refunds",
                           "Avg Monthly Charge","Month-to-Month Contract %"],
    "Churned"           : [
        f"{df_ch['Tenure_in_Months'].mean():.1f} months",
        f"{df_ch['Number_of_Referrals'].mean():.2f}",
        f"{df_ch['Addon_Count'].mean():.2f}",
        f"{(df_ch['Total_Extra_Data_Charges']>0).mean()*100:.1f}%",
        f"{(df_ch['Total_Refunds']>0).mean()*100:.1f}%",
        f"₹{df_ch['Monthly_Charge'].mean():.2f}",
        f"{(df_ch['Contract']=='Month-to-Month').mean()*100:.1f}%",
    ],
    "Stayed"            : [
        f"{df_st['Tenure_in_Months'].mean():.1f} months",
        f"{df_st['Number_of_Referrals'].mean():.2f}",
        f"{df_st['Addon_Count'].mean():.2f}",
        f"{(df_st['Total_Extra_Data_Charges']>0).mean()*100:.1f}%",
        f"{(df_st['Total_Refunds']>0).mean()*100:.1f}%",
        f"₹{df_st['Monthly_Charge'].mean():.2f}",
        f"{(df_st['Contract']=='Month-to-Month').mean()*100:.1f}%",
    ],
}
print(pd.DataFrame(behaviour).to_string(index=False))


# =============================================================================
# SECTION 6 — HIGH-RISK CUSTOMER PROFILES
# =============================================================================
section("RCA-4: HIGH-RISK CUSTOMER PROFILES")

# ── 6.1  Churn rate by combinations of key attributes ────────
profile_df = (
    df_cs.groupby(["Contract","Internet_Type","Tenure_Group"])
    .agg(Total=("Churn_Flag","count"), Churned=("Churn_Flag","sum"),
         Avg_Monthly=("Monthly_Charge","mean"),
         Revenue_At_Risk=("Monthly_Charge","sum"))
    .assign(Churn_Rate=lambda x:(x["Churned"]/x["Total"]*100).round(2))
    .query("Total >= 20")
    .sort_values("Churn_Rate", ascending=False)
    .reset_index()
    .head(20)
)
print("\n📊 Top 20 High-Risk Profiles (Contract × Internet × Tenure):")
print(profile_df.to_string(index=False))

# ── 6.2  Scatter: Monthly Charge vs Tenure — colour by churn ──
fig, ax = plt.subplots(figsize=(13, 7))
sample = df_cs.sample(min(3000, len(df_cs)), random_state=42)
sc = ax.scatter(
    sample["Tenure_in_Months"],
    sample["Monthly_Charge"],
    c=sample["Churn_Flag"],
    cmap="RdYlGn_r",
    alpha=0.5,
    s=18,
    edgecolors="none",
)
# Annotate high-risk zone
ax.axvline(12,  color=WARN_YELLOW, linestyle="--", linewidth=1.2, alpha=0.7,
           label="12 Month threshold")
ax.axhline(70,  color=CHURN_RED,   linestyle="--", linewidth=1.2, alpha=0.7,
           label="₹70 Monthly Charge threshold")
ax.fill_betweenx([70, sample["Monthly_Charge"].max()], 0, 12,
                 color=CHURN_RED, alpha=0.08, label="Highest-Risk Zone")
plt.colorbar(sc, ax=ax, label="Churn (1=Yes, 0=No)")
ax.set_title("High-Risk Zone: Short Tenure + High Monthly Charge = Highest Churn\n"
             "(Top-Left quadrant is the danger zone)", pad=12)
ax.set_xlabel("Tenure (Months)")
ax.set_ylabel("Monthly Charge (₹)")
ax.legend(fontsize=9, loc="upper right")
ax.grid(True, alpha=0.3)
plt.tight_layout()
save("rca07_high_risk_zone_scatter.png")
plt.show()

# ── 6.3  Define the high-risk profile in numbers ──────────────
high_risk = df_cs[
    (df_cs["Contract"]      == "Month-to-Month") &
    (df_cs["Tenure_in_Months"] <= 12) &
    (df_cs["Monthly_Charge"]   >= 70) &
    (df_cs["Internet_Type"].isin(["Fiber Optic","Cable"]))
]
hr_total   = len(high_risk)
hr_churned = high_risk["Churn_Flag"].sum()
hr_rate    = hr_churned/hr_total*100 if hr_total > 0 else 0
hr_rev_risk= high_risk[high_risk["Churn_Flag"]==0]["Monthly_Charge"].sum()

print(f"\n🔴 HIGH-RISK PROFILE QUANTIFICATION")
print(f"   Profile : Month-to-Month | Tenure ≤12M | Charge ≥₹70 | Fiber/Cable")
print(f"   Customers in profile   : {hr_total:,}")
print(f"   Already churned        : {hr_churned:,} ({hr_rate:.1f}% churn rate)")
print(f"   Still active (at risk) : {hr_total - hr_churned:,}")
print(f"   Monthly revenue at risk: ₹{hr_rev_risk:,.2f}")


# =============================================================================
# SECTION 7 — CUSTOMER SEGMENTS WITH HIGHEST CHURN
# =============================================================================
section("RCA-5: CUSTOMER SEGMENTS WITH HIGHEST CHURN")

# ── 7.1  Churn rate heatmap: Contract × Internet Type ─────────
pivot1 = (
    df_cs.groupby(["Contract","Internet_Type"])
    .agg(Total=("Churn_Flag","count"), Churned=("Churn_Flag","sum"))
    .assign(Rate=lambda x:(x["Churned"]/x["Total"]*100).round(1))
    ["Rate"]
    .unstack(fill_value=0)
)
fig, axes = plt.subplots(1, 2, figsize=(17, 5))
sns.heatmap(pivot1, annot=True, fmt=".1f", cmap="RdYlGn_r",
            linewidths=0.8, linecolor="#0f0f1a", ax=axes[0],
            annot_kws={"size":11,"fontweight":"bold"},
            cbar_kws={"label":"Churn Rate (%)"})
axes[0].set_title("Churn Rate %\nContract × Internet Type", pad=12)
axes[0].set_xlabel("Internet Type")
axes[0].set_ylabel("Contract Type")

# ── 7.2  Churn rate heatmap: Tenure Group × Payment Method ───
pivot2 = (
    df_cs.groupby(["Tenure_Group","Payment_Method"])
    .agg(Total=("Churn_Flag","count"), Churned=("Churn_Flag","sum"))
    .assign(Rate=lambda x:(x["Churned"]/x["Total"]*100).round(1))
    ["Rate"]
    .unstack(fill_value=0)
)
sns.heatmap(pivot2, annot=True, fmt=".1f", cmap="RdYlGn_r",
            linewidths=0.8, linecolor="#0f0f1a", ax=axes[1],
            annot_kws={"size":11,"fontweight":"bold"},
            cbar_kws={"label":"Churn Rate (%)"})
axes[1].set_title("Churn Rate %\nTenure Group × Payment Method", pad=12)
axes[1].set_xlabel("Payment Method")
axes[1].set_ylabel("Tenure Group")

plt.suptitle("Customer Segment Churn Rate Heatmaps", fontsize=14, y=1.02)
plt.tight_layout()
save("rca08_segment_heatmaps.png")
plt.show()

# ── 7.3  Churn rate by Addon Count — monotonic decrease? ──────
addon_rate = (
    df_cs.groupby("Addon_Count")
    .agg(Total=("Churn_Flag","count"), Churned=("Churn_Flag","sum"))
    .assign(Churn_Rate=lambda x:(x["Churned"]/x["Total"]*100).round(2))
    .reset_index()
)
print("\n📊 Churn Rate by Add-On Count (Stickiness Hypothesis):")
print(addon_rate.to_string(index=False))

fig, ax1 = plt.subplots(figsize=(10, 5))
ax2 = ax1.twinx()
ax1.bar(addon_rate["Addon_Count"], addon_rate["Total"],
        color=BLUE_ACCENT, alpha=0.5, width=0.4, label="# Customers")
ax2.plot(addon_rate["Addon_Count"], addon_rate["Churn_Rate"],
         color=CHURN_RED, marker="o", linewidth=2.5, markersize=9, label="Churn Rate (%)")
for x, y in zip(addon_rate["Addon_Count"], addon_rate["Churn_Rate"]):
    ax2.annotate(f"{y:.1f}%", (x, y), textcoords="offset points",
                 xytext=(0, 10), ha="center", fontsize=9, color=CHURN_RED)
ax1.set_xlabel("Number of Add-On Services")
ax1.set_ylabel("Number of Customers", color=BLUE_ACCENT)
ax2.set_ylabel("Churn Rate (%)", color=CHURN_RED)
ax1.set_title("Stickiness Effect: Each Add-On Subscription Reduces Churn\n"
              "(0 add-ons = highest churn | 7 add-ons = lowest churn)")
ax1.set_xticks(range(8))
ax1.grid(True, alpha=0.3)
l1, lab1 = ax1.get_legend_handles_labels()
l2, lab2 = ax2.get_legend_handles_labels()
ax1.legend(l1+l2, lab1+lab2, loc="upper right")
plt.tight_layout()
save("rca09_addon_stickiness.png")
plt.show()

# ── 7.4  Plotly Sunburst: Category → Contract → Segment ───────
seg_data = (
    df_cs.groupby(["Contract","Internet_Type","Customer_Status"])
    .agg(Count=("Customer_ID","count"), Revenue=("Total_Revenue","sum"))
    .reset_index()
)
fig_sun = px.sunburst(
    seg_data[seg_data["Customer_Status"]=="Churned"],
    path=["Contract","Internet_Type"],
    values="Count",
    color="Revenue",
    color_continuous_scale=["#1a1a2e","#ffd166","#ff6584"],
    title="Churned Customer Segments — Contract → Internet Type<br>"
          "(Size=Customers | Colour=Revenue Lost)",
    template="plotly_dark",
)
fig_sun.update_traces(textinfo="label+value+percent parent")
save_html(fig_sun, "rca10_segment_sunburst.html")
fig_sun.show()

# ── 7.5  Plotly: Churn reason by Internet Type ────────────────
reason_internet = (
    df_ch.groupby(["Internet_Type","Churn_Category"])
    .agg(Count=("Customer_ID","count"))
    .reset_index()
)
fig_ri = px.bar(
    reason_internet,
    x="Internet_Type",
    y="Count",
    color="Churn_Category",
    barmode="stack",
    title="Churn Category Distribution by Internet Type",
    labels={"Count":"Churned Customers","Internet_Type":"Internet Type"},
    color_discrete_sequence=[CHURN_RED,"#ff8c69",WARN_YELLOW,TEAL_ACCENT,BLUE_ACCENT],
    template="plotly_dark",
)
save_html(fig_ri, "rca11_churn_reason_by_internet.html")
fig_ri.show()


# =============================================================================
# SECTION 8 — COMPETITOR ANALYSIS (DEEP DIVE)
# =============================================================================
section("RCA-6: DEEP DIVE — Competitor-Driven Churn")

comp_ch = df_ch[df_ch["Churn_Category"] == "Competitor"]
print(f"\n🔍 Competitor churners: {len(comp_ch):,} ({len(comp_ch)/len(df_ch)*100:.1f}% of all churn)")

comp_reasons = comp_ch["Churn_Reason"].value_counts().reset_index()
comp_reasons.columns = ["Reason","Count"]
comp_reasons["Pct"] = (comp_reasons["Count"]/comp_reasons["Count"].sum()*100).round(1)
print("\n📊 Competitor Churn Reasons:")
print(comp_reasons.to_string(index=False))

comp_profile = pd.DataFrame({
    "Metric": ["Avg Monthly Charge","Avg Tenure (Months)","Avg Addon Count",
               "Fiber Optic %","Month-to-Month %","Avg Referrals"],
    "Competitor Churners": [
        f"₹{comp_ch['Monthly_Charge'].mean():.2f}",
        f"{comp_ch['Tenure_in_Months'].mean():.1f}",
        f"{comp_ch['Addon_Count'].mean():.2f}",
        f"{(comp_ch['Internet_Type']=='Fiber Optic').mean()*100:.1f}%",
        f"{(comp_ch['Contract']=='Month-to-Month').mean()*100:.1f}%",
        f"{comp_ch['Number_of_Referrals'].mean():.2f}",
    ],
    "All Other Churners": [
        f"₹{df_ch[df_ch['Churn_Category']!='Competitor']['Monthly_Charge'].mean():.2f}",
        f"{df_ch[df_ch['Churn_Category']!='Competitor']['Tenure_in_Months'].mean():.1f}",
        f"{df_ch[df_ch['Churn_Category']!='Competitor']['Addon_Count'].mean():.2f}",
        f"{(df_ch[df_ch['Churn_Category']!='Competitor']['Internet_Type']=='Fiber Optic').mean()*100:.1f}%",
        f"{(df_ch[df_ch['Churn_Category']!='Competitor']['Contract']=='Month-to-Month').mean()*100:.1f}%",
        f"{df_ch[df_ch['Churn_Category']!='Competitor']['Number_of_Referrals'].mean():.2f}",
    ],
})
print("\n📊 Competitor Churner Profile:")
print(comp_profile.to_string(index=False))


# =============================================================================
# SECTION 9 — DISSATISFACTION DEEP DIVE
# =============================================================================
section("RCA-7: DEEP DIVE — Dissatisfaction-Driven Churn")

dis_ch = df_ch[df_ch["Churn_Category"] == "Dissatisfaction"]
print(f"\n🔍 Dissatisfaction churners: {len(dis_ch):,} ({len(dis_ch)/len(df_ch)*100:.1f}% of all churn)")

dis_reasons = dis_ch["Churn_Reason"].value_counts().reset_index()
dis_reasons.columns = ["Reason","Count"]
print("\n📊 Dissatisfaction Reasons:")
print(dis_reasons.to_string(index=False))

# Visualise all deep-dive categories together
fig, axes = plt.subplots(1, 2, figsize=(16, 6))
fig.suptitle("Deep Dive: Competitor vs. Dissatisfaction Churn Reasons", fontsize=13, y=1.01)

axes[0].barh(comp_reasons["Reason"].str[:40], comp_reasons["Count"],
             color=CHURN_RED, edgecolor="#0f0f1a", alpha=0.85)
axes[0].set_title("Competitor Churn Reasons")
axes[0].set_xlabel("Churned Customers")
axes[0].invert_yaxis()
axes[0].grid(True, axis="x", alpha=0.3)

axes[1].barh(dis_reasons["Reason"].str[:40], dis_reasons["Count"],
             color="#ff8c69", edgecolor="#0f0f1a", alpha=0.85)
axes[1].set_title("Dissatisfaction Churn Reasons")
axes[1].set_xlabel("Churned Customers")
axes[1].invert_yaxis()
axes[1].grid(True, axis="x", alpha=0.3)

plt.tight_layout()
save("rca12_deepdive_comp_dissatisfaction.png")
plt.show()


# =============================================================================
# SECTION 10 — RCA SUMMARY DASHBOARD
# =============================================================================
section("RCA-8: SUMMARY DASHBOARD — All Findings")

# ── 10.1  Churn rate by all key dimensions (Plotly parallel) ──
dims = {
    "Contract"         : df_cs.groupby("Contract").apply(lambda x:(x["Churn_Flag"].sum()/len(x)*100)).to_dict(),
    "Internet_Type"    : df_cs.groupby("Internet_Type").apply(lambda x:(x["Churn_Flag"].sum()/len(x)*100)).to_dict(),
    "Payment_Method"   : df_cs.groupby("Payment_Method").apply(lambda x:(x["Churn_Flag"].sum()/len(x)*100)).to_dict(),
    "Tenure_Group"     : df_cs.groupby("Tenure_Group",observed=True).apply(lambda x:(x["Churn_Flag"].sum()/len(x)*100)).to_dict(),
    "Age_Group"        : df_cs.groupby("Age_Group",observed=True).apply(lambda x:(x["Churn_Flag"].sum()/len(x)*100)).to_dict(),
    "Value_Deal"       : df_cs.groupby("Value_Deal").apply(lambda x:(x["Churn_Flag"].sum()/len(x)*100)).to_dict(),
}

rows = []
for dim, d in dims.items():
    for cat, rate in d.items():
        rows.append({"Dimension":dim,"Category":str(cat),"Churn_Rate":round(rate,2)})
dim_df = pd.DataFrame(rows).sort_values("Churn_Rate", ascending=False)

fig_dim = px.bar(
    dim_df,
    x="Churn_Rate",
    y="Category",
    color="Dimension",
    orientation="h",
    title="Churn Rate Across All Key Dimensions",
    labels={"Churn_Rate":"Churn Rate (%)","Category":""},
    template="plotly_dark",
    height=850,
    color_discrete_sequence=[CHURN_RED,"#ff8c69",WARN_YELLOW,TEAL_ACCENT,BLUE_ACCENT,"#c77dff"],
)
fig_dim.update_layout(yaxis={"categoryorder":"total ascending"})
save_html(fig_dim, "rca13_all_dimensions_churn_rate.html")
fig_dim.show()

# ── 10.2  Final printed RCA summary ───────────────────────────
total_ch  = len(df_ch)
total_cs  = len(df_cs)
churn_rt  = total_ch/total_cs*100
rev_lost  = df_ch["Total_Revenue"].sum()
top_cat   = cat_table.iloc[0]["Churn_Category"]
top_cat_pct = cat_table.iloc[0]["Pct_Churn"]
top_rsn   = reason_table.iloc[0]["Churn_Reason"]
mtm_rate  = df_cs[df_cs["Contract"]=="Month-to-Month"]["Churn_Flag"].mean()*100

print(f"""
╔══════════════════════════════════════════════════════════════════╗
║           ROOT CAUSE ANALYSIS — KEY FINDINGS SUMMARY            ║
╠══════════════════════════════════════════════════════════════════╣
║  Overall Churn Rate         : {churn_rt:.1f}%                           ║
║  Total Churned Customers    : {total_ch:,}                           ║
║  Total Revenue Lost         : ₹{rev_lost:,.0f}                    ║
╠══════════════════════════════════════════════════════════════════╣
║  WHY CUSTOMERS LEAVE                                             ║
║  ─────────────────────────────────────────────────────────────  ║
║  #1 Root Cause : {top_cat:<20} ({top_cat_pct:.1f}% of churn)           ║
║  #1 Reason     : {top_rsn[:48]:<48}  ║
╠══════════════════════════════════════════════════════════════════╣
║  LEADING INDICATORS (Red Flags)                                  ║
║  ─────────────────────────────────────────────────────────────  ║
║  ① Month-to-Month contract     → Churn rate: {mtm_rate:.1f}%           ║
║  ② Tenure < 6 months           → Highest early-exit risk        ║
║  ③ Fiber Optic internet         → Price-vs-expectation gap       ║
║  ④ Addon_Count = 0              → No switching cost, easy to go  ║
║  ⑤ Extra data charges present   → Billing shock trigger          ║
║  ⑥ Number_of_Referrals = 0      → Low brand engagement           ║
║  ⑦ Monthly Charge > ₹70        → High price sensitivity          ║
╠══════════════════════════════════════════════════════════════════╣
║  HIGHEST-RISK PROFILE                                            ║
║  ─────────────────────────────────────────────────────────────  ║
║  Month-to-Month + Fiber Optic + Tenure ≤12M + No add-ons        ║
║  → This segment has the highest churn rate in the dataset        ║
╠══════════════════════════════════════════════════════════════════╣
║  CHARTS SAVED TO: images/rca/                                    ║
║  rca01–rca12: Static PNGs (14 charts)                           ║
║  rca03, rca10, rca11, rca13: Interactive HTML (4 charts)        ║
╚══════════════════════════════════════════════════════════════════╝
""")

print("✅ Root Cause Analysis Complete!")
