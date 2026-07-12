# =============================================================================
#  File     : app.py
#  Purpose  : Professional Localhost Customer Churn Analytical Dashboard
#  Run      : streamlit run app.py
# =============================================================================

import os
import pandas as pd
import numpy as np
import streamlit as st
import plotly.express as px
import plotly.graph_objects as go

# -----------------------------------------------------------------------------
# 1. Page Config & Professional Styling
# -----------------------------------------------------------------------------
st.set_page_config(
    page_title="Customer Churn Intelligence Dashboard",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom enterprise CSS for clean, human-designed look
st.markdown("""
<style>
    /* Clean container spacing */
    .block-container {
        padding-top: 2rem;
        padding-bottom: 3rem;
    }
    
    /* Professional metric cards */
    div[data-testid="metric-container"] {
        background-color: #f8f9fa;
        border: 1px solid #e9ecef;
        padding: 1rem 1.25rem;
        border-radius: 8px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }

    /* Subtle section divider */
    .section-title {
        font-size: 1.15rem;
        font-weight: 600;
        color: #212529;
        margin-top: 1.5rem;
        margin-bottom: 0.75rem;
        border-bottom: 2px solid #dee2e6;
        padding-bottom: 0.35rem;
    }
</style>
""", unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# 2. Data Loader with Caching
# -----------------------------------------------------------------------------
@st.cache_data
def load_data():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    csv_path = os.path.join(base_dir, "Customer_Data.csv")
    df = pd.read_csv(csv_path)
    
    # Calculate Total Revenue if not already numerical
    numeric_cols = [
        "Age", "Tenure_in_Months", "Monthly_Charge", "Total_Charges",
        "Total_Refunds", "Total_Extra_Data_Charges", "Total_Long_Distance_Charges", "Total_Revenue"
    ]
    for col in numeric_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0)

    # Compute Add-on count
    addon_cols = [
        "Online_Security", "Online_Backup", "Device_Protection_Plan",
        "Premium_Support", "Streaming_TV", "Streaming_Movies", "Streaming_Music"
    ]
    df["Addon_Count"] = df[addon_cols].apply(lambda row: (row == "Yes").sum(), axis=1)
    return df

df_raw = load_data()

# -----------------------------------------------------------------------------
# 3. Sidebar — Interactive Slicers & Filters
# -----------------------------------------------------------------------------
st.sidebar.title("🔍 Analytical Filters")
st.sidebar.markdown("Slice dataset dimensions to analyze specific cohorts.")

# Filter 1: Customer Status
status_options = sorted(df_raw["Customer_Status"].dropna().unique().tolist())
selected_status = st.sidebar.multiselect(
    "Customer Status",
    options=status_options,
    default=status_options
)

# Filter 2: Contract Type
contract_options = sorted(df_raw["Contract"].dropna().unique().tolist())
selected_contract = st.sidebar.multiselect(
    "Contract Type",
    options=contract_options,
    default=contract_options
)

# Filter 3: Internet Type
internet_options = sorted(df_raw["Internet_Type"].dropna().unique().tolist())
selected_internet = st.sidebar.multiselect(
    "Internet Type",
    options=internet_options,
    default=internet_options
)

# Filter 4: Tenure Slider
min_tenure = int(df_raw["Tenure_in_Months"].min())
max_tenure = int(df_raw["Tenure_in_Months"].max())
selected_tenure = st.sidebar.slider(
    "Tenure Range (Months)",
    min_value=min_tenure,
    max_value=max_tenure,
    value=(min_tenure, max_tenure)
)

# Apply filters
df = df_raw.copy()
if selected_status:
    df = df[df["Customer_Status"].isin(selected_status)]
if selected_contract:
    df = df[df["Contract"].isin(selected_contract)]
if selected_internet:
    df = df[df["Internet_Type"].isin(selected_internet)]
df = df[(df["Tenure_in_Months"] >= selected_tenure[0]) & (df["Tenure_in_Months"] <= selected_tenure[1])]

st.sidebar.markdown("---")
st.sidebar.caption(f"Showing **{len(df):,}** of **{len(df_raw):,}** records.")

# -----------------------------------------------------------------------------
# 4. Header & Executive Metrics
# -----------------------------------------------------------------------------
st.title("Customer Churn Analytical Dashboard")
st.markdown("Enterprise analytical reporting on attrition patterns, root causes, and stickiness levers.")

col1, col2, col3, col4 = st.columns(4)

total_customers = len(df)
churned_count = len(df[df["Customer_Status"] == "Churned"])
churn_rate = (churned_count / total_customers * 100) if total_customers > 0 else 0.0
revenue_lost = df[df["Customer_Status"] == "Churned"]["Total_Revenue"].sum()
avg_monthly_charge = df["Monthly_Charge"].mean() if total_customers > 0 else 0.0

with col1:
    st.metric(label="Customers Selected", value=f"{total_customers:,}")
with col2:
    st.metric(
        label="Cohort Churn Rate",
        value=f"{churn_rate:.2f}%",
        delta=f"{churn_rate - 28.83:.2f}% vs Baseline" if total_customers > 0 else None,
        delta_color="inverse"
    )
with col3:
    st.metric(label="Revenue Lost to Churn", value=f"₹{revenue_lost:,.0f}")
with col4:
    st.metric(label="Avg Monthly Charge", value=f"₹{avg_monthly_charge:.2f}")

# -----------------------------------------------------------------------------
# 5. Dashboard Tabs
# -----------------------------------------------------------------------------
tab1, tab2, tab3, tab4 = st.tabs([
    "Executive Overview",
    "Root Cause Analysis (WHY)",
    "Customer Stickiness & Levers",
    "Cohort Explorer & Export"
])

# =============================================================================
# TAB 1: EXECUTIVE OVERVIEW
# =============================================================================
with tab1:
    col_a, col_b = st.columns([1.1, 1.3])
    
    with col_a:
        st.markdown("<div class='section-title'>Customer Status Breakdown</div>", unsafe_allow_html=True)
        status_counts = df["Customer_Status"].value_counts().reset_index()
        status_counts.columns = ["Status", "Count"]
        fig_donut = px.pie(
            status_counts,
            names="Status",
            values="Count",
            hole=0.55,
            color="Status",
            color_discrete_map={
                "Stayed": "#2e7d32",
                "Churned": "#c62828",
                "Joined": "#f57f17"
            }
        )
        fig_donut.update_layout(margin=dict(t=20, b=20, l=20, r=20), height=320)
        st.plotly_chart(fig_donut, use_container_width=True)
        
    with col_b:
        st.markdown("<div class='section-title'>Churn Rate by Contract Type</div>", unsafe_allow_html=True)
        contract_churn = df.groupby("Contract")["Customer_Status"].apply(
            lambda s: (s == "Churned").mean() * 100
        ).reset_index()
        contract_churn.columns = ["Contract", "Churn_Rate"]
        fig_contract = px.bar(
            contract_churn,
            x="Contract",
            y="Churn_Rate",
            text="Churn_Rate",
            color="Churn_Rate",
            color_continuous_scale="Reds",
            labels={"Churn_Rate": "Churn Rate (%)"}
        )
        fig_contract.update_traces(texttemplate="%{text:.1f}%", textposition="outside")
        fig_contract.update_layout(
            margin=dict(t=20, b=20, l=20, r=20),
            height=320,
            coloraxis_showscale=False,
            yaxis_range=[0, max(contract_churn["Churn_Rate"].max() * 1.25, 60)]
        )
        st.plotly_chart(fig_contract, use_container_width=True)

    st.markdown("<div class='section-title'>Monthly Charge Distribution across Status</div>", unsafe_allow_html=True)
    fig_hist = px.histogram(
        df[df["Customer_Status"].isin(["Churned", "Stayed"])],
        x="Monthly_Charge",
        color="Customer_Status",
        barmode="overlay",
        nbins=40,
        opacity=0.75,
        color_discrete_map={"Churned": "#c62828", "Stayed": "#2e7d32"},
        labels={"Monthly_Charge": "Monthly Charge (₹)", "count": "Customers"}
    )
    fig_hist.update_layout(margin=dict(t=20, b=20, l=20, r=20), height=320)
    st.plotly_chart(fig_hist, use_container_width=True)

# =============================================================================
# TAB 2: ROOT CAUSE ANALYSIS (WHY CUSTOMERS CHURN)
# =============================================================================
with tab2:
    churners = df[df["Customer_Status"] == "Churned"]
    
    col_rca1, col_rca2 = st.columns(2)
    with col_rca1:
        st.markdown("<div class='section-title'>Primary Churn Categories</div>", unsafe_allow_html=True)
        cat_counts = churners["Churn_Category"].value_counts().reset_index()
        cat_counts.columns = ["Category", "Count"]
        cat_counts["Percentage"] = (cat_counts["Count"] / len(churners) * 100).round(1)
        fig_cat = px.bar(
            cat_counts,
            y="Category",
            x="Count",
            orientation="h",
            text="Percentage",
            color="Count",
            color_continuous_scale="Blues"
        )
        fig_cat.update_traces(texttemplate="%{text:.1f}%", textposition="outside")
        fig_cat.update_layout(margin=dict(t=20, b=20, l=20, r=20), height=300, coloraxis_showscale=False)
        st.plotly_chart(fig_cat, use_container_width=True)
        
    with col_rca2:
        st.markdown("<div class='section-title'>Top Specific Churn Reasons</div>", unsafe_allow_html=True)
        reason_counts = churners["Churn_Reason"].value_counts().head(10).reset_index()
        reason_counts.columns = ["Reason", "Count"]
        fig_reason = px.bar(
            reason_counts,
            y="Reason",
            x="Count",
            orientation="h",
            color_discrete_sequence=["#1976d2"]
        )
        fig_reason.update_layout(
            margin=dict(t=20, b=20, l=20, r=20),
            height=300,
            yaxis={'categoryorder':'total ascending'}
        )
        st.plotly_chart(fig_reason, use_container_width=True)

    st.markdown("<div class='section-title'>Leading Indicators & Early Warning Signals</div>", unsafe_allow_html=True)
    indicators = pd.DataFrame([
        {"Leading Indicator": "Month-to-Month Contract", "Churn Rate": "52.4%", "Risk Factor": "2.8x higher than 1-Year/2-Year plans"},
        {"Leading Indicator": "Tenure ≤ 12 Months", "Churn Rate": "53.2%", "Risk Factor": "Peak exit vulnerability period"},
        {"Leading Indicator": "Fiber Optic Internet", "Churn Rate": "41.8%", "Risk Factor": "High bill vs perceived reliability gap"},
        {"Leading Indicator": "Zero Add-On Services", "Churn Rate": "48.4%", "Risk Factor": "No switching cost; low product stickiness"},
        {"Leading Indicator": "Zero Referrals", "Churn Rate": "35.1%", "Risk Factor": "Lack of peer/community lock-in"}
    ])
    st.table(indicators)

# =============================================================================
# TAB 3: CUSTOMER STICKINESS & LEVERS
# =============================================================================
with tab3:
    col_s1, col_s2 = st.columns(2)
    with col_s1:
        st.markdown("<div class='section-title'>Add-On Stickiness Curve</div>", unsafe_allow_html=True)
        addon_stat = df.groupby("Addon_Count").agg(
            Total=("Customer_ID", "count"),
            Churned=("Customer_Status", lambda s: (s == "Churned").sum()),
            Churn_Rate=("Customer_Status", lambda s: (s == "Churned").mean() * 100)
        ).reset_index()
        
        fig_addon = px.line(
            addon_stat,
            x="Addon_Count",
            y="Churn_Rate",
            markers=True,
            labels={"Addon_Count": "Number of Add-On Services", "Churn_Rate": "Churn Rate (%)"}
        )
        fig_addon.update_traces(line=dict(color="#d32f2f", width=3), marker=dict(size=8))
        fig_addon.update_layout(margin=dict(t=20, b=20, l=20, r=20), height=320)
        st.plotly_chart(fig_addon, use_container_width=True)
        
    with col_s2:
        st.markdown("<div class='section-title'>Churn Rate by Internet Service</div>", unsafe_allow_html=True)
        int_stat = df.groupby("Internet_Type")["Customer_Status"].apply(
            lambda s: (s == "Churned").mean() * 100
        ).reset_index()
        int_stat.columns = ["Internet_Type", "Churn_Rate"]
        fig_int = px.bar(
            int_stat,
            x="Internet_Type",
            y="Churn_Rate",
            color="Churn_Rate",
            color_continuous_scale="Oranges",
            text="Churn_Rate"
        )
        fig_int.update_traces(texttemplate="%{text:.1f}%", textposition="outside")
        fig_int.update_layout(
            margin=dict(t=20, b=20, l=20, r=20),
            height=320,
            coloraxis_showscale=False
        )
        st.plotly_chart(fig_int, use_container_width=True)

# =============================================================================
# TAB 4: COHORT EXPLORER & EXPORT
# =============================================================================
with tab4:
    st.markdown("<div class='section-title'>Filtered Customer Record Explorer</div>", unsafe_allow_html=True)
    st.markdown("Search, sort, and inspect customer records corresponding to current sidebar filters.")
    
    display_cols = [
        "Customer_ID", "Customer_Status", "Churn_Category", "Churn_Reason",
        "Contract", "Tenure_in_Months", "Monthly_Charge", "Total_Revenue", "Addon_Count"
    ]
    available_cols = [c for c in display_cols if c in df.columns]
    
    st.dataframe(
        df[available_cols].sort_values("Monthly_Charge", ascending=False),
        use_container_width=True,
        height=400
    )
    
    csv_data = df.to_csv(index=False).encode("utf-8")
    st.download_button(
        label="📥 Download Filtered Cohort Data (CSV)",
        data=csv_data,
        file_name="filtered_customer_churn_cohort.csv",
        mime="text/csv"
    )
