-- US Used Car Market Warehouse - Schema (MySQL 8.0+)
-- Staging tables hold the raw files as-is; the star schema holds cleaned data.

DROP DATABASE IF EXISTS used_car_dw;
CREATE DATABASE used_car_dw;
USE used_car_dw;

-- ---------------------------------------------------------------
-- Staging (raw, untouched copies of the source files)
-- ---------------------------------------------------------------
CREATE TABLE stg_listings (
    price         INT,
    brand         VARCHAR(64),
    model         VARCHAR(64),
    year          INT,
    title_status  VARCHAR(32),
    mileage       INT,
    color         VARCHAR(64),
    vin           VARCHAR(32),
    lot           BIGINT,
    state         VARCHAR(64),
    country       VARCHAR(32),
    `condition`   VARCHAR(32)      -- holds auction time left, not vehicle condition
);

CREATE TABLE stg_epa_vehicles (
    epa_id            INT PRIMARY KEY,
    make              VARCHAR(64),
    model             VARCHAR(128),
    year              INT,
    vehicle_class     VARCHAR(64),
    alt_fuel_type     VARCHAR(32),
    fuel_type         VARCHAR(32),
    combined_mpg      INT,
    annual_fuel_cost  INT,
    ev_range_miles    INT
);

-- ---------------------------------------------------------------
-- Dimensions
-- ---------------------------------------------------------------
CREATE TABLE dim_location (
    location_key  INT AUTO_INCREMENT PRIMARY KEY,
    state         VARCHAR(64) NOT NULL UNIQUE,
    region        VARCHAR(16) NOT NULL       -- US Census region
);

CREATE TABLE dim_make_year (
    make_year_key        INT AUTO_INCREMENT PRIMARY KEY,
    make                 VARCHAR(64) NOT NULL,
    year                 INT NOT NULL,
    models_offered       INT,                 -- EPA model/engine configurations that year
    avg_combined_mpg     DECIMAL(5,1),        -- gasoline and diesel only
    pct_truck_suv_van    DECIMAL(5,1),        -- share of configurations that are trucks, SUVs or vans
    pct_electrified      DECIMAL(5,1),        -- hybrid, plug-in hybrid or EV
    avg_annual_fuel_cost INT,
    UNIQUE KEY uq_make_year (make, year)
);

-- ---------------------------------------------------------------
-- Fact
-- ---------------------------------------------------------------
CREATE TABLE fact_listings (
    listing_key    INT AUTO_INCREMENT PRIMARY KEY,
    lot            BIGINT NOT NULL UNIQUE,
    vin            VARCHAR(32) NOT NULL,
    make           VARCHAR(64) NOT NULL,
    year           INT NOT NULL,
    price          INT NOT NULL,
    mileage        INT NOT NULL,
    title_status   VARCHAR(32) NOT NULL,
    color          VARCHAR(64),
    location_key   INT NOT NULL,
    make_year_key  INT NULL,                  -- NULL when EPA has no match for the make and year
    FOREIGN KEY (location_key)  REFERENCES dim_location(location_key),
    FOREIGN KEY (make_year_key) REFERENCES dim_make_year(make_year_key),
    INDEX idx_make_year (make, year),
    INDEX idx_location (location_key)
);

-- ---------------------------------------------------------------
-- Cleaning log: every raw row that was removed, and why
-- ---------------------------------------------------------------
CREATE TABLE dq_removed_rows (
    lot     BIGINT,
    vin     VARCHAR(32),
    reason  VARCHAR(64)
);
