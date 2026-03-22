## Datasets

This project uses CSV files as the raw data source for building the data warehouse.

The data is based on a mix of **CRM and ERP systems**, simulating a real-world ETL process.

### Data Sources

**CRM Data:**
- Customer Info  
- Product Info  
- Sales Details  

**ERP Data:**
- Additional supporting files (e.g., categories, locations, and other reference data)

### Data Access

The original datasets are not included in this repository to keep it lightweight and avoid sharing raw data.

If needed, the data structure and samples can be shared separately.

### Usage

The CSV files are loaded into the **Bronze layer** using `BULK INSERT`, then cleaned in the Silver layer, and finally transformed into the Gold layer for reporting and analysis.

To run this project, you can replace the source files with your own CSV files that follow a similar structure.
