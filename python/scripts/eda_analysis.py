# =============================================================================
#  Script   : eda_analysis.py
#  Purpose  : Complete Exploratory Data Analysis for Customer Churn Dataset
#  Dataset  : Customer_Data.csv  (6,419 records | 32 columns)
#  Tools    : Pandas, NumPy, Matplotlib, Seaborn, Plotly
#  Author   : [Your Name]
#  Project  : Customer Churn Analysis  (SQL + Python + Power BI)
#  Version  : 1.0
# =============================================================================


# =============================================================================
# SECTION 1 — IMPORT LIBRARIES
# =============================================================================

import os
import warnings
import numpy as np
import pandas as pd

# Matplotlib & Seaborn for static charts
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns

# Plotly for interactive charts
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

# Suppress non-critical warnings for clean output
warnings.filterwarnings("ignore")

# ── Global Style Configuration ────────────────────────────────
plt.rcParams.update({
    "figure.dpi"        : 130,
    "figure.facecolor"  : "#0f0f1a",   # dark background
    "axes.facecolor"    : "#1a1a2e",
    "axes.edgecolor"    : "#444466",
    "axes.labelcolor"   : "#e0e0f0",
    "xtick.color"       : "#b0b0cc",
    "ytick.color"       : "#b0b0cc",
    "text.color"        : "#e0e0f0",
    "grid.color"        : "#2a2a4a",
    "grid.linestyle"    : "--",
    "grid.alpha"        : 0.5,
    "font.family"       : "DejaVu Sans",
    "axes.titlesize"    : 13,
    "axes.labelsize"    : 11,
    "legend.fontsize"   : 10,
})

# ── Colour Palette ────────────────────────────────────────────
PALETTE        = ["#6c63ff", "#ff6584", "#43d9ad", "#ffd166", "#ef8c8c", "#06d6a0"]
CHURN_COLORS   = {"Churned": "#ff6584", "Stayed": "#43d9ad", "Joined": "#ffd166"}
CHURN_PALETTE  = [CHURN_COLORS["Churned"], CHURN_COLORS["Stayed"], CHURN_COLORS["Joined"]]

# ── Output Directory for saving charts ────────────────────────
BASE_DIR    = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # project root
IMAGES_DIR  = os.path.join(BASE_DIR, "images")
os.makedirs(IMAGES_DIR, exist_ok=True)

def save_fig(filename: str):
    """Save the current matplotlib figure to the images directory."""
    path = os.path.join(IMAGES_DIR, filename)
    plt.savefig(path, bbox_inches="tight", facecolor=plt.rcParams["figure.facecolor"])
    print(f"  ✅ Saved: images/{filename}")

print("✅ Libraries imported successfully.")
print(f"📁 Charts will be saved to: {IMAGES_DIR}\n")


# =============================================================================
# SECTION 2 — LOAD DATASET
# =============================================================================

# ── 2.1  Define file path ─────────────────────────────────────
DATA_PATH = os.path.join(BASE_DIR, "Customer_Data.csv")

# ── 2.2  Load raw CSV ─────────────────────────────────────────
df_raw = pd.read_csv(
    DATA_PATH,
    dtype={
        "Customer_ID"                   : str,
        "Gender"                        : str,
        "Married"                       : str,
        "State"                         : str,
        "Value_Deal"                    : str,
        "Phone_Service"                 : str,
        "Multiple_Lines"                : str,
        "Internet_Service"              : str,
        "Internet_Type"                 : str,
        "Online_Security"               : str,
        "Online_Backup"                 : str,
        "Device_Protection_Plan"        : str,
        "Premium_Support"               : str,
        "Streaming_TV"                  : str,
        "Streaming_Movies"              : str,
        "Streaming_Music"               : str,
        "Unlimited_Data"                : str,
        "Contract"                      : str,
        "Paperless_Billing"             : str,
        "Payment_Method"                : str,
        "Customer_Status"               : str,
        "Churn_Category"                : str,
        "Churn_Reason"                  : str,
    }
)

# ── 2.3  Work on a copy; preserve raw ─────────────────────────
df = df_raw.copy()

# ── 2.4  Strip leading/trailing whitespace from string columns ─
str_cols = df.select_dtypes(include="object").columns
df[str_cols] = df[str_cols].apply(lambda col: col.str.strip())

print(f"✅ Dataset loaded: {df.shape[0]:,} rows × {df.shape[1]} columns")
print(f"   File: {DATA_PATH}\n")


# =============================================================================
# SECTION 3 — DATA OVERVIEW
# =============================================================================

print("=" * 65)
print("SECTION 3 — DATA OVERVIEW")
print("=" * 65)

# ── 3.1  Shape ────────────────────────────────────────────────
print(f"\n📐 Shape : {df.shape[0]:,} rows × {df.shape[1]} columns")

# ── 3.2  Column data types ────────────────────────────────────
print("\n📋 Column Data Types:")
dtype_df = pd.DataFrame({
    "Column"   : df.columns,
    "Dtype"    : df.dtypes.values,
    "Non-Null" : df.notnull().sum().values,
    "Null"     : df.isnull().sum().values,
    "Unique"   : df.nunique().values,
})
print(dtype_df.to_string(index=False))

# ── 3.3  First 5 rows ─────────────────────────────────────────
print("\n🔍 First 5 Rows:")
print(df.head().to_string())

# ── 3.4  Last 5 rows ──────────────────────────────────────────
print("\n🔍 Last 5 Rows:")
print(df.tail().to_string())

