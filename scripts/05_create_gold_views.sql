/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Purpose:
    Create final business-ready views in the Gold layer for reporting,
    analytics, and dashboarding.

Description:
    The Gold layer is divided into two parts:

    1. Gold Core Layer:
       Contains structured dimension and fact views used as the foundation
       for analytics.

       - gold.dim_customers
       - gold.dim_products
       - gold.dim_date
       - gold.fact_sales

    2. Gold Business Layer:
       Contains aggregated and analytical views that answer key business
       questions and support decision-making.

       - gold.vw_sales_summary        (monthly performance)
       - gold.vw_sales_trend          (growth & trend analysis)
       - gold.vw_product_performance  (product-level performance)
       - gold.vw_category_performance (category-level contribution)
       - gold.vw_customer_value       (customer value & behavior)

Execution Examples:
    -- Core Views
    SELECT * FROM gold.dim_customers;
    SELECT * FROM gold.dim_products;
    SELECT * FROM gold.dim_date;
    SELECT * FROM gold.fact_sales;

    -- Business Views
    SELECT * FROM gold.vw_sales_summary;
    SELECT * FROM gold.vw_sales_trend;
    SELECT * FROM gold.vw_product_performance;
    SELECT * FROM gold.vw_category_performance;
    SELECT * FROM gold.vw_customer_value;

Key Business Questions Answered:
- How is sales performing over time?
- Which products and categories drive revenue and profit?
- What share of the business does each category contribute?
- Which customers generate the most value?

===============================================================================
*/

USE TrailForgeDW;
GO

EXEC bronze.load_bronze
GO

