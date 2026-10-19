-- US Used Car Market Warehouse - Analysis and Data Quality Queries (MySQL 8.0+)
-- Run after transform.sql:  mysql -u root -p used_car_dw < example_queries.sql
USE used_car_dw;

-- =====================================================================
-- PART 1: DATA QUALITY CHECKS (run before trusting any result)
-- =====================================================================

-- DQ1. What the raw file contained vs. what made it into the warehouse
SELECT 'Raw listings'               AS step, COUNT(*) AS row_count FROM stg_listings
UNION ALL SELECT 'Removed by cleaning rules', COUNT(*) FROM dq_removed_rows
UNION ALL SELECT 'Clean listings in fact table', COUNT(*) FROM fact_listings;

-- DQ2. Why rows were removed
SELECT reason, COUNT(*) AS rows_removed
FROM dq_removed_rows
GROUP BY reason
ORDER BY rows_removed DESC;

-- DQ3. The 'condition' column is mislabeled: it holds auction time left, not vehicle condition
SELECT `condition` AS condition_value, COUNT(*) AS listings
FROM stg_listings
GROUP BY `condition`
ORDER BY listings DESC
LIMIT 5;

-- DQ4. The 'model' column is unreliable: its most common values are not model names
SELECT model, COUNT(*) AS listings
FROM stg_listings
GROUP BY model
ORDER BY listings DESC
LIMIT 5;

-- DQ5. How many clean listings matched EPA specs on make and model year
SELECT COUNT(*)                                        AS clean_listings,
       SUM(make_year_key IS NOT NULL)                  AS matched_to_epa,
       ROUND(100 * AVG(make_year_key IS NOT NULL), 2)  AS match_rate_pct
FROM fact_listings;

-- DQ6. Brand concentration: is the sample balanced?
SELECT make, COUNT(*) AS listings,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_listings
FROM fact_listings
GROUP BY make
ORDER BY listings DESC
LIMIT 6;


-- =====================================================================
-- PART 2: ANALYSIS QUERIES
-- =====================================================================

-- Q1. Median price by title status (MySQL has no PERCENTILE_CONT, so the median uses ROW_NUMBER and COUNT)
WITH ranked AS (
    SELECT title_status, price,
           ROW_NUMBER() OVER (PARTITION BY title_status ORDER BY price) AS rn,
           COUNT(*)     OVER (PARTITION BY title_status)                AS n
    FROM fact_listings
)
SELECT title_status,
       MAX(n)               AS listings,
       ROUND(AVG(price), 0) AS median_price
FROM ranked
WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2))
GROUP BY title_status;


-- Q2. Depreciation curve: median price by vehicle age (clean titles only)
--     Age is measured from 2020, the newest model year in the data.
WITH aged AS (
    SELECT CASE WHEN 2020 - year >= 8 THEN '8+' ELSE CAST(2020 - year AS CHAR) END AS age_years,
           LEAST(2020 - year, 8) AS sort_key,
           price
    FROM fact_listings
    WHERE title_status = 'clean vehicle'
),
ranked AS (
    SELECT age_years, sort_key, price,
           ROW_NUMBER() OVER (PARTITION BY age_years ORDER BY price) AS rn,
           COUNT(*)     OVER (PARTITION BY age_years)                AS n
    FROM aged
),
medians AS (
    SELECT age_years, sort_key, MAX(n) AS listings, ROUND(AVG(price), 0) AS median_price
    FROM ranked
    WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2))
    GROUP BY age_years, sort_key
)
SELECT age_years, listings, median_price,
       ROUND(100 * (median_price / LAG(median_price) OVER (ORDER BY sort_key) - 1), 1) AS pct_change_vs_one_year_newer
FROM medians
ORDER BY sort_key;


-- Q3. Median price by mileage band (clean titles only)
WITH banded AS (
    SELECT CASE WHEN mileage < 25000  THEN '1: under 25K'
                WHEN mileage < 50000  THEN '2: 25K-50K'
                WHEN mileage < 100000 THEN '3: 50K-100K'
                WHEN mileage < 150000 THEN '4: 100K-150K'
                ELSE '5: 150K+' END AS mileage_band,
           price
    FROM fact_listings
    WHERE title_status = 'clean vehicle'
),
ranked AS (
    SELECT mileage_band, price,
           ROW_NUMBER() OVER (PARTITION BY mileage_band ORDER BY price) AS rn,
           COUNT(*)     OVER (PARTITION BY mileage_band)                AS n
    FROM banded
)
SELECT mileage_band, MAX(n) AS listings, ROUND(AVG(price), 0) AS median_price
FROM ranked
WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2))
GROUP BY mileage_band
ORDER BY mileage_band;


-- Q4. Price by US region, and each state's rank within its region (states with 20+ clean listings)
WITH state_prices AS (
    SELECT l.region, l.state,
           COUNT(*)               AS listings,
           ROUND(AVG(f.price), 0) AS avg_price
    FROM fact_listings f
    JOIN dim_location l ON l.location_key = f.location_key
    WHERE f.title_status = 'clean vehicle'
    GROUP BY l.region, l.state
    HAVING COUNT(*) >= 20
)
SELECT region, state, listings, avg_price,
       RANK() OVER (PARTITION BY region ORDER BY avg_price DESC) AS rank_in_region,
       ROUND(AVG(avg_price) OVER (PARTITION BY region), 0)      AS region_avg_of_states
FROM state_prices
ORDER BY region, rank_in_region;


-- Q5. Brand comparison: price, mileage, and the brand's EPA lineup for those model years
--     (brands with 30+ clean listings)
SELECT f.make,
       COUNT(*)                        AS listings,
       ROUND(AVG(f.price), 0)          AS avg_price,
       ROUND(AVG(f.mileage), 0)        AS avg_mileage,
       ROUND(AVG(2020 - f.year), 1)    AS avg_age_years,
       ROUND(AVG(m.avg_combined_mpg), 1)  AS lineup_avg_mpg,
       ROUND(AVG(m.pct_truck_suv_van), 1) AS lineup_pct_truck_suv_van
FROM fact_listings f
LEFT JOIN dim_make_year m ON m.make_year_key = f.make_year_key
WHERE f.title_status = 'clean vehicle'
GROUP BY f.make
HAVING COUNT(*) >= 30
ORDER BY avg_price DESC;


-- Q6. Does a brand's fuel economy relate to price? Pearson r computed in SQL
--     (clean titles, model years 2015-2020, matched to EPA)
SELECT COUNT(*) AS listings,
       ROUND((AVG(f.price * m.avg_combined_mpg) - AVG(f.price) * AVG(m.avg_combined_mpg))
             / (STDDEV_POP(f.price) * STDDEV_POP(m.avg_combined_mpg)), 3) AS r_price_vs_lineup_mpg,
       ROUND((AVG(f.price * f.mileage) - AVG(f.price) * AVG(f.mileage))
             / (STDDEV_POP(f.price) * STDDEV_POP(f.mileage)), 3)          AS r_price_vs_mileage,
       ROUND((AVG(f.price * f.year) - AVG(f.price) * AVG(f.year))
             / (STDDEV_POP(f.price) * STDDEV_POP(f.year)), 3)             AS r_price_vs_year
FROM fact_listings f
JOIN dim_make_year m ON m.make_year_key = f.make_year_key
WHERE f.title_status = 'clean vehicle' AND f.year BETWEEN 2015 AND 2020;
