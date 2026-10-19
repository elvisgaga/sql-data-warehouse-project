/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    CALL bronze.load_bronze();
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
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
        batch_start_time:= clock_timestamp();

        RAISE NOTICE '==========================================';
        RAISE NOTICE 'Loading Bronze Layer';
        RAISE NOTICE '===========================================';

        RAISE NOTICE '--------------------------------------------';
        RAISE NOTICE 'Loading CRM Tables';
        RAISE NOTICE '--------------------------------------------';

        start_time := clock_timestamp();
        current_table := 'bronze.crm_cust_info';
        RAISE NOTICE '>> Truncating Table: %', current_table;
        --TRUNCATE TABLE current_table;
        EXECUTE format('TRUNCATE TABLE %s', current_table);

        RAISE NOTICE '>> Inserting data into: %', current_table;
        COPY bronze.crm_cust_info
        FROM 'C:\Users\Public\Documents\SQL projects\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH(
            FORMAT CSV, 
            DELIMITER ',', 
            HEADER
        );
        end_time := clock_timestamp();
        duration := end_time - start_time;
        RAISE NOTICE 'successfully loaded %', current_table;
        RAISE NOTICE 'Load duration: %', duration;
        RAISE NOTICE '------------------------------------------------';
        RAISE NOTICE '------------------------------------------------';

        start_time := clock_timestamp();
        current_table := 'bronze.crm_prd_info';
        RAISE NOTICE '>> Truncating Table: %', current_table;
        --TRUNCATE TABLE current_table;
        EXECUTE format('TRUNCATE TABLE %s', current_table);

        RAISE NOTICE '>> Inserting data into: %', current_table;
        COPY bronze.crm_prd_info
        FROM 'C:\Users\Public\Documents\SQL projects\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH(
            FORMAT CSV, 
            DELIMITER ',', 
            HEADER
        );
        end_time := clock_timestamp();
        duration := end_time - start_time;
        RAISE NOTICE 'successfully loaded %', current_table;
        RAISE NOTICE 'Load duration: %', duration;
        RAISE NOTICE '------------------------------------------------';
        RAISE NOTICE '------------------------------------------------';


        start_time := clock_timestamp();
        current_table := 'bronze.crm_sales_details';
        RAISE NOTICE '>> Truncating Table: %', current_table;
        --TRUNCATE TABLE current_table;
        EXECUTE format('TRUNCATE TABLE %s', current_table);

        RAISE NOTICE '>> Inserting data into: %', current_table;
        COPY bronze.crm_sales_details
        FROM 'C:\Users\Public\Documents\SQL projects\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH(
            FORMAT CSV, 
            DELIMITER ',', 
            HEADER
        );
        end_time := clock_timestamp();
        duration := end_time - start_time;
        RAISE NOTICE 'successfully loaded %', current_table;
        RAISE NOTICE 'Load duration: %', duration;

        RAISE NOTICE '--------------------------------------------';
        RAISE NOTICE 'Loading ERP Tables';
        RAISE NOTICE '--------------------------------------------';

        start_time := clock_timestamp();
        current_table := 'bronze.erp_loc_a101';
        RAISE NOTICE '>> Truncating Table: %', current_table;
        --TRUNCATE TABLE current_table;
        EXECUTE format('TRUNCATE TABLE %s', current_table);

        RAISE NOTICE '>> Inserting data into: %', current_table;
        COPY bronze.erp_loc_a101
        FROM 'C:\Users\Public\Documents\SQL projects\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        WITH(
            FORMAT CSV, 
            DELIMITER ',', 
            HEADER
        );
        end_time := clock_timestamp();
        duration := end_time - start_time;
        RAISE NOTICE 'successfully loaded %', current_table;
        RAISE NOTICE 'Load duration: %', duration;
        RAISE NOTICE '------------------------------------------------';
        RAISE NOTICE '------------------------------------------------';

        start_time := clock_timestamp();
        current_table := 'bronze.erp_px_cat_giv2';
        RAISE NOTICE '>> Truncating Table: %', current_table;
        --TRUNCATE TABLE current_table;
        EXECUTE format('TRUNCATE TABLE %s', current_table);

        RAISE NOTICE '>> Inserting data into: %', current_table;
        COPY bronze.erp_px_cat_giv2
        FROM 'C:\Users\Public\Documents\SQL projects\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH(
            FORMAT CSV, 
            DELIMITER ',', 
            HEADER
        );
        end_time := clock_timestamp();
        duration := end_time - start_time;
        RAISE NOTICE 'successfully loaded %', current_table;
        RAISE NOTICE 'Load duration: %', duration;
        RAISE NOTICE '------------------------------------------------';
        RAISE NOTICE '------------------------------------------------';

        start_time := clock_timestamp();
        current_table := 'bronze.erp_ust_az12';
        RAISE NOTICE '>> Truncating Table: %', current_table;
        --TRUNCATE TABLE current_table;
        EXECUTE format('TRUNCATE TABLE %s', current_table);

        RAISE NOTICE '>> Inserting data into: %', current_table;
        COPY bronze.erp_ust_az12
        FROM 'C:\Users\Public\Documents\SQL projects\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        WITH(
            FORMAT CSV, 
            DELIMITER ',', 
            HEADER
        );
        end_time := clock_timestamp();
        duration := end_time - start_time;
        RAISE NOTICE 'successfully loaded %', current_table;
        RAISE NOTICE 'Load duration: %', duration;
        RAISE NOTICE '------------------------------------------------';
        RAISE NOTICE '------------------------------------------------';

        batch_end_time := clock_timestamp();
        duration := batch_end_time - batch_start_time;
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
