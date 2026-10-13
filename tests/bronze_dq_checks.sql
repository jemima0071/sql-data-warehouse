/*
==============================================================================
Quality Checks
==============================================================================

Script Purpose:

    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' schema. It includes checks for:

    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:

    - Run these checks after data loading Bronze Layer.
    - Investigate and resolve any discrepancies found during the checks.

==============================================================================
*/
SELECT * FROM (
select * ,
row_number() OVER
(PARTITION BY cst_id order by cst_create_date desc) as flag_last
FROM bronze.crm_cust_info
)t where flag_last = 1 and cst_id = NULL

-- check for the unwanted spaces
select cst_lastname
from bronze.crm_cust_info
where cst_lastname != TRIM(cst_lastname)

---data standardization and consistency
select distinct cst_gndr
from bronze.crm_cust_info

select distinct prd_line
from DataWarehouse.bronze.crm_prd_info

--check for nulls or duplicates in primary key
SELECT cst_id, count(*) from bronze.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null

--2 crm_prd_info
select top(1000)
prd_id,prd_key,prd_nm,prd_cost,prd_end_dt,prd_start_dt,prd_line
from [DataWarehouse].[bronze].[crm_prd_info]

SELECT prd_id, count(*) from [DataWarehouse].bronze.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id is null

select prd_id,prd_nm from DataWarehouse.bronze.crm_prd_info
order by prd_id

----
SELECT * FROM (
select * ,
row_number() OVER
(PARTITION BY prd_id order by prd_start_dt desc) as flag_last
FROM DataWarehouse.bronze.crm_prd_info
)t where flag_last = 1

--
-- check for the unwanted spaces
select prd_nm
from DataWarehouse.silver.crm_prd_info
where prd_nm != TRIM(prd_nm)

--check for nulls or duplicates in primary key
SELECT cst_id, count(*) from silver.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null

---


---check for null or negative numbers
SELECT prd_cost
from datawarehouse.silver.crm_prd_info
where prd_cost < 0 or prd_cost is null
