
# 🚗 Vehicle Data Warehouse – SQL Project

A hands-on **SQL data warehouse project** built entirely with public vehicle datasets to showcase advanced database design, query optimization, and analytics skills.

This project focuses purely on **SQL** — no external ETL tools — just data modeling, normalization, and analytical querying.

---

## 🎯 Project Overview

The aim is to demonstrate how structured query language (SQL) alone can drive insights from raw, multi-source automotive data.

**Key Goals:**
- Design a clean, query-optimized **star schema**
- Write and explain advanced analytical SQL queries
- Provide business-driven insights using real data

---

## 🧱 Schema Design

**Dimension:**
- `dim_vehicle` – make, model, year, engine, and fuel type

**Facts:**
- `fact_sales_listings` – used car listings (price, mileage, state, listing date)  
- `fact_maintenance` – maintenance/repair logs with diagnostic codes  
- `fact_telematics` – speed, RPM, energy use from vehicle sensors

**Highlights:**
- Surrogate key: `vehicle_key`
- Nullable FKs for public datasets with incomplete keys
- Indexes for faster lookups (`vehicle_key`, `make, model, year`)

---

## 🧠 SQL Query Examples

Each query answers a business question while demonstrating a core SQL technique.

### 1️⃣ Median Price by Model-Year & Mileage Bucket
```sql
WITH priced AS (
  SELECT
    CONCAT(make, ' ', model) AS model_name,
    year,
    price,
    CASE
      WHEN mileage < 25000 THEN '<25k'
      WHEN mileage < 50000 THEN '25-50k'
      WHEN mileage < 100000 THEN '50-100k'
      ELSE '100k+'
    END AS mileage_bucket
  FROM fact_sales_listings
  WHERE price IS NOT NULL
)
SELECT model_name, year, mileage_bucket,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median_price
FROM priced
GROUP BY model_name, year, mileage_bucket
ORDER BY year DESC, model_name;
```
**Shows:** use of CTE + percentiles to analyze market depreciation.

---

### 2️⃣ Reliability vs. Market Value
```sql
WITH price_median AS (
  SELECT make, model, year,
         PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median_price
  FROM fact_sales_listings
  GROUP BY make, model, year
),
maint_rate AS (
  SELECT make, model, year,
         AVG(needs_maintenance) AS maintenance_rate
  FROM fact_maintenance
  GROUP BY make, model, year
)
SELECT p.make, p.model, p.year, p.median_price, m.maintenance_rate
FROM price_median p
JOIN maint_rate m USING (make, model, year)
ORDER BY maintenance_rate DESC;
```
**Shows:** correlation analysis using multiple CTEs.

---

### 3️⃣ Telemetry Efficiency Analysis
```sql
SELECT
  series_id,
  ROUND(SUM(energy_kwh) / NULLIF(SUM(speed),0), 4) AS energy_per_km
FROM fact_telematics
WHERE ts BETWEEN '2024-05-01' AND '2024-06-01'
GROUP BY series_id
ORDER BY energy_per_km DESC;
```
**Shows:** NULL handling and aggregated efficiency metrics.

---

### 4️⃣ Monthly Maintenance Trends
```sql
SELECT
  component,
  DATE_FORMAT(event_date, '%Y-%m') AS month,
  COUNT(*) AS events,
  LAG(COUNT(*)) OVER (PARTITION BY component ORDER BY DATE_FORMAT(event_date, '%Y-%m')) AS prev_month,
  COUNT(*) - LAG(COUNT(*)) OVER (PARTITION BY component ORDER BY DATE_FORMAT(event_date, '%Y-%m')) AS change
FROM fact_maintenance
GROUP BY component, DATE_FORMAT(event_date, '%Y-%m')
ORDER BY component, month;
```
**Shows:** window functions for trend analysis.

---

### 5️⃣ Top Vehicles by Demand
```sql
SELECT
  make, model, year,
  COUNT(*) AS listings,
  ROUND(AVG(price), 0) AS avg_price,
  ROW_NUMBER() OVER (PARTITION BY year ORDER BY COUNT(*) DESC) AS rank_in_year
FROM fact_sales_listings
GROUP BY make, model, year
HAVING COUNT(*) > 20
ORDER BY year DESC, rank_in_year;
```
**Shows:** ranking and aggregation.

---

## ⚙️ SQL Skills Highlighted

- Complex queries using **CTEs**, **aggregations**, **window functions**
- **Star schema** design and relational joins
- Performance optimization with **indexes**
- Handling **NULLs** and incomplete keys safely
- Translating business logic into data insights

---

## 🚀 Why This Project Stands Out

✅ 5 complex, real-world analytical queries  
✅ Star schema with optimized indexing  
✅ Every query answers a real business question  
✅ Built entirely in SQL (no code dependencies)  
✅ Designed for analytics interviews and portfolios

---

## 📄 License

All datasets are open source (Kaggle, GitHub, Mendeley, Data.gov).  
Project is MIT Licensed.

---

## 👨‍💻 Author

**Jainam Gala** — MBA in Business Analytics  
Focused on SQL, Data Modeling, and Analytical Storytelling.  

🔗 [LinkedIn](https://www.linkedin.com/in/jainamgala21) | [GitHub](https://github.com/Jeetjad24)
