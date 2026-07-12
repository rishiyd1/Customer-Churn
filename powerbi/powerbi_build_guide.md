# 📊 Power BI Dashboard — Complete Build Guide
### Customer Churn Analysis · 6 Pages · 40+ DAX Measures

---

## Step 0 — Setup Before Building

### 0.1 Connect Power BI to MySQL

1. Open Power BI Desktop → **Home → Get Data → MySQL database**
2. Server: `localhost` | Database: `customer_churn_db`
3. **Import mode** (not DirectQuery — dataset is small enough)
4. Import these tables/views:
   ```
   ✅ customer_churn_clean       (main fact table)
   ✅ vw_executive_summary       (Page 1 KPIs)
   ✅ vw_churn_by_dimension      (Page 3 charts)
   ✅ vw_revenue_analysis        (Page 4 charts)
   ✅ vw_churn_reasons           (Page 3 treemap)
   ✅ vw_segment_risk            (Page 6 table)
   ✅ vw_addon_stickiness        (Page 5 chart)
   ✅ vw_state_summary           (map visual)
   ✅ vw_high_risk_customers     (Page 6 table)
   ```

### 0.2 Apply Theme
1. **View → Themes → Browse for themes**
2. Select `powerbi/customer_churn_theme.json`
3. Click **Apply** — all pages inherit the dark navy theme automatically

### 0.3 Set Canvas Size (All Pages)
- **View → Page View → Actual Size**
- **Format Page → Page Size → Custom → 1440 × 900 px**

---

## DAX MEASURES — Master Library

> Create all measures in a dedicated `_Measures` table:  
> **Modeling → New Table** → Name it `_Measures` → Add each measure below

