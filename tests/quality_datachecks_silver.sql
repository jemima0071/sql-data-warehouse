SELECT * FROM (
select * ,
row_number() OVER
(PARTITION BY cst_id order by cst_create_date desc) as flag_last
FROM bronze.crm_cust_info
)t where flag_last = 1 and cst_id = NULL

-- check for the unwanted spaces
select cst_gndr
from silver.crm_cust_info
where cst_gndr != TRIM(cst_gndr)

---data standardization and consistency
select distinct cst_gndr
from silver.crm_cust_info

--check for nulls or duplicates in primary key
SELECT prd_id, count(*) from silver.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id is null

SELECT sls_cust_id, count(*) from bronze.crm_sales_details
group by sls_cust_id
having count(*) > 1 or sls_cust_id is null

select * from silver.crm_cust_info

-- delete row 
DELETE FROM silver.crm_cust_info
WHERE cst_id IS NULL;

-- RCA
SELECT
    prd_id,
    COUNT(*) cnt
FROM SILVER.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;

SELECT prd_id, COUNT(*)
FROM bronze.crm_prd_info
WHERE prd_id = 215
GROUP BY prd_id;

TRUNCATE TABLE silver.crm_sales_details;
TRUNCATE TABLE silver.erp_cust_az12

SELECT * FROM bronze.crm_sales_details


-- check for the sales details tables
select 
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_sales,
sls_quantity,
sls_price
from bronze.crm_sales_details

-- duplicate rows
SELECT sls_ord_num, count(*) from bronze.crm_sales_details
group by sls_ord_num
having count(*) > 1 or sls_ord_num is null

SELECT sls_prd_key, count(*) from silver.crm_sales_details
group by sls_prd_key
having count(*) > 1 or sls_prd_key is null


-- invalid dates
select sls_order_dt from 
bronze.crm_sales_details
where sls_order_dt  = 0

--query the int to date 
case when sls_order_dt = 0 or len(sls_order_dt)!= 8 then null
else cast(cast (sls_order_dt as varchar)as date)
end as sls_order_dt,

--query to check if the sales,quantity,price has 0, null 3. sales_details
select sls_sales,
sls_quantity,
sls_price
from silver.crm_sales_details
where sls_sales!= sls_quantity * sls_price
or sls_sales is null or  sls_quantity  is null or sls_price is null
or sls_sales< 0 or sls_quantity < 0  or  sls_price < 0

-- old vs new sales_details 3
select distinct
sls_sales as old_sls_sales,
sls_quantity,
sls_price as old_sls_price,
CASE
    WHEN sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price) 
    then sls_quantity * abs(sls_price)
ELSE sls_sales
end as sls_sales,
CASE
    WHEN sls_price is null or sls_price  <= 0 
    then sls_sales / NULLIF (sls_quantity,0)
    ELSE sls_price
end as sls_price
from silver.crm_sales_details
where sls_sales!= sls_quantity * sls_price
or sls_sales is null or  sls_quantity  is null or sls_price is null
or sls_sales <= 0 or sls_quantity <= 0  or  sls_price <= 0
order by sls_sales, sls_quantity,sls_price

--- checking duplicate
SELECT
    cid,
    COUNT(*) AS cnt
FROM silver.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1
    OR cid IS NULL;

    ---
SELECT
    cid,
    COUNT(*) AS cnt
FROM silver.erp_loc_a101
GROUP BY cid
HAVING COUNT(*) > 1
    OR cid IS NULL;

--- cehck gen
 select distinct gen
 from silver.erp_cust_az12

-- removing the duplicate
SELECT *
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

--------------------
select distinct 
case 
when trim(cntry) = 'DE' THEN 'Germany'
when trim(cntry) in ('US','USA') THEN 'United States'
WHEN TRIM(CNTRY) =' ' OR CNTRY IS NULL THEN 'N/a'
else trim(cntry)
end as cntry
from bronze.erp_loc_a101


select distinct 
CNTRY
from bronze.erp_loc_a101

-- CHECK THE SPACES
SELECT CAT,SUBCAT,MAINTENANCE FROM BRONZE.erp_px_cat_g1v2
WHERE CAT != TRIM(CAT) OR SUBCAT != TRIM(SUBCAT) 
OR MAINTENANCE != TRIM(MAINTENANCE)

--DATA STANDARDIZATION 
SELECT DISTINCT CAT
FROM silver.erp_px_cat_g1v2

--truncate
truncate table silver.erp_px_cat_g1v2

--- checking duplicate
SELECT
    cid,
    COUNT(*) AS cnt
FROM silver.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1
    OR cid IS NULL;
