# Decoding-Attrition-A-Data-Driven-Revenue-Risk-Customer-Retention-Intelligence-Framework

## 📌Project Overview
An e-commerce company with 450,000 customers was experiencing a ~24.96% churn rate, putting over ₹1.1 billion in annual revenue at risk.
This project delivers a complete, end to end churn intelligence system, from raw CSV files to an interactive Power BI dashboard and a machine learning prediction 
model using a SQL-first, analytics engineering approach.

## Table of Contents
1. [Background and Overview](#1-background-and-overview)
2. [Data Structure Overview](#2-data-structure-overview)
3. [Executive Summary](#3-executive-summary)
4. [Insights Deep Dive](#4-insights-deep-dive)
5. [Recommendations](#5-recommendations)

## 1. Background and Overview

### Business Context

In the competitive e-commerce landscape, customer acquisition is expensive but retention is where profitability is built. This project addresses a critical business challenge: **identifying which customers are about to leave, understanding why, and quantifying the revenue at stake before it walks out the door.**

The company operates across **5 major Indian metros** (Mumbai, Bangalore, Delhi, Pune, Hyderabad), serves customers acquired through **3 channels** (Organic, Referral, Ads), and processes orders across **5 product categories** (Beauty, Electronics, Home, Sports, Fashion).

### Problem Statement

With no structured churn monitoring in place, the business lacked answers to its most critical questions:
- Which customers are at imminent risk of churning?
- How much revenue is tied to customers who are leaving?
- What behavioral and transactional signals predict churn before it happens?
- Where should retention budget be focused for maximum impact?

### Project Objective

Design and deliver a **complete, end-to-end churn intelligence system** that:

1. Identifies high risk churn customers using behavioral and transactional signals
2. Quantifies the revenue impact of churn in concrete monetary terms
3. Uncovers the root drivers of churn across demographics, behavior, and experience
4. Provides actionable, data-backed retention strategies by customer risk tier
5. Deploys a machine learning model to score churn probability for every active customer

## 2. Data Structure Overview

### Dataset Summary

This project integrates **three relational datasets** totaling **1.35 million rows** of customer, transactional, and behavioral data.

| Table | Rows | Columns | Grain |
|---|---|---|---|
| `customers_table.csv` | 450,000 | 8 | One row per customer |
| `orders_final.csv` | 450,000 | 8 | One row per order |
| `activity_final.csv` | 450,000 | 6 | One row per customer |


### Entity Relationship Diagram

```
┌─────────────────────┐         ┌──────────────────────┐
│     customers       │         │        orders        │
│─────────────────────│         │──────────────────────│
│ customer_id (PK)  ──┼──1───*──┤ order_id (PK)        │
│ signup_date         │         │ customer_id (FK)      │
│ gender              │         │ order_date            │
│ age                 │         │ order_value           │
│ city                │         │ product_category      │
│ acquisition_channel │         │ payment_method        │
│ is_active           │         │ order_status          │
│ churn_flag ★        │         │ discount_used        │
└────────┬────────────┘         └──────────────────────┘
         │
         │ 1-to-1
         │
┌────────▼────────────┐
│      activity       │
│─────────────────────│
│ activity_id (PK)    │
│ customer_id (FK)    │
│ last_login_days     │
│ session_count       │
│ last_purchase_days  │
│ email_click_rate    │
└─────────────────────┘
```

**Relationships:**
- `customers` → `orders`: **One-to-Many** (one customer can have multiple orders)
- `customers` → `activity`: **One-to-One** (one activity record per customer)
- All joins use **LEFT JOIN** to preserve customers with zero orders — a critical design choice, as zero-order customers are among the highest churn risk

---

### The customer_360 View (Core Analytical Model)

All three tables are unified into a single `customer_360` analytical view — one row per customer, combining demographics, transaction metrics, experience signals, and behavioral data.


## 3. Executive Summary

### Headline Numbers

| Metric | Value |
|---|---|
| Total Customers Analyzed | 450,000 |
| **Overall Churn Rate** | **24.96%** |
| **Total Churned Customers** | **112,325** |
| Total Completed Revenue | ₹3,620,694,118 |
| **Revenue Lost to Churn** | **₹903,141,758** (~₹90.3 Crore) |
| Avg Revenue per Churned Customer | ₹8,040 |
| Customers Who Never Ordered | 165,565 (36.8%) |
| Discount Usage Rate | 40.0% of all orders |
| Avg Days Since Last Login | 181.8 days |

---

### The Scale of the Problem

> **1 in 4 customers churns.** That translates to ₹90.3 Crore in lost completed order revenue, revenue that walked out the door and is now being spent with a competitor.

Beyond direct revenue loss, each churned customer represents a wasted acquisition cost. At an estimated ₹500 per acquired customer across 112,325 churned customers, that's an additional **₹5.6 Crore in stranded acquisition spend.**

---

### Where Churn is Coming From —> At a Glance

| Dimension | Highest Churn Segment | Churn Rate |
|---|---|---|
| Acquisition Channel | Referral | 24.99% |
| City | Hyderabad | 25.09% |
| Age Group | 18–25 | 25.07% |
| Product Category | Beauty | 25.14% |
| Order Experience | Zero orders placed | ~100% likely |

> ⚠️ **Notable finding:** Churn rates are remarkably uniform across all demographic splits (within 0.3–0.5% of each other). This tells us that churn is **not driven by who the customer is** it's driven by **what happened to them** after signup. The real drivers are behavioral and experiential.

---

### Revenue Breakdown

| Revenue Type | Amount (₹) | Share |
|---|---|---|
| Completed Orders —> Retained Customers | ~₹2,717,552,360 | 75.1% |
| Completed Orders —> Churned Customers | ₹903,141,758 | 24.9% |
| Revenue Leakage (Returns) | ₹456,982,874 | — |
| Revenue Leakage (Cancellations) | ₹447,304,097 | — |

**Total revenue leakage from returns + cancellations alone: ₹90.4 Crore** — nearly equal to the churn revenue loss, representing a separate but related problem.

---

## 4. Insights Deep Dive

### Insight 1: The Zero Order Problem, Biggest Silent Churn Segment

```
Customers who never placed a single order: 165,565 (36.8% of all customers)
These customers signed up but never converted, they are functionally churned from Day 1.
```

**What this means:** Over a third of the customer base represents pure acquisition waste. The onboarding funnel is broken, customers are being acquired but not activated. This is not a retention problem; it's an activation problem that masquerades as churn.

**Business implication:** Fix the first 7 day onboarding journey before spending more on re-engagement. Every rupee spent on re-activating non-purchasers costs more than activating them would have originally.

---

### Insight 2: Behavioral Disengagement Precedes Churn, But the Signal Window is Wide

| Login Recency Segment | Customers | Churn Rate |
|---|---|---|
| Active (≤30 days) | ~112,000 | 24.83% |
| At Risk (31–90 days) | ~112,000 | 25.13% |
| Disengaged (91–180 days) | ~112,000 | 24.91% |
| Dormant (180+ days) | ~112,000 | 24.95% |

**What this means:** The near uniform churn rate across login segments is a critical finding it reveals that **churn in this dataset is not concentrated in a specific activity window.** Customers are churning across all engagement levels, which points to a **structural issue with retention mechanics** rather than a timing problem.

**Business implication:** Standard "re engage dormant users" campaigns alone will not solve this. The root cause is earlier in the lifecycle likely post-first-purchase experience, product quality, or value perception.

---

### Insight 3: Product Category - Beauty Leads in Both Revenue and Churn Risk

| Product Category | Churn Rate | Completed Revenue |
|---|---|---|
| Beauty | 25.14% | ₹ Highest |
| Electronics | 25.04% | High |
| Fashion | 24.85% | Mid |
| Home | 24.88% | Mid |
| Sports | 24.77% | ₹ Lowest |

**What this means:** Beauty is both the highest-revenue category and the highest churn category. Beauty purchases are inherently repeat purchase driven (consumables), making retention critical in this category specifically.

**Business implication:** Beauty customers who don't reorder within 60–90 days of their first purchase are at high churn risk. Trigger automated replenishment reminders for Beauty category buyers.

---

### Insight 4: Revenue Leakage is a Hidden Second Crisis

```
Returns Revenue:       ₹456,982,874
Cancellations Revenue: ₹447,304,097
─────────────────────────────────────
Total Leakage:         ₹904,286,971
```

**What this means:** Revenue leakage from returns and cancellations is nearly **equal in size to the churn revenue loss.** These are two parallel crises happening simultaneously.

**Business implication:** Any revenue recovery strategy must address both. Cancellations at ₹44.7 Crore suggest checkout friction or second thought behavior, this warrants abandoned cart and checkout UX analysis.

---

## 5. Recommendations

### Risk Tier Framework

Every customer is classified into one of four risk tiers based on their behavioral and transactional profile:

| Tier | Definition | Customer Count (est.) |
|---|---|---|
| 🔴 Critical | Never ordered OR 180+ days inactive | ~165,000+ |
| 🟠 High | 60–180 days inactive, 1–2 orders | ~75,000 |
| 🟡 Medium | 30–60 days inactive, showing discount dependency | ~80,000 |
| 🟢 Low | Active, regular purchases, high engagement | ~130,000 |

---

### The Retention Business Case

```
Investment Required (estimated):
  Re-engagement campaign (High + Critical tier): ₹150 per customer × 240,000 = ₹3.6 Crore
  VIP program setup and ongoing cost:             ₹200 per customer × 130,000 = ₹2.6 Crore
  Total Retention Investment:                                                    ₹6.2 Crore

Projected Return (conservative 10% success rate on at-risk tiers):
  Retained revenue from 10% of High + Critical:  24,000 customers × ₹8,040 = ₹19.3 Crore
  Preserved revenue from Low tier protection:     retain 95% of ₹ top segment

Net ROI: ₹19.3 Crore return on ₹6.2 Crore investment = 3.1× ROI
```

> Every ₹1 spent on retention generates ₹3.10 in preserved revenue compared to ₹3.33 cost to acquire a replacement customer with no revenue guarantee.

---

### Summary of Strategic Priorities

| Priority | Action | Timeline | Impact |
|---|---|---|---|
| 1 | Fix zero order onboarding funnel | Week 1–2 | Highest 36.8% of base |
| 2 | Launch 7-day activation campaign for non-purchasers | Week 2–3 | ₹66 Crore revenue opportunity |
| 3 | Deploy re-engagement campaign for 60–180 day inactive | Week 3–4 | Recover High tier customers |
| 4 | Launch VIP program for Low tier customers | Month 2 | Protect top revenue base |
| 5 | Integrate churn_probability scores into Power BI alerts | Month 2–3 | Ongoing monitoring system |
| 6 | Audit returns & cancellations process | Month 2 | Recover ₹90 Crore leakage |

---