# ── 3.5  Target variable distribution ─────────────────────────
print("\n🎯 Target Variable (Customer_Status) Distribution:")
status_counts = df["Customer_Status"].value_counts()
status_pct    = df["Customer_Status"].value_counts(normalize=True).mul(100).round(2)
print(pd.DataFrame({"Count": status_counts, "Percent (%)": status_pct}))


# =============================================================================
# SECTION 4 — MISSING VALUES ANALYSIS
# =============================================================================

print("\n" + "=" * 65)
print("SECTION 4 — MISSING VALUES ANALYSIS")
print("=" * 65)

# ── 4.1  Replace empty strings with NaN for uniform handling ──
df.replace("", np.nan, inplace=True)

# ── 4.2  Missing value summary ────────────────────────────────
missing = (
    pd.DataFrame({
        "Missing Count" : df.isnull().sum(),
        "Missing %"     : (df.isnull().mean() * 100).round(2),
    })
    .query("`Missing Count` > 0")
    .sort_values("Missing Count", ascending=False)
)
print(f"\n📊 Columns with missing values ({len(missing)} out of {df.shape[1]}):")
print(missing.to_string())

# ── 4.3  Visualise missing values — Seaborn heatmap ──────────
fig, ax = plt.subplots(figsize=(14, 6))
missing_matrix = df.isnull().astype(int)
sns.heatmap(
    missing_matrix.T,
    cbar=False,
    cmap="YlOrRd",
    ax=ax,
    yticklabels=df.columns,
    xticklabels=False,
)
ax.set_title("Missing Value Map (Yellow = Missing)", pad=14)
ax.set_xlabel("Customer Records (rows)")
ax.set_ylabel("Columns")
plt.tight_layout()
save_fig("01_missing_values_heatmap.png")
plt.show()

# ── 4.4  Apply cleaning to structural blanks ──────────────────
# (Mirrors the SQL cleaning from 03_data_cleaning.sql)
INTERNET_ADDONS = [
    "Internet_Type", "Online_Security", "Online_Backup",
    "Device_Protection_Plan", "Premium_Support", "Streaming_TV",
    "Streaming_Movies", "Streaming_Music", "Unlimited_Data",
]
df.loc[df["Internet_Service"] == "No", INTERNET_ADDONS] = "No Internet Service"
df.loc[df["Phone_Service"]    == "No", "Multiple_Lines"] = "No Phone Service"
df["Value_Deal"].fillna("No Deal", inplace=True)
df["Churn_Category"].fillna("Not Applicable", inplace=True)
df["Churn_Reason"].fillna("Not Applicable",   inplace=True)

# Fix negative Monthly_Charge
df["Monthly_Charge"] = df["Monthly_Charge"].abs()

# Binary churn flag
df["Churn_Flag"] = (df["Customer_Status"] == "Churned").astype(int)

# Tenure group
df["Tenure_Group"] = pd.cut(
    df["Tenure_in_Months"],
    bins=[0, 6, 12, 24, 36, 100],
    labels=["0-6 M", "7-12 M", "13-24 M", "25-36 M", "36+ M"],
    right=True,
)

# Age group
df["Age_Group"] = pd.cut(
    df["Age"],
    bins=[17, 30, 45, 60, 120],
    labels=["18-30", "31-45", "46-60", "60+"],
    right=True,
)

# Add-on count
addon_cols = [
    "Online_Security", "Online_Backup", "Device_Protection_Plan",
    "Premium_Support", "Streaming_TV", "Streaming_Movies", "Streaming_Music",
]
df["Addon_Count"] = df[addon_cols].apply(lambda row: (row == "Yes").sum(), axis=1)

print("\n✅ Structural blanks handled. Missing value count after cleaning:")
print(df.isnull().sum()[df.isnull().sum() > 0])


# =============================================================================
# SECTION 5 — SUMMARY STATISTICS
# =============================================================================

print("\n" + "=" * 65)
print("SECTION 5 — SUMMARY STATISTICS")
print("=" * 65)

# ── 5.1  Numerical columns ────────────────────────────────────
NUM_COLS = [
    "Age", "Number_of_Referrals", "Tenure_in_Months",
    "Monthly_Charge", "Total_Charges", "Total_Refunds",
    "Total_Extra_Data_Charges", "Total_Long_Distance_Charges", "Total_Revenue",
]
print("\n📈 Numerical Summary Statistics:")
print(df[NUM_COLS].describe().round(2).to_string())

# ── 5.2  Categorical columns ──────────────────────────────────
CAT_COLS = [
    "Gender", "Married", "Contract", "Payment_Method",
    "Internet_Type", "Customer_Status", "Churn_Category",
]
print("\n📊 Categorical Column Value Counts (Top 5 per column):")
for col in CAT_COLS:
    print(f"\n  [{col}]")
    print(df[col].value_counts().head(5).to_string())

# ── 5.3  Churn-specific statistics ────────────────────────────
df_churn   = df[df["Customer_Status"] == "Churned"]
df_stayed  = df[df["Customer_Status"] == "Stayed"]
print("\n📊 Mean Statistics: Churned vs. Stayed")
comparison = pd.DataFrame({
    "Churned Avg" : df_churn[NUM_COLS].mean().round(2),
    "Stayed Avg"  : df_stayed[NUM_COLS].mean().round(2),
    "Difference"  : (df_churn[NUM_COLS].mean() - df_stayed[NUM_COLS].mean()).round(2),
})
print(comparison.to_string())


# =============================================================================
# SECTION 6 — UNIVARIATE ANALYSIS
# =============================================================================