```
-- ═══════════════════════════════════════════════
-- VOLUME MEASURES
-- ═══════════════════════════════════════════════

Total Customers =
COUNTROWS(customer_churn_clean)

Total Churned =
CALCULATE(
    COUNTROWS(customer_churn_clean),
    customer_churn_clean[Customer_Status] = "Churned"
)

Total Stayed =
CALCULATE(
    COUNTROWS(customer_churn_clean),
    customer_churn_clean[Customer_Status] = "Stayed"
)

Total New Joiners =
CALCULATE(
    COUNTROWS(customer_churn_clean),
    customer_churn_clean[Customer_Status] = "Joined"
)

-- ═══════════════════════════════════════════════
-- CHURN RATE MEASURES
-- ═══════════════════════════════════════════════

Churn Rate % =
DIVIDE(
    [Total Churned],
    [Total Churned] + [Total Stayed],
    0
) * 100

MTM Churn Rate % =
CALCULATE(
    [Churn Rate %],
    customer_churn_clean[Contract] = "Month-to-Month"
)

Fiber Churn Rate % =
CALCULATE(
    [Churn Rate %],
    customer_churn_clean[Internet_Type] = "Fiber Optic"
)

Churn Rate Formatted =
FORMAT([Churn Rate %], "0.0") & "%"

Churn Rate vs Target =
[Churn Rate %] - 20   -- 20% = industry target

-- ═══════════════════════════════════════════════
-- REVENUE MEASURES
-- ═══════════════════════════════════════════════

Total Revenue =
SUM(customer_churn_clean[Total_Revenue])

Revenue Lost =
CALCULATE(
    SUM(customer_churn_clean[Total_Revenue]),
    customer_churn_clean[Customer_Status] = "Churned"
)

Revenue Retained =
CALCULATE(
    SUM(customer_churn_clean[Total_Revenue]),
    customer_churn_clean[Customer_Status] = "Stayed"
)

Monthly Revenue Lost =
CALCULATE(
    SUM(customer_churn_clean[Monthly_Charge]),
    customer_churn_clean[Customer_Status] = "Churned"
)

At Risk Monthly Revenue =
CALCULATE(
    SUM(customer_churn_clean[Monthly_Charge]),
    customer_churn_clean[Customer_Status] = "Stayed",
    customer_churn_clean[Contract] = "Month-to-Month"
)

Avg Monthly Charge =
AVERAGE(customer_churn_clean[Monthly_Charge])

Avg Revenue Per Customer =
AVERAGE(customer_churn_clean[Total_Revenue])

Avg Churner Revenue =
CALCULATE(
    AVERAGE(customer_churn_clean[Total_Revenue]),
    customer_churn_clean[Customer_Status] = "Churned"
)

Revenue Lost % =
DIVIDE([Revenue Lost], [Total Revenue], 0) * 100

-- ═══════════════════════════════════════════════
-- TENURE MEASURES
-- ═══════════════════════════════════════════════

Avg Tenure Months =
AVERAGE(customer_churn_clean[Tenure_in_Months])

Avg Churner Tenure =
CALCULATE(
    AVERAGE(customer_churn_clean[Tenure_in_Months]),
    customer_churn_clean[Customer_Status] = "Churned"
)

Avg Stayer Tenure =
CALCULATE(
    AVERAGE(customer_churn_clean[Tenure_in_Months]),
    customer_churn_clean[Customer_Status] = "Stayed"
)

Tenure Gap =
[Avg Stayer Tenure] - [Avg Churner Tenure]

-- ═══════════════════════════════════════════════
-- ENGAGEMENT MEASURES
-- ═══════════════════════════════════════════════

Avg Addon Count =
AVERAGE(customer_churn_clean[Addon_Count])

Avg Referrals =
AVERAGE(customer_churn_clean[Number_of_Referrals])

Customers With Overage =
CALCULATE(
    COUNTROWS(customer_churn_clean),
    customer_churn_clean[Total_Extra_Data_Charges] > 0
)

Overage Churn Rate % =
CALCULATE(
    [Churn Rate %],
    customer_churn_clean[Total_Extra_Data_Charges] > 0
)

Customers With Refunds =
CALCULATE(
    COUNTROWS(customer_churn_clean),
    customer_churn_clean[Total_Refunds] > 0
)

-- ═══════════════════════════════════════════════
-- AT-RISK MEASURES
-- ═══════════════════════════════════════════════

At Risk Customers =
CALCULATE(
    COUNTROWS(customer_churn_clean),
    customer_churn_clean[Customer_Status] = "Stayed",
    customer_churn_clean[Contract] = "Month-to-Month"
)

Critical Risk Customers =
CALCULATE(
    COUNTROWS(vw_high_risk_customers),
    vw_high_risk_customers[Risk_Level] = "Critical"
)

-- ═══════════════════════════════════════════════
-- FORMATTING HELPERS
-- ═══════════════════════════════════════════════

Revenue Lost Formatted =
"₹" & FORMAT([Revenue Lost] / 1000000, "0.0") & "M"

At Risk Revenue Formatted =
"₹" & FORMAT([At Risk Monthly Revenue] / 1000, "0.0") & "K/mo"

Churn Rate Color =
IF([Churn Rate %] > 25, "#FF6584",
   IF([Churn Rate %] > 15, "#FFD166", "#43D9AD"))
```

---

## PAGE 1 — Executive Dashboard

> **Purpose:** Single-screen business overview for C-suite. All critical KPIs visible at a glance.

### Layout Grid (1440 × 900 px)

```
┌─────────────────────────────────────────────────────────────┐
│  PAGE TITLE: "Customer Churn — Executive Dashboard"         │ ← Header bar (40px)
├──────────┬──────────┬──────────┬──────────┬────────────────┤
│  KPI 1   │  KPI 2   │  KPI 3   │  KPI 4   │  KPI 5         │ ← Row 1: KPI Cards (140px)
│ Churn    │ Churned  │ Rev Lost │ At Risk  │ At Risk Rev    │
│  Rate    │  Count   │          │ Customers│                 │
├──────────┴──────────┴──────────┴──────────┴────────────────┤
│                                                             │
│  DONUT CHART (35%)        │  BAR CHART: Churn by Contract   │ ← Row 2 (300px)
│  Customer Status Split    │  + Churn by Internet Type       │
│                           │                                 │
├───────────────────────────┴─────────────────────────────────┤
│                                                             │
│  MAP: Churn Rate by State (50%)  │ GAUGE: Churn Rate (25%)  │ ← Row 3 (280px)
│                                  │ vs 20% target            │
│                                  │ + TOP 5 Churn Reasons    │
└──────────────────────────────────┴─────────────────────────┘
```

### KPI Cards (Row 1 — 5 cards side by side)

