## Project Description

This project builds a complete data warehouse using SQL Server to transform raw CSV data into structured, business-ready insights.

### Data Layers

The data moves through three layers:

- **Bronze** → stores raw data exactly as it is  
- **Silver** → cleans and standardizes the data  
- **Gold** → organizes data into a star schema for reporting and analysis  

The goal is to simulate a real ETL process by loading, cleaning, and transforming data step by step instead of jumping straight into analysis.

In the end, the data is ready to answer business questions like sales trends, customer behavior, and product performance.

---

## Data Source

The project uses CSV files as the raw data source (customers, products, sales, etc.).

These files are stored in a location accessible by SQL Server, especially when running through Docker.

---

## Database Setup

A SQL Server database is used (local or Docker).

The database is organized into three schemas:

- `bronze` → raw data  
- `silver` → cleaned data  
- `gold` → final reporting layer  

---

## Bronze Layer (Raw Data)

- Tables match the source files exactly  
- Data is loaded using `BULK INSERT`  
- No transformations are applied  
- Tables are truncated before each load  

This layer acts as a raw backup of the source data.

---

## Silver Layer (Data Cleaning)

- Data is cleaned and standardized  
- Handles:
  - Missing values  
  - Incorrect formats  
  - Duplicate records  
- Applies basic business rules  

This is where the data becomes usable.

---

## Gold Layer (Analytics)

- Data is structured into a star schema  
- Includes:
  - Fact table (sales)  
  - Dimension tables (customers, products, etc.)  
- Built using views for flexibility  

This layer is designed for reporting and analysis.

---

## ETL Process

The pipeline runs in three steps:

1. Load raw data into Bronze  
2. Transform data into Silver  
3. Query final data from Gold  

Stored procedures are used to manage and control the process.

---

## Data Validation

Basic checks are included to ensure data quality:

- Row count comparisons  
- Missing values  
- Duplicate detection  
- Consistency between layers  

---

## Final Output

At the end of the process:

- Data is clean and structured  
- The Gold layer is ready for analysis  
- Queries can be used to analyze sales trends, customer behavior, and product performance  