print("\n" + "=" * 65)
print("SECTION 6 — UNIVARIATE ANALYSIS")
print("=" * 65)

# ── 6.1  Distribution of all numerical columns (Matplotlib) ──
fig, axes = plt.subplots(3, 3, figsize=(16, 12))
fig.suptitle("Univariate Distribution — Numerical Columns", fontsize=15, y=1.02)
axes = axes.flatten()

for i, col in enumerate(NUM_COLS):
    ax = axes[i]
    ax.hist(df[col].dropna(), bins=40, color=PALETTE[0], edgecolor="#0f0f1a", alpha=0.85)
    ax.axvline(df[col].mean(),   color="#ffd166", linewidth=1.5, linestyle="--", label="Mean")
    ax.axvline(df[col].median(), color="#43d9ad", linewidth=1.5, linestyle=":",  label="Median")
    ax.set_title(col.replace("_", " "))
    ax.set_xlabel("Value")
    ax.set_ylabel("Count")
    ax.legend(fontsize=8)
    ax.grid(True, alpha=0.3)

plt.tight_layout()
save_fig("02_univariate_numerical.png")
plt.show()

# ── 6.2  Categorical value counts (Matplotlib) ────────────────
cat_plot_cols = [
    "Contract", "Payment_Method", "Internet_Type",
    "Gender", "Married", "Paperless_Billing", "Value_Deal",
]
fig, axes = plt.subplots(2, 4, figsize=(20, 9))
fig.suptitle("Univariate Distribution — Categorical Columns", fontsize=15)
axes = axes.flatten()

for i, col in enumerate(cat_plot_cols):
    ax = axes[i]
    counts = df[col].value_counts()
    bars = ax.barh(counts.index, counts.values, color=PALETTE[:len(counts)], edgecolor="#0f0f1a")
    ax.set_title(col.replace("_", " "))
    ax.set_xlabel("Count")
    # Add count labels
    for bar in bars:
        ax.text(bar.get_width() + 10, bar.get_y() + bar.get_height() / 2,
                f"{int(bar.get_width()):,}", va="center", fontsize=8, color="#e0e0f0")
    ax.grid(True, axis="x", alpha=0.3)

axes[-1].set_visible(False)  # hide unused subplot
plt.tight_layout()
save_fig("03_univariate_categorical.png")
plt.show()

# ── 6.3  Plotly interactive: Monthly Charge distribution ──────
fig_plotly = px.histogram(
    df[df["Customer_Status"].isin(["Churned", "Stayed"])],
    x="Monthly_Charge",
    color="Customer_Status",
    nbins=60,
    barmode="overlay",
    opacity=0.75,
    color_discrete_map=CHURN_COLORS,
    title="Monthly Charge Distribution — Churned vs. Stayed",
    labels={"Monthly_Charge": "Monthly Charge (₹)", "count": "Number of Customers"},
    template="plotly_dark",
)
fig_plotly.update_layout(legend_title="Status", bargap=0.05)
fig_plotly.write_html(os.path.join(IMAGES_DIR, "06a_monthly_charge_dist_interactive.html"))
fig_plotly.show()
print("  ✅ Interactive chart saved: images/06a_monthly_charge_dist_interactive.html")


# =============================================================================
# SECTION 7 — CHURN DISTRIBUTION
# =============================================================================

print("\n" + "=" * 65)
print("SECTION 7 — CHURN DISTRIBUTION")
print("=" * 65)

# ── 7.1  Donut chart: Overall churn split ─────────────────────
status_counts = df["Customer_Status"].value_counts()
fig, axes = plt.subplots(1, 2, figsize=(14, 6))
fig.suptitle("Customer Status Distribution", fontsize=15)

# Donut
wedges, texts, autotexts = axes[0].pie(
    status_counts.values,
    labels=status_counts.index,
    autopct="%1.1f%%",
    startangle=90,
    colors=CHURN_PALETTE,
    wedgeprops=dict(width=0.5, edgecolor="#0f0f1a", linewidth=2),
    textprops={"color": "#e0e0f0", "fontsize": 11},
)
for at in autotexts:
    at.set_fontsize(10)
    at.set_color("#0f0f1a")
    at.set_fontweight("bold")
axes[0].set_title("Proportion Split")

# Bar chart
bars = axes[1].bar(
    status_counts.index,
    status_counts.values,
    color=CHURN_PALETTE,
    edgecolor="#0f0f1a",
    linewidth=1.5,
    width=0.5,
)
for bar in bars:
    axes[1].text(
        bar.get_x() + bar.get_width() / 2,
        bar.get_height() + 30,
        f"{int(bar.get_height()):,}",
        ha="center", fontsize=11, fontweight="bold", color="#e0e0f0",
    )
axes[1].set_title("Absolute Count")
axes[1].set_ylabel("Number of Customers")
axes[1].grid(True, axis="y", alpha=0.3)

plt.tight_layout()
save_fig("04_churn_distribution.png")
plt.show()

# ── 7.2  Plotly interactive donut chart ──────────────────────
fig_donut = go.Figure(data=[go.Pie(
    labels=status_counts.index,
    values=status_counts.values,
    hole=0.55,
    marker=dict(colors=CHURN_PALETTE, line=dict(color="#0f0f1a", width=2)),
    textinfo="label+percent+value",
    textfont=dict(size=13),
)])
fig_donut.update_layout(
    title="Customer Status Distribution (Interactive)",
    template="plotly_dark",
    annotations=[dict(text="Churn<br>Analysis", x=0.5, y=0.5, font_size=14,
                      showarrow=False, font_color="white")],
)
fig_donut.write_html(os.path.join(IMAGES_DIR, "04a_churn_distribution_interactive.html"))
fig_donut.show()
print("  ✅ Interactive chart saved: images/04a_churn_distribution_interactive.html")