| # | Card Title | DAX Measure | Conditional Format |
|---|---|---|---|
| 1 | Churn Rate | `[Churn Rate %]` | Red if >25%, Yellow if >15% |
| 2 | Total Churned | `[Total Churned]` | Always red |
| 3 | Revenue Lost | `[Revenue Lost Formatted]` | Always red |
| 4 | At-Risk Customers | `[At Risk Customers]` | Yellow |
| 5 | Monthly Revenue at Risk | `[At Risk Revenue Formatted]` | Yellow |

**How to build:**
1. Insert → Card visual × 5
2. Field: drag respective measure into **Fields** well
3. Format → Data Label → Font Size: 32, Bold, White
4. Format → Category Label → Font Size: 11, color #B0B0CC
5. Format → Background → color #1E1E32, border radius 8px
6. Format → Border → color #2A2A4A, 1px

### Donut Chart: Customer Status Split

**How to build:**
1. Insert → **Donut Chart**
2. Legend: `Customer_Status`
3. Values: `[Total Customers]`
4. Format → Colors: Churned=#FF6584, Stayed=#43D9AD, Joined=#FFD166
5. Format → Inner radius: 60%
6. Format → Detail labels: Category + Percent
7. Format → Legend: Top, white text
8. Title: "Customer Status Distribution"

### Clustered Bar: Churn by Contract & Internet Type

**How to build:**
1. Insert → **Clustered bar chart**
2. Y-axis: `Contract`
3. X-axis: `[Churn Rate %]`
4. Add second bar chart below: Y=`Internet_Type`, X=`[Churn Rate %]`
5. Format → Data colors: Use gradient (green→yellow→red based on value)
6. Format → Data labels: On, format as "0.0%"
7. Format → X-axis: Title "Churn Rate (%)", max value: 60

### Map: Churn Rate by State

**How to build:**
1. Insert → **Map** (or Filled Map)
2. Location: `State` (from `vw_state_summary`)
3. Bubble size / Color saturation: `Churn_Rate_Pct`
4. Tooltips: `Total_Customers`, `Churned`, `Revenue_Lost`
5. Format → Map styles: Dark (matches theme)
6. Format → Bubbles: Min color #43D9AD, Max color #FF6584

> **Note:** Power BI may need State names mapped to India geography. In the State field, set **Data Category → State or Province**.

### Gauge: Churn Rate vs Target

**How to build:**
1. Insert → **Gauge**
2. Value: `[Churn Rate %]`
3. Minimum: 0 | Maximum: 50 | Target: 20
4. Format → Gauge axis: Min=0, Max=50
5. Format → Target: color #FFD166, show label
6. Format → Fill color: red gradient (poor=red, good=green)
7. Title: "Churn Rate vs. 20% Target"

### Slicers (Page 1)

| Slicer | Field | Style |
|---|---|---|
| Contract Type | `Contract` | Dropdown |
| Internet Type | `Internet_Type` | Dropdown |
| State | `State` | Dropdown / Search |

---

## PAGE 2 — Customer Dashboard

> **Purpose:** Demographics and customer profile overview.

### Layout Grid

```
┌──────────────────────────────────────────────────────────┐
│  TITLE: "Customer Profile Dashboard"                     │
├────────┬────────┬────────┬────────┬──────────────────────┤
│ KPI 1  │ KPI 2  │ KPI 3  │ KPI 4  │ KPI 5               │ ← Cards
│ Total  │ Active │Avg Age │Avg Ten.│ Avg Referrals       │
├────────┴────────┴────────┴────────┴──────────────────────┤
│                                          │               │
│  AGE HISTOGRAM (40%)                     │ GENDER DONUT  │ ← Row 2
│  By Customer_Status                      │ (25%)         │
│                                          │               │
├──────────────────────────────────────────┤ MARRIED DONUT │
│                                          │ (25%)         │
│  STACKED BAR: State × Customer_Status    │               │
│  (top 10 states by customer count)       │               │
│                                          │               │
├──────────────────────────────────────────┴───────────────┤
│  TENURE DISTRIBUTION (histogram)  │ AGE GROUP BAR (churn)│
└────────────────────────────────────┴─────────────────────┘
```

### KPI Cards (Row 1)

