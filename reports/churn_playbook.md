# 📘 Customer Churn Playbook
### Telecom Customer Retention Strategy — India Market
> Built from: SQL Analysis · Python EDA · Root Cause Analysis · 6,419 Customer Records

---

## How to Use This Playbook

This playbook translates data findings into **executable retention actions**. Every strategy is backed by a specific data finding. Every action has a measurable business outcome.

```
DATA FINDING  →  TRIGGER CONDITION  →  ACTION  →  EXPECTED OUTCOME
```

---

## Part 1 — Churn Landscape: The Full Picture

### Overall Business Health

| Metric | Value | Benchmark | Status |
|---|---|---|---|
| Churn Rate | ~27% | Industry: 15–25% | 🔴 Above Benchmark |
| Month-to-Month Churn Rate | ~45–50% | — | 🔴 Critical |
| Fiber Optic Churn Rate | Highest tier | — | 🟠 High Risk |
| Revenue Lost to Churn | Significant | — | 🔴 Action Required |
| Customers at Risk (MTM, Active) | High count | — | 🟠 Immediate Focus |

### The 5 Root Causes (Ranked by Volume)

```
┌─────────────────────────────────────────────────────────────┐
│  RANK  │  ROOT CAUSE     │  % CHURN  │  PRIMARY TRIGGER     │
├────────┼─────────────────┼───────────┼──────────────────────┤
│   1    │  Competitor     │  ~45%     │  Better offer/speed  │
│   2    │  Dissatisfaction│  ~17%     │  Network/product gap │
│   3    │  Attitude       │  ~15%     │  Bad support exp.    │
│   4    │  Price          │  ~12%     │  Overage/LD charges  │
│   5    │  Other          │  ~11%     │  Unknown/mixed       │
└─────────────────────────────────────────────────────────────┘
```

---

## Part 2 — Trigger-Action Decision Trees

> These are the executable workflows for the retention team. Each trigger fires automatically (CRM/alert system) and routes to the correct action.

---

### 🔴 TRIGGER 1: Month-to-Month Customer — No Activity Signal

```
Customer on Month-to-Month contract
            │
            ▼
    Tenure < 6 months?
     ┌──── YES ────┐         ┌──── NO ────┐
     ▼             ▼         ▼            ▼
 Monthly        Monthly   Monthly      Monthly
Charge > ₹70  Charge ≤70  Charge >70  Charge ≤70
     │             │         │            │
     ▼             ▼         ▼            ▼
 🔴 CRITICAL    🟠 HIGH   🟠 HIGH      🟡 MEDIUM
 (See Action 1A) (1B)      (1C)         (1D)
```

**Action 1A — Critical New High-Spender (MTM + <6M + >₹70)**
- **Who contacts:** Senior Retention Specialist (not automated)
- **Channel:** Phone call within 48 hours
- **Offer:** 20% discount on first year of annual contract
- **Message:** *"As a valued new customer, we'd like to lock in your current rate for 12 months with an exclusive loyalty offer."*
- **Fallback:** If no answer → WhatsApp message + email with offer link

**Action 1B — New Low-Spender (MTM + <6M + ≤₹70)**
- **Who contacts:** Automated CRM + Follow-up by junior agent
- **Channel:** Email + In-app notification
- **Offer:** Free add-on trial for 30 days (Online Security or Backup)
- **Message:** *"Explore what you're missing — try [Add-On] free for 30 days."*

**Action 1C — Established High-Spender (MTM + >6M + >₹70)**
- **Who contacts:** Account Manager
- **Channel:** Phone call + personalized email
- **Offer:** Annual contract with 2 months free + speed upgrade
- **Message:** *"You've been with us for [X] months. Here's a loyalty reward — upgrade to annual and get 2 months on us."*

**Action 1D — Established Low-Spender (MTM + >6M + ≤₹70)**
- **Who contacts:** Automated email sequence (3-email drip)
- **Channel:** Email
- **Offer:** Bundle upgrade — add streaming/security for reduced price
- **Expected Outcome:** Contract conversion rate 15–25%

---

### 🟠 TRIGGER 2: Customer Receives Overage (Extra Data) Charge

```
Total_Extra_Data_Charges > ₹0 detected on billing cycle
            │
            ▼
    Unlimited_Data = 'No'?
            │ YES
            ▼
    Customer_Status = 'Stayed'?
            │ YES
            ▼
    Monthly_Charge > ₹60?
     ┌──── YES ────┐
     ▼             ▼
 High-value    Standard
   (2A)          (2B)
```