# =============================================================================
# SECTION 8 — BIVARIATE ANALYSIS
# =============================================================================

print("\n" + "=" * 65)
print("SECTION 8 — BIVARIATE ANALYSIS")
print("=" * 65)

# Filter to Churned + Stayed only for churn-rate comparisons
df_cs = df[df["Customer_Status"].isin(["Churned", "Stayed"])].copy()

def churn_rate_by(col: str, data: pd.DataFrame = df_cs) -> pd.DataFrame:
    """Compute churn rate grouped by a categorical column."""
    return (
        data.groupby(col)
        .agg(Total=("Churn_Flag", "count"), Churned=("Churn_Flag", "sum"))
        .assign(Churn_Rate=lambda x: (x["Churned"] / x["Total"] * 100).round(2))
        .sort_values("Churn_Rate", ascending=False)
        .reset_index()
    )

# ── 8.1  Churn rate by key categorical variables (Matplotlib grid) ─
biv_cols = ["Contract", "Internet_Type", "Payment_Method", "Tenure_Group",
            "Age_Group", "Monthly_Charge_Tier"]

# Add Monthly_Charge_Tier to dataframe
df_cs["Monthly_Charge_Tier"] = pd.cut(
    df_cs["Monthly_Charge"],
    bins=[0, 30, 60, 90, 999],
    labels=["Low (<30)", "Medium (30-60)", "High (61-90)", "Premium (>90)"],
)
df["Monthly_Charge_Tier"] = pd.cut(
    df["Monthly_Charge"],
    bins=[0, 30, 60, 90, 999],
    labels=["Low (<30)", "Medium (30-60)", "High (61-90)", "Premium (>90)"],
)

fig, axes = plt.subplots(2, 3, figsize=(18, 12))
fig.suptitle("Churn Rate by Key Business Variables", fontsize=15, y=1.01)
axes = axes.flatten()

for i, col in enumerate(biv_cols):
    ax = axes[i]
    cr = churn_rate_by(col, df_cs)
    colors = [CHURN_COLORS["Churned"] if r > cr["Churn_Rate"].median()
              else CHURN_COLORS["Stayed"] for r in cr["Churn_Rate"]]
    bars = ax.barh(cr[col].astype(str), cr["Churn_Rate"], color=colors, edgecolor="#0f0f1a")
    ax.set_title(f"Churn Rate by {col.replace('_', ' ')}")
    ax.set_xlabel("Churn Rate (%)")
    for bar in bars:
        ax.text(bar.get_width() + 0.3, bar.get_y() + bar.get_height() / 2,
                f"{bar.get_width():.1f}%", va="center", fontsize=9, color="#e0e0f0")
    ax.axvline(cr["Churn_Rate"].mean(), color="#ffd166", linestyle="--",
               linewidth=1.2, label=f"Avg {cr['Churn_Rate'].mean():.1f}%")
    ax.legend(fontsize=8)
    ax.grid(True, axis="x", alpha=0.3)

plt.tight_layout()
save_fig("05_bivariate_churn_rates.png")
plt.show()

# ── 8.2  Plotly: Churn rate by Contract type (interactive bar) ─
cr_contract = churn_rate_by("Contract")
fig_contract = px.bar(
    cr_contract,
    x="Contract",
    y="Churn_Rate",
    color="Churn_Rate",
    color_continuous_scale=["#43d9ad", "#ffd166", "#ff6584"],
    text="Churn_Rate",
    title="Churn Rate by Contract Type",
    labels={"Churn_Rate": "Churn Rate (%)", "Contract": "Contract Type"},
    template="plotly_dark",
)
fig_contract.update_traces(texttemplate="%{text:.1f}%", textposition="outside")
fig_contract.update_layout(coloraxis_showscale=False)
fig_contract.write_html(os.path.join(IMAGES_DIR, "05a_churn_by_contract_interactive.html"))
fig_contract.show()
print("  ✅ Interactive chart saved: images/05a_churn_by_contract_interactive.html")

# ── 8.3  Box plots: Monthly Charge vs. Customer Status ────────
fig, axes = plt.subplots(1, 3, figsize=(18, 6))
fig.suptitle("Financial Metrics by Customer Status", fontsize=14)
fin_cols = ["Monthly_Charge", "Total_Charges", "Total_Revenue"]

for i, col in enumerate(fin_cols):
    sns.boxplot(
        data=df_cs,
        x="Customer_Status",
        y=col,
        palette={"Churned": CHURN_COLORS["Churned"], "Stayed": CHURN_COLORS["Stayed"]},
        ax=axes[i],
        linewidth=1.5,
        flierprops=dict(marker="o", markerfacecolor="#ffd166", markersize=3, alpha=0.5),
    )
    axes[i].set_title(col.replace("_", " "))
    axes[i].set_xlabel("")
    axes[i].grid(True, axis="y", alpha=0.3)

plt.tight_layout()
save_fig("07_boxplot_financial_by_status.png")
plt.show()