EXEC silver.load_silver
GO
-- =============================================================================
-- Create view: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id              AS customer_id,
    ci.cst_key             AS customer_number,
    ci.cst_firstname       AS first_name,
    ci.cst_lastname        AS last_name,
    ci.cst_firstname + ' ' + ci.cst_lastname AS full_name,
    CASE
    WHEN UPPER(
            LTRIM(RTRIM(
                REPLACE(REPLACE(REPLACE(REPLACE(la.cntry, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')
            ))
         ) IN ('US', 'USA', 'UNITEDSTATES', 'UNITED STATES')
    THEN 'United States'

    WHEN UPPER(
            LTRIM(RTRIM(
                REPLACE(REPLACE(REPLACE(REPLACE(la.cntry, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')
            ))
         ) IN ('DE', 'GERMANY')
    THEN 'Germany'

    WHEN NULLIF(
            UPPER(
                LTRIM(RTRIM(
                    REPLACE(REPLACE(REPLACE(REPLACE(la.cntry, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')
                ))
            ),
            ''
         ) IS NULL
    THEN 'Unknown'

    ELSE LTRIM(RTRIM(
            REPLACE(REPLACE(REPLACE(REPLACE(la.cntry, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')
         ))
END AS country,
    ci.cst_marital_status  AS marital_status,
    CASE
        WHEN ci.cst_gndr <> 'N/A' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'N/A')
    END                    AS gender,
    ca.bdate               AS birth_date,
    ci.cst_create_date     AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;
GO


-- =============================================================================
-- Create view: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
    pn.prd_id            AS product_id,
    pn.prd_key           AS product_number,
    pn.prd_nm            AS product_name,
    pn.cat_id            AS category_id,
    isnull(pc.cat, 'N/A')   AS category,
    pc.subcat            AS subcategory,
    pc.maintenance       AS maintenance,
    pn.prd_cost          AS cost,
    pn.prd_line          AS product_line,
    pn.prd_start_dt      AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;
GO


-- =============================================================================
-- Create view: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num       AS order_number,
    pr.product_key       AS product_key,
    cx.customer_key      AS customer_key,
    ISNULL(sd.sls_order_dt, '1990-01-01')     AS order_date,
    sd.sls_quantity      AS quantity,
    sd.sls_price         AS unit_price,
    sd.sls_sales         AS revenue,
    pr.cost              AS unit_cost,
    pr.cost * sd.sls_quantity AS total_cost,
    sd.sls_sales - (pr.cost * sd.sls_quantity) AS profit,
    (sd.sls_sales - (pr.cost * sd.sls_quantity)) * 1.0 / NULLIF(sd.sls_sales, 0) AS margin_pct

FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cx
    ON sd.sls_cust_id = cx.customer_id;;
GO

-- =============================================================================
-- Create view: gold.dim_date
-- =============================================================================
IF OBJECT_ID ('gold.dim_date' , 'V') IS NOT NULL
    DROP VIEW gold.dim_date
GO

CREATE OR ALTER VIEW gold.dim_date AS
SELECT DISTINCT
    order_date AS full_date,
    YEAR(order_date) AS year,
    DATEPART(QUARTER, order_date) AS quarter,
    MONTH(order_date) AS month,
    DATENAME(MONTH, order_date) AS month_name,
    DATEPART(WEEK, order_date) AS week,
    DATENAME(WEEKDAY, order_date) AS day_name,
    CAST(FORMAT(order_date, 'yyyyMMdd') AS INT) AS date_key
FROM gold.fact_sales;
GO

-- =============================================================================
-- Create view: gold.vw_sales_summary
-- =============================================================================
IF OBJECT_ID ('gold.vw_sales_summary','V') IS NOT NULL
    DROP VIEW gold.vw_sales_summary;
GO

CREATE OR ALTER VIEW gold.vw_sales_summary AS 
SELECT
    YEAR(s.order_date) AS year,
    MONTH(s.order_date) AS month,
    d.month_name AS month_name,
    SUM(s.revenue) AS total_revenue,
    SUM(s.quantity) AS total_units_sold,
    COUNT(DISTINCT s.order_number) AS total_orders,
    SUM(s.revenue) * 1.0 / COUNT(DISTINCT s.order_number) AS avg_order_value -- total revenue / distinct orders
FROM gold.fact_sales s
JOIN gold.dim_date d
    ON s.order_date = d.full_date
GROUP BY
    YEAR(s.order_date),
    MONTH(s.order_date),
    d.month_name;
GO

-- =============================================================================
-- Create view: gold.vw_sales_trend
-- =============================================================================
IF OBJECT_ID ('gold.vw_sales_trend','V') IS NOT NULL
    DROP VIEW gold.vw_sales_trend
GO

CREATE OR ALTER VIEW gold.vw_sales_trend AS
SELECT
    year,
    month,
    month_name,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY year,month) AS previous_month_revenue,
    total_revenue - LAG(total_revenue) OVER (ORDER BY year,month) as revenue_change,
    (total_revenue - LAG(total_revenue) OVER (ORDER BY year,month)) *1.0
        / NULLIF(LAG(total_revenue) OVER (ORDER BY year,month),0) as revenue_growth_pct
FROM gold.vw_sales_summary
GO

-- =============================================================================
-- Create view: GOLD.vw_product_performance
-- =============================================================================
IF OBJECT_ID('gold.vw_product_performance','V') IS NOT NULL
    DROP VIEW gold.vw_product_performance
GO

CREATE OR ALTER VIEW gold.vw_product_performance AS 
SELECT
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.product_line,
    p.cost,
    sum(f.revenue) as total_revenue,
    sum(f.quantity) as total_units_sold,
    sum(f.profit) as total_profit,
    sum(f.profit)*1.0/nullif(sum(f.revenue),0) as margin_pct,
    sum(f.revenue)*1.0/nullif(sum(f.quantity),0) AS avg_selling_price
 from gold.fact_sales f
 join gold.dim_products p on p.product_key = f.product_key
 group by  
     p.product_key,
     p.product_name,
     p.category,
     p.subcategory,
     p.product_line,
     p.cost
GO

-- =============================================================================
-- Create view: gold.vw_category_performance
-- =============================================================================
IF OBJECT_ID('gold.vw_category_performance','V') IS NOT NULL
    DROP VIEW gold.vw_category_performance;
GO 

CREATE OR ALTER VIEW gold.vw_category_performance AS

with category_summary as(
SELECT
    p.category,
    sum(f.revenue) as total_revenue,
    sum(f.quantity) as total_units_sold,
    sum(f.profit) as total_profit
 from gold.fact_sales f
 join gold.dim_products p on p.product_key = f.product_key
 group by  
     p.category
),

company_total as (
select  
    sum(revenue) as total_company_rev
from gold.fact_sales
)

select 
    cs.category,
    cs.total_revenue,
    cs.total_units_sold,
    cs.total_profit,
    cs.total_profit *1.0 / nullif(cs.total_revenue,0) as margin_pct,
    cs.total_revenue *1.0 / nullif(ct.total_company_rev,0) as sale_share_pct
from category_summary cs
cross join company_total ct
GO

-- =============================================================================
-- Create view: gold.vw_customer_value
-- =============================================================================
IF OBJECT_ID ('gold.vw_customer_value','V') IS NOT NULL
    DROP VIEW gold.vw_customer_value
GO

CREATE OR ALTER VIEW gold.vw_customer_value AS 

SELECT
    cx.customer_key,
    cx.customer_id,
    cx.first_name,
    cx.last_name,
    cx.first_name + ' ' + cx.last_name as full_name,
    cx.country,
    SUM(s.quantity) AS total_units_purchased,
    COUNT(DISTINCT s.order_number) AS total_orders,
    SUM(s.revenue) AS lifetime_revenue,
    SUM(s.revenue) * 1.0 / NULLIF(COUNT(DISTINCT s.order_number), 0) AS average_order_value,
    MIN(s.order_date) AS first_purchase_date,
    MAX(s.order_date) AS last_purchase_date
FROM gold.dim_customers cx
JOIN gold.fact_sales s
    ON cx.customer_key = s.customer_key
GROUP BY
    cx.customer_key,
    cx.customer_id,
    cx.first_name,
    cx.last_name,
    cx.country;

