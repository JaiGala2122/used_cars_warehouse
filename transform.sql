-- Clean the staging data and build the star schema
-- Run after load_data.sql:  mysql -u root -p used_car_dw < transform.sql
USE used_car_dw;

-- ---------------------------------------------------------------
-- 1. Log rows to remove (a row is logged once, under its first failing rule)
-- ---------------------------------------------------------------
INSERT INTO dq_removed_rows (lot, vin, reason)
SELECT lot, vin,
       CASE
         WHEN country <> 'usa'                                   THEN 'Not a US listing'
         WHEN brand IN ('peterbilt', 'harley-davidson', 'heartland') THEN 'Not a passenger vehicle'
         WHEN price < 100                                        THEN 'Placeholder price (under $100)'
         WHEN mileage = 0 OR mileage > 500000                    THEN 'Implausible mileage'
       END AS reason
FROM stg_listings
WHERE country <> 'usa'
   OR brand IN ('peterbilt', 'harley-davidson', 'heartland')
   OR price < 100
   OR mileage = 0 OR mileage > 500000;

-- Duplicate lots: keep one copy, log the extra copies
INSERT INTO dq_removed_rows (lot, vin, reason)
SELECT lot, vin, 'Duplicate row'
FROM (
    SELECT lot, vin,
           ROW_NUMBER() OVER (PARTITION BY lot ORDER BY lot) AS copy_no
    FROM stg_listings
    WHERE lot NOT IN (SELECT lot FROM dq_removed_rows)
) d
WHERE copy_no > 1;

-- ---------------------------------------------------------------
-- 2. dim_location: state -> US Census region
-- ---------------------------------------------------------------
INSERT INTO dim_location (state, region)
SELECT DISTINCT s.state,
       CASE
         WHEN s.state IN ('connecticut','maine','massachusetts','new hampshire','rhode island','vermont',
                          'new jersey','new york','pennsylvania') THEN 'Northeast'
         WHEN s.state IN ('illinois','indiana','michigan','ohio','wisconsin','iowa','kansas','minnesota',
                          'missouri','nebraska','north dakota','south dakota') THEN 'Midwest'
         WHEN s.state IN ('delaware','florida','georgia','maryland','north carolina','south carolina','virginia',
                          'west virginia','alabama','kentucky','mississippi','tennessee','arkansas','louisiana',
                          'oklahoma','texas','district of columbia') THEN 'South'
         ELSE 'West'
       END
FROM stg_listings s
WHERE s.country = 'usa'
ORDER BY s.state;

-- ---------------------------------------------------------------
-- 3. dim_make_year: EPA specs rolled up to make and model year
--    Listing brands are lowercase and 'land' means Land Rover, so names are normalized for the join.
-- ---------------------------------------------------------------
INSERT INTO dim_make_year (make, year, models_offered, avg_combined_mpg, pct_truck_suv_van,
                           pct_electrified, avg_annual_fuel_cost)
SELECT CASE WHEN LOWER(make) = 'land rover' THEN 'land' ELSE LOWER(make) END AS make,
       year,
       COUNT(*),
       ROUND(AVG(CASE WHEN fuel_type <> 'Electricity' THEN combined_mpg END), 1),
       ROUND(100 * AVG(vehicle_class REGEXP 'Pickup|Sport Utility|Van'), 1),
       ROUND(100 * AVG(alt_fuel_type IN ('Hybrid', 'Plug-in Hybrid', 'EV')), 1),
       ROUND(AVG(annual_fuel_cost), 0)
FROM stg_epa_vehicles
GROUP BY 1, year;

-- ---------------------------------------------------------------
-- 4. fact_listings: rows that passed every rule
-- ---------------------------------------------------------------
INSERT INTO fact_listings (lot, vin, make, year, price, mileage, title_status, color,
                           location_key, make_year_key)
SELECT s.lot, s.vin, s.brand, s.year, s.price, s.mileage, s.title_status, s.color,
       l.location_key, m.make_year_key
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY lot ORDER BY lot) AS copy_no
    FROM stg_listings
) s
JOIN dim_location l       ON l.state = s.state
LEFT JOIN dim_make_year m ON m.make = s.brand AND m.year = s.year
WHERE s.copy_no = 1
  AND s.lot NOT IN (SELECT lot FROM dq_removed_rows WHERE reason <> 'Duplicate row');

-- ---------------------------------------------------------------
-- 5. Summary
-- ---------------------------------------------------------------
SELECT reason, COUNT(*) AS rows_removed
FROM dq_removed_rows
GROUP BY reason
UNION ALL SELECT 'TOTAL REMOVED', COUNT(*) FROM dq_removed_rows
UNION ALL SELECT 'ROWS IN fact_listings', COUNT(*) FROM fact_listings;