# ── 8.4  Violin plot: Tenure by Customer Status ───────────────
fig, ax = plt.subplots(figsize=(10, 6))
sns.violinplot(
    data=df[df["Customer_Status"].isin(["Churned", "Stayed"])],
    x="Customer_Status",
    y="Tenure_in_Months",
    palette={"Churned": CHURN_COLORS["Churned"], "Stayed": CHURN_COLORS["Stayed"]},
    inner="quartile",
    ax=ax,
)
ax.set_title("Tenure Distribution by Customer Status")
ax.set_xlabel("")
ax.set_ylabel("Tenure (Months)")
ax.grid(True, axis="y", alpha=0.3)
plt.tight_layout()
save_fig("08_violin_tenure_by_status.png")
plt.show()


# =============================================================================
# SECTION 9 — CUSTOMER DEMOGRAPHICS
# =============================================================================

print("\n" + "=" * 65)
print("SECTION 9 — CUSTOMER DEMOGRAPHICS")
print("=" * 65)

# ── 9.1  Gender × Churn stacked bar (Matplotlib) ──────────────
fig, axes = plt.subplots(1, 3, figsize=(18, 6))
fig.suptitle("Churn Rates Across Demographics", fontsize=14)

demo_cols = ["Gender", "Married", "Age_Group"]
for i, col in enumerate(demo_cols):
    ax = axes[i]
    pivot = df_cs.groupby([col, "Customer_Status"]).size().unstack(fill_value=0)
    pivot_pct = pivot.div(pivot.sum(axis=1), axis=0) * 100

    pivot_pct.plot(
        kind="bar",
        stacked=True,
        color={"Churned": CHURN_COLORS["Churned"], "Stayed": CHURN_COLORS["Stayed"]},
        ax=ax,
        edgecolor="#0f0f1a",
        linewidth=0.8,
    )
    ax.set_title(f"Churn % by {col.replace('_', ' ')}")
    ax.set_ylabel("Percentage (%)")
    ax.set_xlabel("")
    ax.set_xticklabels(ax.get_xticklabels(), rotation=30, ha="right")
    ax.legend(title="Status", loc="upper right", fontsize=8)
    ax.yaxis.set_major_formatter(mticker.PercentFormatter())
    ax.grid(True, axis="y", alpha=0.3)

plt.tight_layout()
save_fig("09_demographics_churn_stacked.png")
plt.show()

# ── 9.2  Age distribution by churn status (Plotly) ────────────
fig_age = px.histogram(
    df_cs,
    x="Age",
    color="Customer_Status",
    nbins=40,
    barmode="overlay",
    opacity=0.75,
    color_discrete_map=CHURN_COLORS,
    title="Age Distribution — Churned vs. Stayed",
    labels={"Age": "Customer Age", "count": "Count"},
    template="plotly_dark",
)
fig_age.update_layout(bargap=0.02, legend_title="Status")
fig_age.write_html(os.path.join(IMAGES_DIR, "09a_age_distribution_interactive.html"))
fig_age.show()
print("  ✅ Interactive chart saved: images/09a_age_distribution_interactive.html")

# ── 9.3  State-wise churn rate (Plotly choropleth — bar substitute) ─
state_churn = (
    df_cs.groupby("State")
    .agg(Total=("Churn_Flag","count"), Churned=("Churn_Flag","sum"))
    .assign(Churn_Rate=lambda x: (x["Churned"]/x["Total"]*100).round(2))
    .sort_values("Churn_Rate", ascending=False)
    .reset_index()
)
fig_state = px.bar(
    state_churn,
    x="Churn_Rate",
    y="State",
    orientation="h",
    color="Churn_Rate",
    color_continuous_scale=["#43d9ad", "#ffd166", "#ff6584"],
    text="Churn_Rate",
    title="Churn Rate by Indian State",
    labels={"Churn_Rate": "Churn Rate (%)", "State": ""},
    template="plotly_dark",
    height=750,
)
fig_state.update_traces(texttemplate="%{text:.1f}%", textposition="outside")
fig_state.update_layout(coloraxis_showscale=False, yaxis={"categoryorder": "total ascending"})
fig_state.write_html(os.path.join(IMAGES_DIR, "09b_state_churn_rate_interactive.html"))
fig_state.show()
print("  ✅ Interactive chart saved: images/09b_state_churn_rate_interactive.html")


# =============================================================================
# SECTION 10 — REVENUE ANALYSIS
# =============================================================================

print("\n" + "=" * 65)
print("SECTION 10 — REVENUE ANALYSIS")
print("=" * 65)

# ── 10.1  Revenue summary table ───────────────────────────────
rev_summary = df.groupby("Customer_Status").agg(
    Customers         = ("Customer_ID",    "count"),
    Total_Revenue     = ("Total_Revenue",  "sum"),
    Avg_Revenue       = ("Total_Revenue",  "mean"),
    Avg_Monthly       = ("Monthly_Charge", "mean"),
    Total_Monthly     = ("Monthly_Charge", "sum"),
).round(2)
print("\n💰 Revenue Summary by Customer Status:")
print(rev_summary.to_string())

# ── 10.2  Revenue lost vs retained (Matplotlib) ───────────────
fig, axes = plt.subplots(1, 2, figsize=(15, 6))
fig.suptitle("Revenue Analysis", fontsize=14)

# Total revenue by status
rev_total = df.groupby("Customer_Status")["Total_Revenue"].sum() / 1e6  # in millions
axes[0].bar(rev_total.index, rev_total.values,
            color=CHURN_PALETTE[:len(rev_total)], edgecolor="#0f0f1a", linewidth=1.5, width=0.5)
axes[0].set_title("Total Revenue by Customer Status (₹ Millions)")
axes[0].set_ylabel("Total Revenue (₹ Millions)")
for i, (idx, val) in enumerate(rev_total.items()):
    axes[0].text(i, val + 0.3, f"₹{val:.1f}M", ha="center", fontweight="bold", color="#e0e0f0")
