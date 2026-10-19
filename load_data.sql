-- Load the raw CSV files into the staging tables
-- Run from the repository folder:  mysql --local-infile=1 -u root -p < load_data.sql
USE used_car_dw;
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'data/us_used_car_listings.csv' INTO TABLE stg_listings
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES
(price, brand, model, year, title_status, mileage, color, vin, lot, state, country, `condition`);

LOAD DATA LOCAL INFILE 'data/epa_vehicles.csv' INTO TABLE stg_epa_vehicles
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES
(epa_id, make, model, year, vehicle_class, alt_fuel_type, fuel_type, combined_mpg, annual_fuel_cost, ev_range_miles);

SELECT 'stg_listings' AS table_name, COUNT(*) AS row_count FROM stg_listings
UNION ALL SELECT 'stg_epa_vehicles', COUNT(*) FROM stg_epa_vehicles;
