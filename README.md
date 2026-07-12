# 🔍 Customer Churn Intelligence System

> **From prediction to prevention — a full-stack business analytics solution that doesn't just identify churn, it stops it.**

![Python](https://img.shields.io/badge/Python-3.10%2B-3776AB?style=for-the-badge&logo=python&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-Dashboard-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![ML](https://img.shields.io/badge/ML-XGBoost%20%7C%20SHAP-FF6F00?style=for-the-badge&logo=scikit-learn&logoColor=white)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)

---

## 📌 The Problem

A company is **losing customers** — and doesn't know why.

Most analytics projects stop at *"here's a churn prediction model."* This project goes further:


---

## 🗺️ Project Architecture

```
Customer Churn Intelligence System
│
├── 📊 Data Layer (SQL)
│   ├── Raw customer transactions
│   ├── Feature engineering queries
│   └── Monthly cohort aggregations
│
├── 🧠 Analytics Layer (Python)
│   ├── Exploratory Data Analysis
│   ├── Churn Prediction Model (XGBoost)
│   ├── SHAP-based Root Cause Analysis
│   └── Churn Playbook Rule Engine
│
└── 📈 Visualization Layer (Power BI)
    ├── Executive Churn Dashboard
    ├── Customer Segment Drilldown
    └── Playbook Action Tracker
```

---

## ⚡ Key Features

### 1. 📅 Time-Series Churn Trend Analysis
- Monthly churn rate tracking with rolling averages
- Seasonal churn pattern detection
- Cohort retention curves (when did customers leave?)

### 2. 👥 Customer Segmentation
- **New vs. Returning** customers — do they churn for different reasons?
- **High-value vs. Low-value** tiers — who costs the most to lose?
- Behavioral clustering with unsupervised ML

### 3. 🛠️ Feature Usage Analytics
- Which product features correlate with **staying**?
- Which feature gaps predict **leaving**?
- Inactivity duration as a leading indicator

### 4. 🔮 Churn Prediction Model
- **Algorithm:** XGBoost Classifier (tuned with Optuna)
- **Explainability:** SHAP values for every prediction
- **Metrics:**
  - AUC-ROC: *~0.91*
  - Precision: *~0.84*
  - Recall: *~0.79*
  - F1 Score: *~0.81*

### 5. 🔍 Root Cause Analysis
Unlike generic models, this system **explains WHY** a customer is about to churn:
- SHAP waterfall plots per customer
- Top churn drivers by segment
- Feature importance ranked by business impact (not just model weight)

---

## 📋 The Churn Playbook

> The most critical part of this project — automated actions triggered by churn signals.

| Trigger Condition | Customer Segment | Action |
|---|---|---|
| Inactive ≥ 7 days | All | 📧 Send reminder email |
| Churn score > 0.75 | High-value (top 20%) | 🧑‍💼 Assign dedicated support agent |
| Feature usage < 2 in 14 days | New customers (< 30 days) | 🎓 Trigger onboarding sequence |
| 2 failed logins + open support ticket | Any | 🔧 Proactive tech outreach |
| Churn score > 0.85 + renewal in 30 days | High-value | 💰 Offer discount or upgrade incentive |
| No purchase in 60 days | Mid-value | 📊 Send personalized usage report |

---

## 🗂️ Project Structure

```
customer-churn-intelligence/
│
├── 📁 data/
│   ├── raw/                        # Raw customer datasets
│   ├── processed/                  # Cleaned & feature-engineered data
│   └── exports/                    # Model outputs for Power BI
│
├── 📁 sql/
│   ├── 01_schema.sql               # Database schema setup
│   ├── 02_feature_engineering.sql  # Churn signal features
│   ├── 03_cohort_analysis.sql      # Monthly cohort queries
│   └── 04_segment_profiles.sql     # Customer segment profiling
│
├── 📁 notebooks/
│   ├── 01_EDA.ipynb                # Exploratory Data Analysis
│   ├── 02_feature_engineering.ipynb
│   ├── 03_churn_model.ipynb        # Model training & evaluation
│   ├── 04_root_cause_analysis.ipynb   # SHAP analysis
│   └── 05_playbook_engine.ipynb    # Rule engine simulation
│
├── 📁 src/
│   ├── data_pipeline.py            # ETL pipeline
│   ├── feature_store.py            # Feature computation
│   ├── model.py                    # Model training & inference
│   ├── explainer.py                # SHAP-based explanation
│   └── playbook.py                 # Churn Playbook rule engine
│
├── 📁 powerbi/
│   ├── ChurnDashboard.pbix         # Main Power BI report
│   └── screenshots/                # Dashboard preview images
│
├── 📁 reports/
│   ├── churn_analysis_report.pdf
│   └── playbook_effectiveness.pdf
│
├── requirements.txt
├── config.yaml
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- Python 3.10+
- PostgreSQL 14+ (or any SQL-compatible database)
- Power BI Desktop (for `.pbix` file)
- Git

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/customer-churn-intelligence.git
cd customer-churn-intelligence
```

### 2. Set Up Python Environment

```bash
python -m venv venv
source venv/bin/activate        # macOS/Linux
venv\Scripts\activate           # Windows

pip install -r requirements.txt
```

### 3. Configure the Database

```bash
# Copy and edit configuration
cp config.yaml.example config.yaml

# Update database credentials in config.yaml
# Then run schema setup
psql -U postgres -d churn_db -f sql/01_schema.sql
```

### 4. Load Data & Run Feature Engineering

```bash
python src/data_pipeline.py --mode full
```

### 5. Run the Full Analysis

```bash
# Option A: Notebooks (recommended for exploration)
jupyter lab

# Option B: Run scripts directly
python src/model.py --train
python src/explainer.py --generate-shap
python src/playbook.py --simulate
```

### 6. Open Power BI Dashboard

Open `powerbi/ChurnDashboard.pbix` in Power BI Desktop and refresh data sources.

---

## 🧰 Tech Stack

| Layer | Tool | Purpose |
|---|---|---|
| **Data Storage** | PostgreSQL | Customer data warehouse |
| **Data Processing** | Python / Pandas | ETL & feature engineering |
| **Machine Learning** | XGBoost + Scikit-learn | Churn prediction |
| **Explainability** | SHAP | Root cause analysis |
| **Hyperparameter Tuning** | Optuna | Model optimization |
| **Visualization** | Matplotlib / Seaborn | EDA plots |
| **BI Dashboard** | Power BI | Executive reporting |

---

## 📊 Dashboard Preview

The Power BI dashboard includes:
- 📉 **Monthly Churn Trend** — line chart with annotations for business events
- 🎯 **At-Risk Customer Table** — live list filtered by churn score threshold
- 🗂️ **Segment Comparison** — new vs. returning, low vs. high value
- 🧩 **Feature Usage Heatmap** — which features drive retention
- 📋 **Playbook Status Tracker** — how many customers are in each action bucket

---

## 📈 Leading Indicators of Churn

Based on analysis, these signals most strongly predict churn (ranked by SHAP impact):

| Rank | Feature | Business Meaning |
|---|---|---|
| 1 | `days_since_last_login` | Inactivity is the #1 predictor |
| 2 | `num_features_used_30d` | Low feature adoption = high risk |
| 3 | `support_tickets_open` | Unresolved issues drive exit |
| 4 | `billing_failure_count` | Payment friction = churn signal |
| 5 | `days_to_contract_renewal` | At-risk window near renewal |
| 6 | `monthly_spend_trend` | Declining usage before cancelling |
| 7 | `nps_score` | Sentiment predicts behavior |

---

## 🔬 Root Cause Analysis Methodology

This project uses **SHAP (SHapley Additive exPlanations)** to move beyond "black box" prediction:

```
For each at-risk customer:
  ↓
  SHAP Waterfall Plot generated
  → Shows exactly WHICH features pushed them toward churn
  → Quantifies contribution of each feature in dollars of LTV risk
  ↓
  Root causes bucketed into categories:
  → Engagement  (low usage, inactivity)
  → Support     (open tickets, billing issues)
  → Value       (feature mismatch, price sensitivity)
  → Lifecycle   (onboarding failure, renewal window)
  ↓
  Matching Playbook action triggered automatically
```

---

## 📐 Data Model

```sql
-- Core tables used in the analysis
customers          -- Demographics, tier, signup date
events             -- Product usage logs (feature-level)
subscriptions      -- Plan, billing, renewal dates
support_tickets    -- Support interactions
nps_responses      -- Customer satisfaction scores
churn_labels       -- Ground truth (churned Y/N + date)
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add: your feature description'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

## 👤 Author

**[Your Name]**
- 📧 Email: your.email@example.com
- 💼 LinkedIn: [linkedin.com/in/yourprofile](https://linkedin.com/in/yourprofile)
- 🐙 GitHub: [github.com/yourusername](https://github.com/yourusername)

---

## ⭐ If this project helped you, please give it a star!

> *"Most people only build models — this project solves a real business problem."*

---

<div align="center">

**Built with ❤️ using SQL · Python · Power BI**

</div>