axes[0].grid(True, axis="y", alpha=0.3)

# Monthly revenue at risk scatter
scatter_df = df_cs.sample(min(1500, len(df_cs)), random_state=42)
sc = axes[1].scatter(
    scatter_df["Tenure_in_Months"],
    scatter_df["Monthly_Charge"],
    c=scatter_df["Churn_Flag"],
    cmap="RdYlGn_r",
    alpha=0.55,
    edgecolors="none",
    s=20,
)
axes[1].set_title("Monthly Charge vs. Tenure (Colour = Churn)")
axes[1].set_xlabel("Tenure (Months)")
axes[1].set_ylabel("Monthly Charge (₹)")
plt.colorbar(sc, ax=axes[1], label="Churn (1=Yes)")
axes[1].grid(True, alpha=0.3)

plt.tight_layout()
save_fig("10_revenue_analysis.png")
plt.show()

# ── 10.3  Plotly: Revenue lost by Churn Reason (Treemap) ──────
churn_reason_rev = (
    df[df["Customer_Status"] == "Churned"]
    .groupby(["Churn_Category", "Churn_Reason"])
    .agg(Customers=("Customer_ID","count"), Revenue_Lost=("Total_Revenue","sum"))
    .reset_index()
)
fig_tree = px.treemap(
    churn_reason_rev,
    path=["Churn_Category", "Churn_Reason"],
    values="Customers",
    color="Revenue_Lost",
    color_continuous_scale=["#1a1a2e", "#ff6584"],
    title="Churn Reason Treemap — Size = Customers | Colour = Revenue Lost",
    template="plotly_dark",
)
fig_tree.update_traces(textinfo="label+value+percent parent")
fig_tree.write_html(os.path.join(IMAGES_DIR, "10a_churn_reason_treemap.html"))
fig_tree.show()
print("  ✅ Interactive treemap saved: images/10a_churn_reason_treemap.html")

# ── 10.4  Plotly: Monthly Charge by Contract and Status (Box) ─
fig_box = px.box(
    df_cs,
    x="Contract",
    y="Monthly_Charge",
    color="Customer_Status",
    color_discrete_map=CHURN_COLORS,
    title="Monthly Charge Distribution by Contract Type and Churn Status",
    labels={"Monthly_Charge": "Monthly Charge (₹)", "Contract": "Contract Type"},
    template="plotly_dark",
    notched=True,
)
fig_box.write_html(os.path.join(IMAGES_DIR, "10b_monthly_charge_contract_box.html"))
fig_box.show()
print("  ✅ Interactive box plot saved: images/10b_monthly_charge_contract_box.html")


# =============================================================================
# SECTION 11 — CORRELATION ANALYSIS
# =============================================================================

print("\n" + "=" * 65)
print("SECTION 11 — CORRELATION ANALYSIS")
print("=" * 65)

# ── 11.1  Correlation matrix of numerical columns ─────────────
corr_cols = NUM_COLS + ["Churn_Flag", "Addon_Count"]
corr_matrix = df[corr_cols].corr().round(3)

print("\n📊 Correlation Matrix:")
print(corr_matrix.to_string())

# ── 11.2  Seaborn heatmap ─────────────────────────────────────
fig, ax = plt.subplots(figsize=(13, 10))
mask = np.triu(np.ones_like(corr_matrix, dtype=bool))     # show lower triangle only
sns.heatmap(
    corr_matrix,
    mask=mask,
    annot=True,
    fmt=".2f",
    cmap="coolwarm",
    center=0,
    vmin=-1,
    vmax=1,
    square=True,
    linewidths=0.5,
    linecolor="#0f0f1a",
    ax=ax,
    cbar_kws={"shrink": 0.8},
    annot_kws={"size": 8},
)
ax.set_title("Pearson Correlation Matrix — Numerical Features", pad=15)
plt.xticks(rotation=45, ha="right")
plt.tight_layout()
save_fig("11_correlation_heatmap.png")
plt.show()

# ── 11.3  Correlation with Churn_Flag (ranked bar chart) ──────
churn_corr = corr_matrix["Churn_Flag"].drop("Churn_Flag").sort_values()
fig, ax = plt.subplots(figsize=(10, 6))
colors = [CHURN_COLORS["Churned"] if v > 0 else CHURN_COLORS["Stayed"] for v in churn_corr.values]
bars = ax.barh(churn_corr.index, churn_corr.values, color=colors, edgecolor="#0f0f1a")
ax.axvline(0, color="#e0e0f0", linewidth=0.8)
ax.set_title("Feature Correlation with Churn Flag\n(Red = Positive Correlation | Green = Negative)")
ax.set_xlabel("Pearson Correlation Coefficient")
for bar in bars:
    xv = bar.get_width()
    ax.text(xv + (0.005 if xv >= 0 else -0.005),
            bar.get_y() + bar.get_height() / 2,
            f"{xv:.3f}", va="center", ha="left" if xv >= 0 else "right",
            fontsize=9, color="#e0e0f0")
ax.grid(True, axis="x", alpha=0.3)
plt.tight_layout()
save_fig("11b_churn_correlation_ranked.png")
plt.show()


# =============================================================================
# SECTION 12 — OUTLIER DETECTION
# =============================================================================

print("\n" + "=" * 65)
print("SECTION 12 — OUTLIER DETECTION")
print("=" * 65)

