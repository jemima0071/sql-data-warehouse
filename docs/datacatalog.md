# Data Catalog - Customer & Product Sales Data Mart

## DimCustomer

**Purpose:** Stores customer master and demographic information used for customer analysis, segmentation, and sales reporting.

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| Customer Key | INT | Surrogate key and Primary Key of the customer dimension |
| Customer ID | INT | Source customer identifier |
| Customer Number | NVARCHAR(50) | Business customer number |
| First Name | NVARCHAR(50) | Customer first name |
| Last Name | NVARCHAR(50) | Customer last name |
| Marital Status | NVARCHAR(50) | Customer marital status |
| Create Date | DATE | Customer record creation date |
| Birthdate | DATE | Customer date of birth |
| Gender | NVARCHAR(50) | Customer gender |
| Country | NVARCHAR(50) | Customer country |

## DimProduct

**Purpose:** Stores product master data and hierarchy information used for product and sales analysis.

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| Product Key | INT | Surrogate key and Primary Key of the product dimension |
| Product ID | INT | Source product identifier |
| Product Number | NVARCHAR(50) | Business product code |
| Product Name | NVARCHAR(50) | Product name |
| Category ID | NVARCHAR(50) | Product category identifier |
| Category | NVARCHAR(50) | Product category |
| Sub Category | NVARCHAR(50) | Product sub-category |
| Maintenance | NVARCHAR(50) | Maintenance classification |
| Product Cost | DECIMAL(18,2) | Product cost |
| Product Line | NVARCHAR(50) | Product line classification |
| Start Date | DATE | Product effective start date |

## FactSales

**Purpose:** Stores sales transactions and measures used for reporting and analytics.

| Column Name | Data Type | Description |
|-------------|-----------|-------------|
| Order Number | NVARCHAR(50) | Unique sales order number |
| Product Key | INT | Foreign key referencing DimProduct |
| Customer Key | INT | Foreign key referencing DimCustomer |
| Order Date | DATE | Date order was placed |
| Ship Date | DATE | Date order was shipped |
| Due Date | DATE | Expected delivery date |
| Sales | DECIMAL(18,2) | Sales amount |
| Quantity | INT | Quantity sold |
| Price | DECIMAL(18,2) | Unit selling price |
