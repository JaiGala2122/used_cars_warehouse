# US Used Car Market Warehouse - SQL Project

A MySQL star schema built from 2,499 real US used-car auction listings and 41,804 EPA vehicle records, with SQL cleaning, data quality checks and price analysis.

**Full write-up, results and charts:** [galajainam.com](https://www.galajainam.com/projects/vehicle-analytics/index.html)

## 🎯 Project Overview

This project shows SQL skills through:
- Loading raw files into staging tables, then cleaning them in SQL
- Designing a star schema with location and make-year dimensions
- Joining listings to EPA fuel-economy specs
- Answering pricing questions with CTEs and window functions

## 📦 Dataset

- **Used car listings:** [US Cars dataset](https://raw.githubusercontent.com/stat-lu/dataviz/main/data/us_cars.csv) - 2,499 auction listings with price, mileage, model year, title status and state (originally published on Kaggle, scraped from AUCTION EXPORT)
- **Vehicle specs:** [EPA fuel economy data](https://github.com/rfordatascience/tidytuesday/tree/master/data/2019/2019-10-15) - 41,804 vehicle configurations, 1984–2020, from fueleconomy.gov

## ⚙️ How It Works

1. `schema.sql` - creates the `used_car_dw` database: staging tables, dimensions, fact table and a cleaning log
2. `load_data.sql` - loads both CSV files into staging, untouched
3. `transform.sql` - cleans the data and builds the star schema:
   - removes placeholder prices, non-US and non-passenger listings, impossible mileage and duplicates
   - logs every removed row, and the reason, in `dq_removed_rows`
   - maps states to US Census regions
   - rolls the EPA data up to one row per make and model year
4. `example_queries.sql` - 6 data quality checks and 6 analysis queries

## 🛠️ Skills Demonstrated

- Staging → clean → star schema workflow in SQL
- Data cleaning rules with a logged audit trail
- CTEs and window functions (ROW_NUMBER, RANK, LAG, COUNT/SUM/AVG OVER)
- Median without PERCENTILE_CONT (MySQL)
- Pearson correlation computed in SQL
- Joining two public datasets on make and model year

## 🚀 Quick Start

```bash
mysql -u root -p < schema.sql
mysql --local-infile=1 -u root -p < load_data.sql
mysql -u root -p used_car_dw < transform.sql
mysql -u root -p used_car_dw < example_queries.sql
```

Needs MySQL 8.0+. Run the commands from the repository folder so `load_data.sql` can find `data/`.

## 📁 Files

```
schema.sql            Tables, keys and indexes
load_data.sql         Loads the raw CSV files
transform.sql         Cleaning rules and star schema build
example_queries.sql   Data quality checks and analysis queries
data/                 Raw listings and EPA data
```