**Action 2A — High-Value Customer with Overage**
- **Timing:** Within 24 hours of overage charge
- **Who contacts:** Dedicated support agent (proactive outbound call)
- **Offer:** Immediate upgrade to Unlimited Data — waive first month's upgrade fee
- **Message:** *"We noticed you went over your data limit. We've applied a one-time credit and would love to move you to our Unlimited plan at no extra cost this month."*
- **Why this works:** Overage is a known churn trigger (RCA Finding #5). Getting ahead of the complaint converts a negative experience into a loyalty moment.

**Action 2B — Standard Customer with Overage**
- **Timing:** Same day as overage via automated alert
- **Channel:** SMS + App notification
- **Offer:** Discounted Unlimited Data upgrade (10% off first 3 months)
- **Message:** *"You've hit your data limit. Upgrade to Unlimited for just ₹[X]/month — no more surprise charges."*

---

### 🟡 TRIGGER 3: Customer Has Zero Add-On Services

```
Customer on Internet Service with Addon_Count = 0
            │
            ▼
    Tenure_in_Months < 12?
            │ YES
            ▼
    Internet_Type = 'Fiber Optic'?
     ┌──── YES ────┐
     ▼             ▼
 🔴 URGENT      🟠 HIGH
   (3A)           (3B)
```

**Action 3A — Fiber Optic Customer with No Add-Ons (<12M)**
- **Why urgent:** This is the exact profile that shows the highest churn rate in the dataset
- **Channel:** In-app + Email + SMS (multi-touch)
- **Offer:** "Starter Bundle" — Online Security + Online Backup for ₹99/month (bundled discount)
- **Message:** *"Protect what matters. Get Online Security + Cloud Backup bundled — only ₹99/month. Your first 30 days are on us."*
- **Goal:** Move Addon_Count from 0 → 2 (raises switching cost significantly)

**Action 3B — Other Internet Customer with No Add-Ons (<12M)**
- **Channel:** Email onboarding sequence (weekly, 4 weeks)
- **Week 1:** Introduce Online Security
- **Week 2:** Introduce Cloud Backup
- **Week 3:** Introduce Streaming bundle
- **Week 4:** Combined offer with discount
- **Message tone:** Educational, not sales. *"Here's what customers like you are using to get more from their plan."*

---

### 🔵 TRIGGER 4: High-Value Customer Shows Disengagement Signal

```
Customer_Status = 'Stayed'
AND Monthly_Charge > ₹80 (High Value)
AND ANY of:
  - Number_of_Referrals = 0
  - Addon_Count ≤ 1
  - Contract = 'Month-to-Month'
            │
            ▼
    Assign to VIP Retention Team
            │
            ▼
    Schedule proactive outreach
            │
            ▼
    Conduct "Value Check-In" call
```

**Action 4 — VIP Retention Call**
- **Timing:** Quarterly (every 90 days) for all high-value MTM customers
- **Who contacts:** Named Account Manager (same person each time)
- **Agenda:**
  1. "How is everything going with your service?"
  2. "Are there any features you haven't explored yet?"
  3. "We have an exclusive loyalty offer for customers like you..."
- **Offer pool (pick one based on conversation):**
  - Contract upgrade with 3 months free
  - Speed upgrade at current price
  - Premium Support activation (free for 6 months)
  - Referral bonus (₹500 credit per referral)
- **Expected Outcome:** Reduce churn in this segment by 30–40%

---

### 🟣 TRIGGER 5: Customer Contacts Support (Attitude Risk)

```
Customer raises a support ticket
OR
Customer contacts service provider
            │
            ▼
    Was issue resolved in first contact?
     ┌──── NO ────┐
     ▼            ▼
Escalate to   Standard
 Senior (5A)  follow-up (5B)
            │
            ▼
    Monthly_Charge > ₹60?
     ┌──── YES ────┐
     ▼             ▼
 Assign VIP   Standard
  agent (5C)  queue (5D)
```

**Action 5A — Unresolved Escalation**
- **Timing:** Flag immediately when first-contact resolution fails
- **Assign:** Senior support specialist (different from original agent)
- **SLA:** Callback within 2 hours
- **Post-resolution:** Send follow-up satisfaction survey 24 hours later
- **If satisfaction < 4/5:** Trigger a retention offer automatically

**Action 5B — Standard Resolution Follow-Up**
- **Timing:** 48 hours after issue resolved
- **Channel:** SMS/WhatsApp
- **Message:** *"We hope your issue was resolved. How would you rate your experience? (1–5)"*
- **If rating < 4:** Auto-trigger Action 5A escalation path

**Action 5C — High-Value Customer with Unresolved Issue**
- **Priority:** Highest (P0 for retention)
- **Action:** CEO/Director-level apology + service credit
- **Offer:** 1 month free service credit + Premium Support upgrade
- **Message tone:** Personal, apologetic, empowered

---

### 🟤 TRIGGER 6: Customer Has Low Feature Usage (Onboarding Gap)

```
Internet_Service = 'Yes'
AND Addon_Count = 0
AND Tenure_in_Months BETWEEN 1 AND 3
            │
            ▼
    Low feature usage in first 90 days
            │
            ▼
    Launch Product Onboarding Sequence
```

**Action 6 — 90-Day Onboarding Journey**

```
Day 1:   Welcome email + "Getting started" guide
Day 7:   "Did you know?" — Feature highlight (Online Security)
Day 14:  Usage tip — how to monitor your data usage
Day 21:  "Customers like you also use..." — Backup recommendation
Day 30:  Check-in: "How's your experience so far?" (NPS micro-survey)
Day 45:  Streaming add-on introduction (if no streaming subscribed)
Day 60:  Referral program introduction ("Share and earn ₹500")
Day 90:  Contract upgrade offer — "Lock in your rate for a year"
```

**Why this matters (data evidence):** Customers in the 0–6 month window have the highest churn rate. Every engagement touchpoint during this period increases tenure probability.

---

### ⚫ TRIGGER 7: Contract Renewal / Expiry Alert

```
Contract = 'One Year' OR 'Two Year'
AND Tenure approaching renewal window (±30 days)
            │
            ▼
    Start renewal campaign 45 days before expiry
            │
            ▼
    Monthly_Charge > ₹70?
     ┌──── YES ────┐
     ▼             ▼
 VIP renewal    Standard
  offer (7A)    offer (7B)
```

**Action 7A — VIP Contract Renewal**
- **Day -45:** Personalized email from Account Manager
  - *"Your plan renews in 45 days. As a valued customer, here's your exclusive renewal offer."*
- **Day -30:** Phone call from retention specialist
- **Offer:** Renew for 2 years → get 3 months free + free speed upgrade
- **Day -15:** Final reminder with countdown urgency
- **Day -7:** Last-chance message: *"Your offer expires in 7 days"*

**Action 7B — Standard Contract Renewal**
- **Day -30:** Automated email with renewal offer (10% off annual)
- **Day -15:** Follow-up with add-on bundle discount
- **Day -7:** Final reminder

---

## Part 3 — Customer Segment Strategies

### Segment Map

```
                    HIGH MONTHLY CHARGE
                           │
          ┌────────────────┼────────────────┐
          │                │                │
    Long Tenure      Medium Tenure    Short Tenure
    (36M+)           (13-36M)         (0-12M)
          │                │                │
    🟢 LOYAL          🟡 AT-RISK       🔴 CRITICAL
    Advocate           Middle           Churn Zone
    Program            Ground
          │                │                │
    Low Churn          Moderate         Highest
     Rate               Risk             Risk
          │
          ▼
    LOW MONTHLY CHARGE (Phone-only / DSL customers)
```

---

### Segment 1: 🔴 CRITICAL — New High-Value (0–12M + >₹70/month)
> **Data:** Highest churn rate in the dataset. Fiber Optic + Month-to-Month.

| Attribute | Value |
|---|---|
| Contract | Month-to-Month |
| Tenure | 0–12 Months |
| Internet | Fiber Optic or Cable |
| Monthly Charge | > ₹70 |
| Add-Ons | 0–1 |

**Strategy:** Rapid relationship building + switching cost creation

| Action | Timeline | Owner |
|---|---|---|
| Assign named Account Manager | Day 1 of signup | Onboarding team |
| 30-day free add-on bundle trial | Day 7 | Automated CRM |
| Personal check-in call | Day 30 | Account Manager |
| Contract upgrade offer | Day 60 | Senior Retention |
| Referral program invitation | Day 90 | Marketing |

**Target KPI:** Reduce churn from ~50% to <30% within 6 months

---

### Segment 2: 🟠 AT-RISK — Established MTM (>12M + Month-to-Month)
> **Data:** Long enough to have value, no contract lock-in. At risk from any competitor offer.

| Attribute | Value |
|---|---|
| Contract | Month-to-Month |
| Tenure | 12+ Months |
| Addon Count | 1–3 |
| Referrals | 0–3 |

**Strategy:** Contract conversion + deepened product engagement

| Action | Timeline | Owner |
|---|---|---|
| Annual loyalty offer (proactive) | Quarterly | Retention Team |
| Add-on stickiness campaign | Monthly | Marketing |
| Referral incentive program | Ongoing | Marketing |
| Speed/feature upgrade offer | At billing cycle | Automated |

**Target KPI:** Convert 25% of MTM customers to annual contracts quarterly

---

### Segment 3: 🟡 ADVOCACY — Loyal Long-Term (36M+ + Any Contract)
> **Data:** These customers have the lowest churn rate and highest referral counts. Protect and leverage them.

| Attribute | Value |
|---|---|
| Tenure | 36+ Months |
| Referrals | 5+ |
| Addon Count | 3+ |

**Strategy:** Turn loyalty into advocacy. Protect at all costs.

| Action | Timeline | Owner |
|---|---|---|
| VIP loyalty program enrollment | Immediate | Account Management |
| Annual appreciation gift/reward | Yearly | Customer Success |
| Early access to new features | Ongoing | Product Team |
| Referral multiplier reward | Per referral | Marketing |
| Direct line to senior support | Permanent | Support |

**Target KPI:** Maintain churn rate < 5%. Generate 3+ referrals per advocate.

---

### Segment 4: 🟢 GROWTH — New Joiners (Customer_Status = 'Joined')
> **Data:** Recently acquired. No churn label yet. Critical 90-day window.

**Strategy:** Maximize time-to-value. Build habits before competitors approach.

| Action | Timeline | Owner |
|---|---|---|
| Welcome call within 24 hours | Day 1 | Onboarding |
| Feature activation check | Day 7 | CRM Automated |
| First billing experience management | Day 30 | Support |
| Add-on discovery campaign | Day 14–45 | Marketing |
| First contract upgrade offer | Day 60 | Retention |

**Target KPI:** Achieve Addon_Count ≥ 2 within 90 days for >60% of new joiners.

---

## Part 4 — Business Impact Projections

### If We Reduce Churn Rate from 27% to 20%:

| Metric | Current (27%) | Target (20%) | Improvement |
|---|---|---|---|
| Customers Retained Extra | Baseline | +~450 customers | +~450/cycle |
| Monthly Revenue Protected | Baseline | Significant uplift | Measurable |
| Annual Revenue Impact | Baseline | Material increase | ROI positive |
| Cost of Retention vs. Acquisition | Lower | Even lower | Efficient |

> **Key insight:** Retaining one customer costs 5–7× less than acquiring a new one. A 7-point reduction in churn rate generates significant ROI from retention programs alone.

### ROI Formula for Each Retention Action

```
ROI = (Customers Saved × Avg Monthly Charge × 12 months)
      ─────────────────────────────────────────────────────
             Cost of Retention Program
```

**Example for Action 1A (Critical New High-Spender):**
- Target segment: ~300 customers
- Conversion rate (5% → 30%): Save ~75 customers
- Avg Monthly Charge of this segment: ~₹90
- Annual revenue saved: 75 × ₹90 × 12 = **₹81,000**
- Cost of dedicated specialist program: ~₹20,000/quarter
- **Net ROI per quarter: ~₹61,000 (305% ROI)**

---

## Part 5 — KPIs to Track

### Retention KPIs (Monthly Dashboard)

| KPI | Definition | Target | Alert Threshold |
|---|---|---|---|
| Overall Churn Rate | % of active customers who left | < 20% | > 25% |
| MTM → Annual Conversion Rate | % of MTM customers converting monthly | > 5% | < 2% |
| New Customer 90-Day Retention | % of joined customers still active at Day 90 | > 80% | < 70% |
| Addon Attachment Rate | % of internet customers with ≥2 add-ons | > 50% | < 35% |
| First Contact Resolution Rate | Support tickets resolved on first contact | > 85% | < 75% |
| VIP Customer Churn Rate | Churn among Monthly Charge > ₹80 | < 5% | > 10% |
| Revenue at Risk (MTM Active) | Sum of Monthly_Charge for all MTM stayed | Monitor | — |
| Referral Rate | Avg referrals per active customer | > 5 | < 2 |

### Campaign-Level KPIs

| Campaign | Primary KPI | Secondary KPI |
|---|---|---|
| Contract Upgrade (Action 1) | Conversion rate % | Avg contract value |
| Overage Intervention (Action 2) | Churn rate of treated group | Unlimited upgrade rate |
| Add-On Onboarding (Action 3) | Addon_Count at Day 30 | 90-day retention rate |
| VIP Outreach (Action 4) | VIP churn rate | Referral increase |
| Support Recovery (Action 5) | Post-resolution CSAT | 30-day churn rate |
| Onboarding Journey (Action 6) | Day-90 retention | Addon_Count at Day 90 |
| Contract Renewal (Action 7) | Renewal rate | Upsell to 2-year rate |

---

## Part 6 — 90-Day Implementation Roadmap

### Month 1 — Foundation

```
Week 1–2:
  ✅ Set up CRM triggers for all 7 decision trees
  ✅ Define high-risk customer list (MTM + <12M + >₹70)
  ✅ Brief retention team on playbook workflows
  ✅ Create email/SMS templates for Actions 1A–1D

Week 3–4:
  ✅ Launch Action 2 (Overage Auto-Alert) in CRM
  ✅ Launch Action 6 (New Customer Onboarding Journey)
  ✅ Begin VIP customer identification for Action 4
  ✅ Train support team on Action 5 escalation paths
```

### Month 2 — Activation

```
Week 5–6:
  ✅ Launch contract upgrade campaigns (Action 1 full rollout)
  ✅ Start first batch of VIP quarterly calls (Action 4)
  ✅ Launch Action 3 (Add-On Discovery Campaign)
  ✅ Begin tracking all 8 Retention KPIs

Week 7–8:
  ✅ First campaign performance review
  ✅ A/B test offer variants (discount % vs. free months)
  ✅ Identify contract renewal pipeline (Action 7)
  ✅ Launch referral bonus program
```

### Month 3 — Optimise

```
Week 9–10:
  ✅ Analyse first-month campaign results
  ✅ Double down on highest-ROI triggers
  ✅ Refine customer segment boundaries based on results
  ✅ Expand add-on trial offers based on Addon_Count data

Week 11–12:
  ✅ Full playbook review with leadership
  ✅ Update RCA analysis with new churner data
  ✅ Set Quarter 2 churn rate target
  ✅ Publish Month 3 Retention Dashboard
```

---

## Part 7 — Quick Reference Card

> Print this. Post it at the retention team's desk.

```
┌─────────────────────────────────────────────────────────────────┐
│              CHURN PLAYBOOK — QUICK REFERENCE                   │
├──────────────────────────────────────┬──────────────────────────┤
│  TRIGGER                             │  ACTION                  │
├──────────────────────────────────────┼──────────────────────────┤
│  MTM + Tenure <6M + Charge >₹70     │  🔴 Senior call 48hrs    │
│  MTM + Any + No add-ons             │  🟠 Add-on trial offer   │
│  Overage charge detected             │  🟡 Unlimited upgrade    │
│  Support escalation (unresolved)     │  🟣 Senior + credit      │
│  High-value customer, 0 referrals   │  🔵 VIP quarterly call   │
│  New customer, Day 7, low usage     │  🟤 Feature onboarding   │
│  Contract renewal in 45 days        │  ⚫ Renewal campaign      │
│  Fiber Optic + MTM + <12M tenure    │  🔴 URGENT outreach      │
├──────────────────────────────────────┼──────────────────────────┤
│  NEVER let these happen:             │                          │
│  • Overage charge with no contact   │  → Guaranteed churn      │
│  • Unresolved support ticket        │  → Attitude churn        │
│  • MTM renewal with no offer        │  → Silent departure      │
│  • New customer with no onboarding  │  → Day-90 exit           │
└──────────────────────────────────────┴──────────────────────────┘
```

---

*Playbook Version 1.0 — Customer Churn Analysis Project*  
*Data Source: Customer_Data.csv | Analysis: SQL + Python | Visualisation: Power BI*