# ── 12.1  IQR-based outlier detection ────────────────────────
print("\n📊 Outlier Summary (IQR Method):")
outlier_summary = []
for col in NUM_COLS:
    Q1  = df[col].quantile(0.25)
    Q3  = df[col].quantile(0.75)
    IQR = Q3 - Q1
    lower = Q1 - 1.5 * IQR
    upper = Q3 + 1.5 * IQR
    n_out = ((df[col] < lower) | (df[col] > upper)).sum()
    outlier_summary.append({
        "Column"     : col,
        "Q1"         : round(Q1,  2),
        "Q3"         : round(Q3,  2),
        "IQR"        : round(IQR, 2),
        "Lower Fence": round(lower, 2),
        "Upper Fence": round(upper, 2),
        "Outlier Count": n_out,
        "Outlier %"  : round(n_out / len(df) * 100, 2),
    })
outlier_df = pd.DataFrame(outlier_summary)
print(outlier_df.to_string(index=False))

# ── 12.2  Box plots for outlier visualization (Matplotlib) ────
fig, axes = plt.subplots(3, 3, figsize=(16, 12))
fig.suptitle("Outlier Detection — Box Plots (IQR Method)", fontsize=14)
axes = axes.flatten()

for i, col in enumerate(NUM_COLS):
    ax = axes[i]
    bp = ax.boxplot(
        df[col].dropna(),
        vert=True,
        patch_artist=True,
        boxprops=dict(facecolor=PALETTE[0], color="#e0e0f0"),
        medianprops=dict(color="#ffd166", linewidth=2),
        whiskerprops=dict(color="#e0e0f0"),
        capprops=dict(color="#e0e0f0"),
        flierprops=dict(marker="o", markerfacecolor=CHURN_COLORS["Churned"],
                        markersize=3, alpha=0.5, markeredgewidth=0),
    )
    ax.set_title(col.replace("_", " "), fontsize=10)
    ax.set_ylabel("Value")
    ax.grid(True, axis="y", alpha=0.3)

plt.tight_layout()
save_fig("12_outlier_boxplots.png")
plt.show()

# ── 12.3  Plotly: Interactive scatter of outliers in Monthly_Charge ─
Q1_mc  = df["Monthly_Charge"].quantile(0.25)
Q3_mc  = df["Monthly_Charge"].quantile(0.75)
IQR_mc = Q3_mc - Q1_mc
df["Is_Outlier_MC"] = (
    (df["Monthly_Charge"] < Q1_mc - 1.5 * IQR_mc) |
    (df["Monthly_Charge"] > Q3_mc + 1.5 * IQR_mc)
).map({True: "Outlier", False: "Normal"})

fig_scatter = px.scatter(
    df_cs.assign(Is_Outlier_MC=df.loc[df_cs.index, "Is_Outlier_MC"]),
    x="Tenure_in_Months",
    y="Monthly_Charge",
    color="Is_Outlier_MC",
    color_discrete_map={"Outlier": "#ff6584", "Normal": "#6c63ff"},
    symbol="Customer_Status",
    opacity=0.7,
    title="Monthly Charge Outliers vs. Tenure",
    labels={"Monthly_Charge": "Monthly Charge (₹)", "Tenure_in_Months": "Tenure (Months)"},
    template="plotly_dark",
    hover_data=["Customer_ID", "Contract", "Internet_Type"],
)
fig_scatter.write_html(os.path.join(IMAGES_DIR, "12a_outlier_scatter_interactive.html"))
fig_scatter.show()
print("  ✅ Interactive chart saved: images/12a_outlier_scatter_interactive.html")


# =============================================================================
# SECTION 13 — CUSTOMER SEGMENTATION
# =============================================================================

print("\n" + "=" * 65)
print("SECTION 13 — CUSTOMER SEGMENTATION")
print("=" * 65)

# ── 13.1  Segment definition: Contract × Tenure group ─────────
seg = (
    df_cs.groupby(["Contract", "Tenure_Group"])
    .agg(
        Customers  = ("Customer_ID",    "count"),
        Churned    = ("Churn_Flag",     "sum"),
        Avg_Revenue= ("Total_Revenue",  "mean"),
        Avg_Charge = ("Monthly_Charge", "mean"),
    )
    .assign(Churn_Rate=lambda x: (x["Churned"] / x["Customers"] * 100).round(2))
    .reset_index()
)
print("\n📊 Customer Segment Table (Contract × Tenure):")
print(seg.to_string(index=False))

# ── 13.2  Heatmap: Churn Rate by Segment (Matplotlib) ─────────
pivot_seg = seg.pivot(index="Contract", columns="Tenure_Group", values="Churn_Rate")
fig, ax = plt.subplots(figsize=(12, 5))
sns.heatmap(
    pivot_seg,
    annot=True,
    fmt=".1f",
    cmap="RdYlGn_r",
    linewidths=0.8,
    linecolor="#0f0f1a",
    ax=ax,
    annot_kws={"size": 10, "fontweight": "bold"},
    cbar_kws={"label": "Churn Rate (%)"},
)
ax.set_title("Churn Rate Heatmap: Contract Type × Tenure Group", pad=15)
ax.set_xlabel("Tenure Group")
ax.set_ylabel("Contract Type")
plt.tight_layout()
save_fig("13_segment_heatmap_contract_tenure.png")
plt.show()

