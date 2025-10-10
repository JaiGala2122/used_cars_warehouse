
-- Vehicle Data Warehouse - Schema Definition (MySQL)

CREATE DATABASE IF NOT EXISTS vehicle_dw;
USE vehicle_dw;

CREATE TABLE dim_vehicle (
    vehicle_key INT PRIMARY KEY,
    make VARCHAR(64),
    model VARCHAR(128),
    year INT,
    engine VARCHAR(64),
    fuel_type VARCHAR(64)
);

CREATE TABLE fact_sales_listings (
    listing_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    vehicle_key INT,
    price DECIMAL(10,2),
    mileage INT,
    state VARCHAR(32),
    listed_at DATETIME,
    INDEX idx_sales_vehicle (vehicle_key),
    FOREIGN KEY (vehicle_key) REFERENCES dim_vehicle(vehicle_key)
);

CREATE TABLE fact_maintenance (
    maint_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    vehicle_key INT,
    component VARCHAR(64),
    dtc_code VARCHAR(32),
    cost DECIMAL(10,2),
    needs_maintenance TINYINT,
    event_date DATE,
    INDEX idx_maint_vehicle (vehicle_key),
    FOREIGN KEY (vehicle_key) REFERENCES dim_vehicle(vehicle_key)
);

CREATE TABLE fact_telematics (
    telem_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    vehicle_key INT,
    ts DATETIME,
    speed DOUBLE,
    rpm DOUBLE,
    energy_kwh DOUBLE,
    INDEX idx_telem_vehicle (vehicle_key),
    FOREIGN KEY (vehicle_key) REFERENCES dim_vehicle(vehicle_key)
);
