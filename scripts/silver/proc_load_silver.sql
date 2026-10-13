/*
==============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
==============================================================================

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

    EXEC Silver.load_silver;

==============================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver as
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME;
	BEGIN TRY
       PRINT '=====================================';
	   PRINT 'Loading Silver Layer';
	   PRINT '=====================================';


	   PRINT '--------------------------------------';
	   PRINT 'Loading CRM Tables';
	   PRINT '--------------------------------------';
    -- loading silver.crm_cust_info
    SET @start_time = GETDATE();
    PRINT '>>Inserting Data Into: silver.crm_cust_info';
    INSERT INTO silver.crm_cust_info
    ( 
    cst_id, 
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date)

    select
	    cst_id,
	    cst_key,
	    TRIM (cst_firstname) AS first_name,
	    TRIM(cst_lastname) AS last_name,
	    case 
		    when UPPER (cst_marital_status )= 'S' then 'Single'
		    when UPPER(cst_marital_status) = 'M' then 'Married'
		    else 'N/A' -- normalize the values to readable format.
	    end cst_marital_status,
	    case 
		    when UPPER (cst_gndr )= 'F' then 'Female'
		    when UPPER(cst_gndr) = 'M' then 'Male'
		    else 'N/A' -- normalize the values to readable format.
	    end cst_gndr,
	    cst_create_date
	    from (
	    select * ,
		    row_number() OVER
		    (PARTITION BY cst_id order by cst_create_date desc) as flag_last
	    FROM bronze.crm_cust_info
	    )t 
	    where flag_last = 1; 
    	    SET @end_time = GETDATE();
		    PRINT '>> Load Duration: ' +CAST (DATEDIFF(second,@start_time, @end_time) AS NVARCHAR) + 'seconds';
		    PRINT '>> ------------------------------'
    
    --loading silver.crm_prd_info
    SET @start_time = GETDATE();
		    PRINT '>>Inserting Data Into: silver.crm_prd_info';
    INSERT INTO silver.crm_prd_info
    (
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
        REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
        SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
        prd_nm,
        ISNULL(prd_cost,0) AS prd_cost,
        CASE
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            ELSE 'N/A'
        END AS prd_line,
        CAST(prd_start_dt AS DATE) AS prd_start_dt,
        prd_end_dt
    FROM
    (
        SELECT *,
               ROW_NUMBER() OVER
               (
                   PARTITION BY prd_id
                   ORDER BY prd_start_dt DESC
               ) AS flag_last
        FROM bronze.crm_prd_info
    ) t
    WHERE flag_last = 1;
		    SET @end_time = GETDATE();
		    PRINT '>> Load Duration: ' +CAST (DATEDIFF(second,@start_time, @end_time) AS NVARCHAR) + 'seconds';
		    PRINT '>> ------------------------------'
    --loading silver.crm_sales_details
    SET @start_time = GETDATE();
	PRINT '>>Inserting Data Into: silver.crm_sales_details';
    INSERT INTO silver.crm_sales_details (
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
    select 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE 
        when sls_order_dt = 0 or len(sls_order_dt)!= 8 then null
        else cast(cast (sls_order_dt as varchar)as date)
    end as sls_order_dt,
    CASE 
        when sls_ship_dt = 0 or len(sls_ship_dt)!= 8 then null
        else cast(cast (sls_ship_dt as varchar)as date)
    end as sls_ship_dt,
    CASE 
        when sls_due_dt = 0 or len(sls_due_dt)!= 8 then null
        else cast(cast (sls_due_dt as varchar)as date)
    end as sls_due_dt,
    CASE
        WHEN sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price) 
        then sls_quantity * abs(sls_price)
    ELSE sls_sales
    end as sls_sales,
    sls_quantity,
    CASE
        WHEN sls_price is null or sls_price  <= 0 
        then sls_sales / NULLIF (sls_quantity,0)
        ELSE sls_price
    end as sls_price
    from
    (
    select *, row_number() over 
    (
        partition by sls_ord_num, sls_prd_key order by sls_order_dt desc)
        as flag_last
    from bronze.crm_sales_details
    )t 
    where flag_last = 1;
    SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' +CAST (DATEDIFF(second,@start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> ------------------------------'

   	PRINT '--------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '--------------------------------------';
    
    --loading silver.erp_cust_az12
		SET @start_time = GETDATE();
		PRINT '>>Inserting Data Into: silver.erp_cust_az12';
    INSERT INTO silver.erp_cust_az12
    (
    cid,
    bdate,
    GEN
    )
    SELECT 
    CASE 
       WHEN CID LIKE 'NAS%' THEN SUBSTRING(cid,4,len(cid))
       else cid
    end as cid,
    CASE 
        when bdate > getdate() then null
        else bdate
    end as bdate,
    case 
		    when UPPER (trim(gen) ) in  ('F','Female') then 'Female'
		    when UPPER(trim(gen)) in ('M','Male') then 'Male'
		    else 'N/A'
    end as gen
    FROM
    (
        SELECT *,
               ROW_NUMBER() OVER
               (
                   PARTITION BY cid
                   ORDER BY gen DESC
               ) AS flag_last
        FROM bronze.erp_cust_az12
    ) t
    WHERE flag_last = 1;
    		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' +CAST (DATEDIFF(second,@start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> ------------------------------'

  
    --loading silver.erp_loc_a101
	SET @start_time = GETDATE();
	PRINT '>>Inserting Data Into: silver.erp_loc_a101';
    INSERT INTO silver.erp_loc_a101
    (
    CID,
    cntry
    )
    SELECT  
    REPLACE(CID,'-','') CID,
    case 
    when trim(cntry) = 'DE' THEN 'Germany'
    when trim(cntry) in ('US','USA') THEN 'United States'
    WHEN TRIM(CNTRY) =' ' OR CNTRY IS NULL THEN 'N/a'
    else trim(cntry)
    end as cntry

    FROM
    (
        SELECT *,
               ROW_NUMBER() OVER
               (
                   PARTITION BY cid
                   ORDER BY cntry DESC
               ) AS flag_last
        FROM bronze.erp_loc_a101
    ) t
    WHERE flag_last = 1;
    SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' +CAST (DATEDIFF(second,@start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>> ------------------------------'

    --loading silver.erp_px_cat_g1v2
	SET @start_time = GETDATE();
		PRINT '>>Inserting Data Into: silver.erp_px_cat_g1v2';
    INSERT INTO SILVER.erp_px_cat_g1v2
    (
    ID,
    CAT,
    SUBCAT,
    MAINTENANCE
    )
    SELECT 
    ID,
    CAT,
    SUBCAT,
    MAINTENANCE 
    FROM 
    bronze.erp_px_cat_g1v2;
    SET @end_time = GETDATE();
	PRINT '>> Load Duration: ' +CAST (DATEDIFF(second,@start_time, @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>> ------------------------------'
    	END TRY
	BEGIN CATCH
		PRINT '=============================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + Cast(ERROR_STATE()AS NVARCHAR);
		PRINT '=============================================';
	END CATCH
END


EXEC SILVER.load_silver























