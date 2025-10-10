# Vehicle Data Warehouse - SQL Project

A SQL-focused portfolio project demonstrating advanced database design and analytical queries using public vehicle datasets.

## 🎯 Project Overview

This project showcases SQL skills through:
- Star schema design for analytical queries
- Complex SQL with CTEs, window functions, and joins
- Real-world business questions answered with data

## 📊 Database Schema

**Tables:**
- `dim_vehicle` - Vehicle specifications (make, model, year, engine, fuel)
- `fact_sales_listings` - Used car listings with price and mileage
- `fact_maintenance` - Service records and component failures  
- `fact_telematics` - Real-time vehicle sensor data

## 🔍 Sample Queries

This project includes 5 complex SQL queries demonstrating:
1. Median price analysis with mileage stratification
2. Reliability vs. market value correlation
3. Telemetry efficiency calculations
4. Monthly maintenance trends using window functions
5. Vehicle ranking by market demand

See `example_queries.sql` for full implementations.

## 🛠️ SQL Skills Demonstrated

- Star schema design with proper indexing
- CTEs for readable, maintainable queries
- Window functions (LAG, ROW_NUMBER, PERCENTILE_CONT)
- JOIN operations across multiple tables
- Aggregations with GROUP BY and HAVING
- NULL handling and data quality checks

## 🚀 Quick Start
```sql
-- Create the database
CREATE DATABASE vehicle_dw;
USE vehicle_dw;

-- Run schema
SOURCE schema.sql;

-- Try the example queries
SOURCE example_queries.sql;
