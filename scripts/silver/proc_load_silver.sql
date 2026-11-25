/*
===========================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===========================================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    CALL silver.load_silver;
==========================================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_silver()
LANGUAGE plpgsql
AS $body$
DECLARE
    current_table TEXT;
    batch_start_time TIMESTAMP;
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    batch_end_time TIMESTAMP;
    duration INTERVAL;
    BEGIN
        batch_start_time := clock_timestamp();
        RAISE NOTICE '===========================================';
        RAISE NOTICE 'Loading silver Layer';
        RAISE NOTICE '===========================================';

        RAISE NOTICE '--------------------------------------------';
        RAISE NOTICE 'Loading CRM Tables';
        RAISE NOTICE '--------------------------------------------';

        start_time := clock_timestamp();
        current_table := 'silver.crm_cust_info';
        RAISE NOTICE '>> Truncating Table: %', current_table;
        --TRUNCATE TABLE current_table;
        EXECUTE format('TRUNCATE TABLE %s', current_table);

        RAISE NOTICE '>> Inserting data into: %', current_table;
        INSERT INTO silver.crm_cust_info(
            cst_id,
            cst_key,
            cst_first_name,
            cst_last_name,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_first_name) AS cst_first_name,
            TRIM(cst_last_name) AS cst_last_name,
            CASE 
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END cst_marital_status, -- Normalize marital status values to readable format
            CASE 
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END cst_gndr, -- Normalize gender values to readable format
            cst_create_date
        FROM(
            SELECT 
            *,
            ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
            FROM bronze.crm_cust_info
        )t WHERE flag_last = 1; -- Select the most recent record per customer

        end_time := clock_timestamp();
        duration := end_time - start_time;
        RAISE NOTICE 'successfully loaded %', current_table;
        RAISE NOTICE 'Load duration: %', duration;
        RAISE NOTICE '----------------------------------------------'; 

        start_time := clock_timestamp();
        current_table := 'silver.crm_prd_info';
        RAISE NOTICE '>> Truncating Table: %', current_table;
        --TRUNCATE TABLE current_table;
        EXECUTE format('TRUNCATE TABLE %s', current_table);

        RAISE NOTICE '>> Inserting data into: %', current_table;
        INSERT INTO silver.crm_prd_info(
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-','_') AS cat_id, -- Extract category ID
            SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS prd_key, -- Extract product key
            prd_nm,
            COALESCE(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,                          -- Map product line codes to descriptive values
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL '1 day' AS DATE) AS prd_end_dt  -- Calculate end date as one day before the next start date
        FROM bronze.crm_prd_info;

        end_time := clock_timestamp();
        duration := end_time - start_time;
        RAISE NOTICE 'successfully loaded %', current_table;
        RAISE NOTICE 'Load duration: %', duration;
        RAISE NOTICE '-------------------------------------------------------';

        start_time := clock_timestamp();
        current_table := 'silver.crm_sales_details';
        RAISE NOTICE '>> Truncating Table: %', current_table;
        --TRUNCATE TABLE current_table;
        EXECUTE format('TRUNCATE TABLE %s', current_table);

        RAISE NOTICE '>> Inserting data into: %', current_table;
        INSERT INTO silver.crm_sales_details(
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE
                WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::TEXT) != 8 THEN NULL
                ELSE sls_order_dt::VARCHAR::DATE
            END AS sls_order_dt,
            CASE
                WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::TEXT) != 8 THEN NULL
                ELSE sls_ship_dt::VARCHAR::DATE
            END AS sls_ship_dt,
            CASE
                WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::TEXT) != 8 THEN NULL
                ELSE sls_due_dt::VARCHAR::DATE
            END AS sls_due_dt,
            CASE 
                WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_sales * ABS(sls_price)
                THEN sls_quantity * ABS(sls_price)
                ELSE sls_price
            END AS sls_sales,  -- Recalculate sales if original value is missing or incorrect
            sls_quantity,
            CASE
                WHEN sls_price IS NULL OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price  -- Derive price if original value is invalid
        FROM bronze.crm_sales_details;

        end_time := clock_timestamp();
        duration := end_time - start_time;
        RAISE NOTICE 'successfully loaded %', current_table;
        RAISE NOTICE 'Load duration: %', duration;
        RAISE NOTICE '-------------------------------------------------';

        RAISE NOTICE '--------------------------------------------';
        RAISE NOTICE 'Loading ERP Tables';
        RAISE NOTICE '--------------------------------------------';

        start_time := clock_timestamp();
        current_table := 'silver.erp_cust_az12';
        RAISE NOTICE '>> Truncating Table: %', current_table;
        --TRUNCATE TABLE current_table;
        EXECUTE format('TRUNCATE TABLE %s', current_table);

        RAISE NOTICE '>> Inserting data into: %', current_table;
        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
            CASE 
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))  -- Remove 'NAS' prefix if present
                ELSE cid
            END cid,
            CASE
                WHEN bdate > NOW() THEN NULL  -- Set future birthdates to NULL
                ELSE bdate
            END AS bdate,
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'n/a'
            END AS gen  -- Normalize gender values and handle unknown cases
        FROM bronze.erp_ust_az12;

        end_time := clock_timestamp();
        duration := end_time - start_time;
        RAISE NOTICE 'successfully loaded %', current_table;
        RAISE NOTICE 'Load duration: %', duration;
        RAISE NOTICE '-------------------------------------------------';

        start_time := clock_timestamp();
        current_table := 'silver.erp_loc_a101';
        RAISE NOTICE '>> Truncating Table: %', current_table;
        --TRUNCATE TABLE current_table;
        EXECUTE format('TRUNCATE TABLE %s', current_table);

        RAISE NOTICE '>> Inserting data into: %', current_table;
        INSERT INTO silver.erp_loc_a101(cid, cntry)
        SELECT
            REPLACE(cid, '-', '') cid,
            CASE 
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END AS cntry  -- Normalize and Handle missing or blank country codes
        FROM bronze.erp_loc_a101;

        end_time := clock_timestamp();
        duration := end_time - start_time;
        RAISE NOTICE 'successfully loaded %', current_table;
        RAISE NOTICE 'Load duration: %', duration;
        RAISE NOTICE '-------------------------------------------------';

        start_time := clock_timestamp();
        current_table := 'silver.erp_px_cat_g1v2';
        RAISE NOTICE '>> Truncating Table: %', current_table;
        --TRUNCATE TABLE current_table;
        EXECUTE format('TRUNCATE TABLE %s', current_table);

        RAISE NOTICE '>> Inserting data into: %', current_table;
        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance  
        )   
        SELECT
            id,
            cat,
            subcat,
            maintenance 
        FROM bronze.erp_px_cat_g1v2;

        end_time := clock_timestamp();
        duration := end_time - start_time;
        RAISE NOTICE 'successfully loaded %', current_table;
        RAISE NOTICE 'Load duration: %', duration;
        RAISE NOTICE '-------------------------------------------------';

        batch_end_time := clock_timestamp();
        duration := batch_end_time - batch_start_time;
        RAISE NOTICE 'All tables successfully loaded';
        RAISE NOTICE 'Load duration: %', duration;
    
    EXCEPTION
    -- Error handler begins
        WHEN OTHERS THEN
            RAISE NOTICE 'bronze layer load failed';
            RAISE NOTICE 'Failed table: %', current_table;
            RAISE NOTICE 'Error code: %', SQLSTATE;
            RAISE NOTICE 'Error message: %', SQLERRM;
    RAISE;    
    END
$body$;
