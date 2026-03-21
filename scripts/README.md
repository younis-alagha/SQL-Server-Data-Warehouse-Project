# SQL Server Data Warehouse Project

## Overview
This project builds a data warehouse using SQL Server with a layered architecture:

- Bronze: Raw data loading from CSV files
- Silver: Data cleaning and transformation
- Gold: Business-ready views for analysis

## Architecture
CSV Files → Bronze → Silver → Gold

## Technologies
- SQL Server
- BULK INSERT
- Stored Procedures
- Views

## How to Run

1. Run `01_create_database_and_bronze_tables.sql`
2. Run `02_load_bronze.sql`
3. Run `03_create_silver_tables.sql`
4. Run `EXEC silver.load_silver`
5. Run `05_create_gold_views.sql`

## Example Queries

```sql
SELECT TOP 10 * FROM gold.dim_customers;
SELECT TOP 10 * FROM gold.dim_products;
SELECT TOP 10 * FROM gold.fact_sales;
