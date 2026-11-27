/*
=================================================================================
Customer Report
=================================================================================
- This report consolidates key product metrics and behaviours

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identity High-Perfomers, Mid_Range, or Low-Perfomers.
    3. Aggregates product level metrics:
        - total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last order)
        - average order value
        - average monthly spend
=================================================================================
*/

CREATE VIEW gold.report_product AS
WITH base_query AS(
/*----------------------------------------------------------------
1) Base Query: Retrieve core columns from tables
----------------------------------------------------------------*/
SELECT 
    f.order_number,
    f.order_date,
    f.sales_amount,
    f.quantity,
    f.customer_key,
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERE order_date IS NOT NULL 
)
,customer_aggregation AS (
/*--------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
--------------------------------------------------------------------*/
SELECT 
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT customer_key) AS total_customers,
    MAX(order_date) AS last_order_date,
    EXTRACT("YEAR" FROM AGE(
        MAX(order_date),
        MIN(order_date)
    )) * 12 +
    EXTRACT(MONTH FROM AGE(
        MAX(order_date),
        MIN(order_date)
    )) AS lifespan
FROM base_query
GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    CASE
        WHEN total_sales > 5000 THEN 'High-Perfomer'
        WHEN total_sales >= 1000 THEN 'Mid-Range'
        ELSE 'Low_Perfomer'
    END AS Product_Segment,
    CASE 
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END customer_segment,
    last_order_date,
    EXTRACT("YEAR" FROM AGE(
        CURRENT_DATE,
        last_order_date
    )) * 12 +
    EXTRACT(MONTH FROM AGE(
        CURRENT_DATE,
        last_order_date
    )) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    lifespan,
    -- Compute average order value (AVO)
    CASE 
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_value,
    -- Compute average monthly spend
    CASE 
        WHEN lifespan = 0 THEN total_sales
        ELSE ROUND(total_sales / lifespan, 2) 
    END AS avg_monthly_spend
FROM customer_aggregation