# ── 13.3  Plotly bubble chart: Segment × Revenue × Churn ──────
fig_bubble = px.scatter(
    seg,
    x="Avg_Charge",
    y="Churn_Rate",
    size="Customers",
    color="Contract",
    symbol="Tenure_Group",
    text="Tenure_Group",
    title="Customer Segment Bubble Chart<br>X=Avg Monthly Charge | Y=Churn Rate | Size=# Customers",
    labels={
        "Avg_Charge" : "Avg Monthly Charge (₹)",
        "Churn_Rate" : "Churn Rate (%)",
        "Customers"  : "Segment Size",
    },
    template="plotly_dark",
    size_max=60,
    color_discrete_sequence=PALETTE,
)
fig_bubble.update_traces(textposition="top center", textfont_size=9)
fig_bubble.write_html(os.path.join(IMAGES_DIR, "13a_segment_bubble_interactive.html"))
fig_bubble.show()
print("  ✅ Interactive bubble chart saved: images/13a_segment_bubble_interactive.html")

# ── 13.4  Add-on count vs churn rate — line plot ──────────────
addon_churn = (
    df_cs.groupby("Addon_Count")
    .agg(Customers=("Churn_Flag","count"), Churned=("Churn_Flag","sum"))
    .assign(Churn_Rate=lambda x: (x["Churned"]/x["Customers"]*100).round(2))
    .reset_index()
)
fig, ax1 = plt.subplots(figsize=(10, 5))
ax2 = ax1.twinx()

ax1.bar(addon_churn["Addon_Count"], addon_churn["Customers"],
        color=PALETTE[0], alpha=0.6, label="# Customers", width=0.4)
ax2.plot(addon_churn["Addon_Count"], addon_churn["Churn_Rate"],
         color=CHURN_COLORS["Churned"], marker="o", linewidth=2.5,
         markersize=8, label="Churn Rate (%)")

ax1.set_xlabel("Number of Add-On Services Subscribed")
ax1.set_ylabel("Number of Customers", color=PALETTE[0])
ax2.set_ylabel("Churn Rate (%)", color=CHURN_COLORS["Churned"])
ax1.set_title("Add-On Count vs. Churn Rate\n(More Add-Ons = Higher Switching Cost = Lower Churn)")
ax1.set_xticks(range(0, 8))
ax1.grid(True, alpha=0.3)

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc="upper right")
plt.tight_layout()
save_fig("13b_addon_count_churn_rate.png")
plt.show()

# ── 13.5  Final high-risk segment table ───────────────────────
print("\n🔴 HIGH-RISK SEGMENTS (Churn Rate > 30%):")
high_risk = (
    df_cs.groupby(["Contract", "Internet_Type", "Tenure_Group"])
    .agg(Customers=("Churn_Flag","count"), Churned=("Churn_Flag","sum"),
         Revenue_At_Risk=("Monthly_Charge","sum"))
    .assign(Churn_Rate=lambda x: (x["Churned"]/x["Customers"]*100).round(2))
    .query("Churn_Rate > 30 and Customers >= 20")
    .sort_values("Churn_Rate", ascending=False)
    .reset_index()
)
print(high_risk.to_string(index=False))


# =============================================================================
# SECTION 14 — SUMMARY REPORT
# =============================================================================

print("\n" + "=" * 65)
print("SECTION 14 — EDA SUMMARY REPORT")
print("=" * 65)

total        = len(df_cs)
churned      = df_cs["Churn_Flag"].sum()
churn_rate   = churned / total * 100
rev_lost     = df_cs[df_cs["Churn_Flag"]==1]["Total_Revenue"].sum()
mtm_at_risk  = df[
    (df["Customer_Status"]=="Stayed") & (df["Contract"]=="Month-to-Month")
]["Monthly_Charge"].sum()

print(f"""
╔══════════════════════════════════════════════════════════╗
║            CUSTOMER CHURN EDA — KEY FINDINGS            ║
╠══════════════════════════════════════════════════════════╣
║  Total Customers Analysed  : {total:>10,}                  ║
║  Total Churned             : {churned:>10,}                  ║
║  Overall Churn Rate        : {churn_rate:>9.2f}%                  ║
║  Lifetime Revenue Lost     : ₹{rev_lost:>12,.2f}             ║
║  Monthly Revenue at Risk   : ₹{mtm_at_risk:>12,.2f}             ║
╠══════════════════════════════════════════════════════════╣
║  TOP CHURN DRIVERS                                       ║
║  1. Contract Type  → Month-to-Month has highest churn   ║
║  2. Tenure         → 0-6 months at highest risk         ║
║  3. Internet Type  → Fiber Optic customers churn most   ║
║  4. Monthly Charge → High bills = price sensitivity     ║
║  5. Addon Count    → Fewer add-ons = more likely to go  ║
╠══════════════════════════════════════════════════════════╣
║  CHARTS SAVED TO: images/                               ║
║  01_missing_values_heatmap.png                          ║
║  02_univariate_numerical.png                            ║
║  03_univariate_categorical.png                          ║
║  04_churn_distribution.png                              ║
║  05_bivariate_churn_rates.png                           ║
║  07_boxplot_financial_by_status.png                     ║
║  08_violin_tenure_by_status.png                         ║
║  09_demographics_churn_stacked.png                      ║
║  10_revenue_analysis.png                                ║
║  11_correlation_heatmap.png                             ║
║  11b_churn_correlation_ranked.png                       ║
║  12_outlier_boxplots.png                                ║
║  13_segment_heatmap_contract_tenure.png                 ║
║  13b_addon_count_churn_rate.png                         ║
║  + 8 interactive Plotly HTML charts                     ║
╚══════════════════════════════════════════════════════════╝
""")

print("✅ EDA Complete!")