| Measure | Value |
|---|---|
| Total Customers | `[Total Customers]` |
| Active Customers | `[Total Stayed]` |
| Avg Age | `AVERAGE(customer_churn_clean[Age])` |
| Avg Tenure | `[Avg Tenure Months]` |
| Avg Referrals | `[Avg Referrals]` |

### Age Distribution: Histogram by Status

**How to build:**
1. Insert → **Clustered Column Chart**
2. X-axis: `Age` (set to bins of 5 years using Power BI's built-in bin feature)
3. Y-axis: `[Total Customers]`
4. Legend: `Customer_Status`
5. Format → Colors: Churned=#FF6584, Stayed=#43D9AD
6. Title: "Age Distribution — Churned vs. Stayed"

> **Creating bins:** Right-click `Age` in Fields pane → **New group** → Bin size: 5

### Gender & Married Donut Charts

**How to build (same steps for both):**
1. Insert → **Donut Chart**
2. Legend: `Gender` (or `Married`)
3. Values: `[Total Customers]`
4. Inner radius: 60%
5. Show detail labels as percent

### State Stacked Bar (Top 10 States)

**How to build:**
1. Insert → **Stacked bar chart**
2. Y-axis: `State`
3. X-axis: `[Total Customers]`
4. Legend: `Customer_Status`
5. Add a **Top N filter** on `State`: Top 10 by `[Total Customers]`
6. Sort by total count descending

### Tenure Histogram

**How to build:**
1. Insert → **Clustered Column Chart**
2. X-axis: `Tenure_Group` (categorical)
3. Y-axis: `[Total Customers]`
4. Legend: `Customer_Status`
5. Sort X by custom order: 0–6M, 7–12M, 13–24M, 25–36M, 36M+

> Add sort column: **Modeling → New Column** in `customer_churn_clean`:
> ```
> Tenure_Sort =
> SWITCH(customer_churn_clean[Tenure_Group],
>     "0-6 Months", 1, "7-12 Months", 2,
>     "13-24 Months", 3, "25-36 Months", 4, 5)
> ```

### Slicers (Page 2)

| Slicer | Field | Style |
|---|---|---|
| Gender | `Gender` | Button style |
| Married | `Married` | Button style |
| Age Group | `Age_Group` | List |
| State | `State` | Dropdown |

---

## PAGE 3 — Churn Dashboard

> **Purpose:** Deep dive into churn rates across every dimension. The analytical core page.

### Layout Grid

```
┌──────────────────────────────────────────────────────────┐
│  TITLE: "Churn Analysis Dashboard"                       │
├────────┬────────┬─────────────────┬──────────────────────┤
│Churn % │MTM Rate│Fiber Rate       │ Avg Churner Tenure   │ ← 4 KPI Cards
├────────┴────────┴─────────────────┴──────────────────────┤
│                           │                              │
│  TREEMAP: Churn Reasons   │  CLUSTERED BAR: Churn by    │ ← Row 2
│  (Churn_Category →        │  Contract (sorted desc)     │
│   Churn_Reason)           │                             │
│                           │                              │
├───────────────────────────┴──────────────────────────────┤
│ BAR: Internet Type │ BAR: Payment Method │ BAR: Tenure    │ ← Row 3
├────────────────────┴─────────────────────┴───────────────┤
│                                                          │
│  MATRIX: Churn Rate % by Contract × Internet Type        │ ← Row 4
│  (heatmap-style conditional formatting)                  │
└──────────────────────────────────────────────────────────┘
```

### KPI Cards (Row 1)

```
[Churn Rate %]
[MTM Churn Rate %]
[Fiber Churn Rate %]
[Avg Churner Tenure]  ← with subtitle "(vs [Avg Stayer Tenure] for stayed)"
```

### Treemap: Churn Reason Hierarchy

**How to build:**
1. Source: `vw_churn_reasons`
2. Insert → **Treemap**
3. Category: `Churn_Category`
4. Details: `Churn_Reason`
5. Values: `Churned_Customers`
6. Tooltips: `Revenue_Lost`, `Avg_Monthly_Charge`, `Avg_Tenure_Months`
7. Format → Data colors: Use conditional formatting by `Churn_Category`:
   - Competitor = #FF6584
   - Dissatisfaction = #FF8C69
   - Price = #FFD166
   - Attitude = #43D9AD
   - Other = #6C63FF
8. Title: "Why Customers Leave — Churn Category → Specific Reason"

### Churn Rate Bars (Contract, Internet, Payment, Tenure)

**How to build (repeat for each):**
1. Source: `vw_churn_by_dimension`
2. Insert → **Clustered bar chart**
3. Filter `Dimension` = "Contract" (or relevant dimension)
4. Y-axis: `Category`
5. X-axis: `Churn_Rate_Pct`
6. Format → Data colors: Conditional format — gradient from #43D9AD (0%) → #FF6584 (50%+)
7. Format → Data labels: On, format "0.0%"
8. Sort: By Churn_Rate_Pct descending

### Heatmap Matrix: Contract × Internet Type

**How to build:**
1. Insert → **Matrix** visual
2. Rows: `Contract`
3. Columns: `Internet_Type`
4. Values: `[Churn Rate %]`
5. **Format → Conditional formatting on Values:**
   - By rules: <15 = Green, 15–30 = Yellow, >30 = Red
   - Or use Color scale: Min=#43D9AD, Mid=#FFD166, Max=#FF6584
6. Format → Cell elements → Bold, center-aligned
7. Title: "Churn Rate Heatmap: Contract × Internet Type"

### Slicers (Page 3)

| Slicer | Field | Style |
|---|---|---|
| Contract | `Contract` | Button |
| Internet Type | `Internet_Type` | Button |
| Tenure Group | `Tenure_Group` | Dropdown |
| Churn Category | `Churn_Category` | List |
| State | `State` | Dropdown |

---

## PAGE 4 — Revenue Dashboard

> **Purpose:** Financial impact of churn — where money is lost and where it's protected.

### Layout Grid

```
┌──────────────────────────────────────────────────────────┐
│  TITLE: "Revenue & Financial Impact Dashboard"           │
├────────┬────────┬─────────┬─────────┬────────────────────┤
│ Total  │ Rev    │Monthly  │Avg Rev  │ Rev Lost %         │ ← 5 KPI Cards
│Revenue │ Lost   │Rev Lost │/Customer│                    │
├────────┴────────┴─────────┴─────────┴────────────────────┤
│                                    │                     │
│  WATERFALL: Revenue by Status      │ DONUT: Revenue      │ ← Row 2
│  (Retained → Lost → New Joiners)   │ Split by Status     │
│                                    │                     │
├────────────────────────────────────┴─────────────────────┤
│                           │                              │
│  BAR: Revenue Lost by     │  SCATTER: Tenure vs Charge   │ ← Row 3
│  Churn Reason             │  (colour = churn flag)       │
│                           │                              │
├───────────────────────────┴──────────────────────────────┤
│  BAR: Revenue by Contract │  BAR: Revenue by Internet    │ ← Row 4
└────────────────────────────┴─────────────────────────────┘
```

### KPI Cards (Row 1)

| Measure | Format |
|---|---|
| `[Total Revenue]` | "₹0.0M" |
| `[Revenue Lost]` | "₹0.0M" — red color |
| `[Monthly Revenue Lost]` | "₹0.0K" — red color |
| `[Avg Revenue Per Customer]` | "₹0" |
| `[Revenue Lost %]` | "0.0%" — red if >20% |

### Waterfall Chart: Revenue Flow

**How to build:**
1. Insert → **Waterfall chart**
2. Category: `Customer_Status` (manual sort: Stayed → Churned)
3. Y-axis: `Total_Revenue`
4. Format: Increase=#43D9AD, Decrease=#FF6584, Total=#6C63FF
5. Title: "Revenue Waterfall — Retained vs. Lost"

> **Alternative:** Use a Stacked Bar with `Customer_Status` on Y and `Total_Revenue` on X.

### Scatter: Tenure vs. Monthly Charge (Coloured by Churn)

**How to build:**
1. Insert → **Scatter Chart**
2. X-axis: `Tenure_in_Months`
3. Y-axis: `Monthly_Charge`
4. Legend: `Customer_Status`
5. Size: none (or `Total_Revenue` for bubble)
6. Format → Colors: Churned=#FF6584, Stayed=#43D9AD
7. Format → Markers: Size 6, 70% opacity
8. Add reference lines: X=12 (vertical, yellow dashed), Y=70 (horizontal, red dashed)
9. Title: "Risk Zone: Short Tenure + High Charge = Highest Churn"

### Revenue by Churn Reason Bar

**How to build:**
1. Source: `vw_churn_reasons`
2. Insert → **Clustered bar chart**
3. Y-axis: `Churn_Reason` (Top N filter: Top 10 by `Revenue_Lost`)
4. X-axis: `Revenue_Lost`
5. Format: Color by `Churn_Category` (same color scheme as treemap)
6. Data labels: On, format "₹0K"

### Slicers (Page 4)

| Slicer | Field | Style |
|---|---|---|
| Contract | `Contract` | Button |
| Internet Type | `Internet_Type` | Dropdown |
| Monthly Charge Tier | `Monthly_Charge_Tier` | List |
| State | `State` | Dropdown |

---

## PAGE 5 — Customer Behaviour Dashboard

> **Purpose:** How customers use (or don't use) the product — and how that predicts churn.

### Layout Grid

```
┌──────────────────────────────────────────────────────────┐
│  TITLE: "Customer Behaviour & Engagement Dashboard"      │
├─────────┬─────────┬──────────┬────────────────────────────┤
│Avg Addon│Avg Ref. │Overage % │ Refund %                  │ ← 4 KPIs
├─────────┴─────────┴──────────┴────────────────────────────┤
│                              │                            │
│  LINE+BAR COMBO:             │  BAR: Referral Bucket      │ ← Row 2
│  Addon Count vs Churn Rate   │  vs Churn Rate             │
│  (dual axis)                 │                            │
│                              │                            │
├──────────────────────────────┴────────────────────────────┤
│                              │                            │
│  STACKED BAR:                │  TABLE: Add-on Adoption    │ ← Row 3
│  Addon Adoption per Service  │  by Customer Status        │
│  (% subscribed)              │                            │
│                              │                            │
├──────────────────────────────┴────────────────────────────┤
│  BAR: Churn by Value Deal    │  BAR: Churn by Payment     │ ← Row 4
└─────────────────────────────────────────────────────────-─┘
```

### KPI Cards (Row 1)

```dax
Avg Addon Count = AVERAGE(customer_churn_clean[Addon_Count])

Avg Referrals = AVERAGE(customer_churn_clean[Number_of_Referrals])

Overage Rate % =
DIVIDE([Customers With Overage], [Total Customers]) * 100

Refund Rate % =
DIVIDE([Customers With Refunds], [Total Customers]) * 100
```

### Line + Bar Combo: Addon Stickiness Chart

**How to build:**
1. Source: `vw_addon_stickiness`
2. Insert → **Line and clustered column chart**
3. X-axis: `Addon_Count`
4. Column Y-axis: `Total_Customers` (blue bars)
5. Line Y-axis: `Churn_Rate_Pct` (red line)
6. Format → Line: color #FF6584, width 2.5px, markers on
7. Format → Columns: color #6C63FF, 60% opacity
8. Format → Data labels: On for line values (format "0.0%")
9. Title: "Stickiness Effect: More Add-Ons = Lower Churn"
10. Add annotation text box: *"Each add-on reduces switching cost"*

### Add-On Adoption Stacked Bar

**How to build:**
1. Insert → **Stacked bar chart**
2. Y-axis: Add-on service names (manually create a bridge table or unpivot in Power Query)
3. X-axis: `[Total Customers]`
4. Legend: `Customer_Status`

> **Power Query — Unpivot add-on columns:**
> 1. Transform Data → select `customer_churn_clean`
> 2. Select columns: Online_Security, Online_Backup, Device_Protection_Plan, Premium_Support, Streaming_TV, Streaming_Movies, Streaming_Music
> 3. Transform → **Unpivot Columns**
> 4. Rename: Attribute → `Addon_Name`, Value → `Addon_Status`
> 5. Keep: Customer_ID, Customer_Status, Addon_Name, Addon_Status

### Slicers (Page 5)

| Slicer | Field | Style |
|---|---|---|
| Contract | `Contract` | Button |
| Internet Type | `Internet_Type` | Dropdown |
| Customer Status | `Customer_Status` | Button |
| Tenure Group | `Tenure_Group` | Dropdown |

---

## PAGE 6 — Recommendations Dashboard

> **Purpose:** Actionable intelligence for the retention team. WHO to contact, WHY, and WHAT to offer.

### Layout Grid

```
┌──────────────────────────────────────────────────────────┐
│  TITLE: "Retention Recommendations — Action Dashboard"   │
├────────┬─────────┬──────────────────────────────────────-┤
│Critical│  High   │  Monthly Revenue Saveable             │ ← 3 KPIs
│ Risk   │  Risk   │  (from Critical+High risk stayed)     │
├────────┴─────────┴──────────────────────────────────────-┤
│                                                          │
│  SEGMENT RISK TABLE (vw_segment_risk)                    │ ← Row 2
│  Columns: Contract | Internet | Tenure | Risk | Score   │
│  Conditional format Risk Level column                    │
│                                                          │
├──────────────────────────────────────────────────────────┤
│                              │                            │
│  HIGH-RISK CUSTOMER TABLE    │  BAR: Top Segments by     │ ← Row 3
│  (vw_high_risk_customers)    │  Revenue at Risk          │
│  Filterable by Risk Level    │                            │
│                              │                            │
├──────────────────────────────┴────────────────────────────┤
│  PLAYBOOK SUMMARY TEXT BOX (top 3 triggers and actions)  │ ← Row 4
└──────────────────────────────────────────────────────────┘
```

### KPI Cards (Row 1)

```dax
Critical Risk Customers =
CALCULATE(
    COUNTROWS(vw_high_risk_customers),
    vw_high_risk_customers[Risk_Level] = "Critical"
)

High Risk Customers =
CALCULATE(
    COUNTROWS(vw_high_risk_customers),
    vw_high_risk_customers[Risk_Level] = "High"
)

Saveable Monthly Revenue =
CALCULATE(
    SUM(vw_high_risk_customers[Monthly_Charge]),
    vw_high_risk_customers[Risk_Level] IN {"Critical", "High"}
)
```

### Segment Risk Table (Key Visual)

**How to build:**
1. Source: `vw_segment_risk`
2. Insert → **Table** visual
3. Columns:
   - `Contract`
   - `Internet_Type`
   - `Tenure_Group`
   - `Segment_Size`
   - `Churn_Rate_Pct` ← **Format as data bar** (red gradient)
   - `Risk_Level` ← **Conditional color background**
   - `Monthly_Revenue_At_Risk` ← **Format as ₹ with data bar**
   - `Risk_Score`
4. Format → Risk_Level conditional formatting:
   - Critical = background #FF6584, text white
   - High = background #FF8C69, text white
   - Medium = background #FFD166, text dark
   - Low = background #43D9AD, text dark
5. Sort by `Risk_Score` descending
6. Title: "Customer Segment Risk Scorecard"

### High-Risk Customer Table

**How to build:**
1. Source: `vw_high_risk_customers`
2. Insert → **Table**
3. Columns: `Customer_ID`, `State`, `Contract`, `Internet_Type`, `Tenure_in_Months`, `Monthly_Charge`, `Risk_Flag_Count`, `Risk_Level`
4. Conditional format `Risk_Level` same as above
5. Format `Risk_Flag_Count` with data bars
6. Add slicer: `Risk_Level` (Button style: Critical | High | Medium)
7. Title: "Active Customers Requiring Immediate Retention Action"

> **This table is the retention team's work queue** — they work through it top to bottom each week.

### Top Segments by Revenue at Risk Bar

**How to build:**
1. Source: `vw_segment_risk`
2. Insert → **Clustered bar chart**
3. Y-axis: Concatenate Contract + Internet_Type (create calculated column):
   ```dax
   Segment Label = vw_segment_risk[Contract] & " | " & vw_segment_risk[Internet_Type]
   ```
4. X-axis: `Monthly_Revenue_At_Risk`
5. Color: `Risk_Level` (Critical=red, High=orange, Medium=yellow)
6. Top N filter: Top 8 segments
7. Title: "Revenue at Risk by Segment"

### Playbook Text Box

**How to add:**
1. Insert → **Text Box**
2. Paste formatted text:
```
🔴 CRITICAL ACTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
① MTM + Fiber + <12M + >₹70       → Senior retention call within 48hrs
② Overage charge detected          → Proactive Unlimited Data upgrade offer
③ High-value customer, 0 add-ons   → Free 30-day add-on bundle trial
```
3. Format: Background #1E1E32, border #6C63FF 2px, font Segoe UI 11pt, white text

### Slicers (Page 6)

| Slicer | Field | Style |
|---|---|---|
| Risk Level | `Risk_Level` | Button (Critical/High/Medium) |
| Contract | `Contract` | Dropdown |
| Internet Type | `Internet_Type` | Dropdown |
| State | `State` | Search dropdown |

---

## Cross-Page Settings

### Page Navigation (Tab Bar)

**How to build a custom nav bar:**
1. On every page, insert → **Rectangle** shape (full width, 50px height, top of canvas)
2. Color: #12122A
3. Insert → **Buttons** (Blank) for each page:
   - Page 1: "📊 Executive"
   - Page 2: "👥 Customers"
   - Page 3: "📉 Churn"
   - Page 4: "💰 Revenue"
   - Page 5: "🎯 Behaviour"
   - Page 6: "🚨 Recommendations"
4. Format each button → Action → Type: Page navigation → Destination: [page name]
5. Format → Fill: #1A1A2E (normal), #6C63FF (selected/hover)
6. Format → Font: Segoe UI 10pt, white

### Tooltips (All pages)

**Enable rich tooltips:**
1. Format → Tooltips → Type: Report page
2. Create a dedicated **Tooltip Page** (Page Size: Tooltip preset 320×240)
3. Add mini KPIs: Customer_ID, Churn_Rate, Monthly_Charge, Churn_Reason

### Drill-Through Setup

**Enable drill-through to customer detail:**
1. Create a blank page: "Customer Detail"
2. Add `Customer_ID` to the **Drill-through** filter well on that page
3. Add a Table visual with all columns from `vw_customer_detail`
4. On any page, right-click a data point → Drill-through → Customer Detail

---

## Summary Checklist

```
SETUP
  ☐ MySQL connection established
  ☐ All 9 views imported
  ☐ Theme JSON applied
  ☐ Canvas size set to 1440×900

DAX
  ☐ _Measures table created
  ☐ All 25+ measures added
  ☐ Tenure_Sort column added
  ☐ Segment Label calculated column added

PAGE 1 — Executive
  ☐ 5 KPI cards
  ☐ Customer status donut
  ☐ Churn rate gauge (vs 20% target)
  ☐ Contract + Internet bar charts
  ☐ State map
  ☐ 3 slicers

PAGE 2 — Customers
  ☐ 5 KPI cards
  ☐ Age histogram (with bins)
  ☐ Gender donut
  ☐ Married donut
  ☐ State stacked bar (Top 10)
  ☐ Tenure group chart
  ☐ 4 slicers

PAGE 3 — Churn
  ☐ 4 KPI cards
  ☐ Churn reason treemap
  ☐ Churn by Contract bar
  ☐ Churn by Internet bar
  ☐ Churn by Payment bar
  ☐ Churn by Tenure bar
  ☐ Heatmap matrix (Contract × Internet)
  ☐ 5 slicers

PAGE 4 — Revenue
  ☐ 5 KPI cards
  ☐ Revenue waterfall
  ☐ Revenue donut by status
  ☐ Revenue lost by reason bar
  ☐ Tenure vs Charge scatter (risk zone)
  ☐ Revenue by Contract bar
  ☐ 4 slicers

PAGE 5 — Behaviour
  ☐ 4 KPI cards
  ☐ Addon stickiness combo chart
  ☐ Referral bucket bar
  ☐ Add-on adoption stacked bar (unpivoted)
  ☐ Churn by Value Deal
  ☐ Churn by Payment Method
  ☐ 4 slicers

PAGE 6 — Recommendations
  ☐ 3 KPI cards
  ☐ Segment risk scorecard table
  ☐ High-risk customer table
  ☐ Revenue at risk bar
  ☐ Playbook text box
  ☐ Navigation bar on all pages
  ☐ 4 slicers

FINAL
  ☐ Cross-page navigation bar
  ☐ Drill-through to Customer Detail page
  ☐ Tooltip page created
  ☐ Publish to Power BI Service
```
