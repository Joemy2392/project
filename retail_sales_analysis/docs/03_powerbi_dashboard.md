# Power BI Dashboard — Retail Sales Performance

## Data Source Connection

Power BI Desktop connects to the OLAP layer directly via a MySQL connector:

1. **Home → Get Data → More… → MySQL database**
2. Server: `localhost` (or the applicable MySQL host)
3. Database: `retail_olap`
4. Authenticate with a MySQL username/password
5. Select tables: `fact_sales`, `dim_customers`, `dim_products`, `dim_date`
6. **Load**

Requirements: a running MySQL server, Power BI Desktop, and the MySQL Connector/ODBC driver.

## Data Model

In **Model view**, the four tables are related as a star schema:

| From | To | Cardinality | Cross-filter direction |
|---|---|---|---|
| `dim_customers.customer_key` | `fact_sales.customer_key` | 1 → * | Single |
| `dim_products.product_key` | `fact_sales.product_key` | 1 → * | Single |
| `dim_date.date_key` | `fact_sales.date_key` | 1 → * | Single |

## DAX Measures

```dax
Total Sales = SUM(fact_sales[total_amount])

Total Quantity = SUM(fact_sales[quantity])

Total Customers = DISTINCTCOUNT(fact_sales[customer_key])

Sales Year = SELECTEDVALUE(dim_date[year])

Average Order Value = DIVIDE([Total Sales], [Total Customers])
```

> **Note on `Average Order Value`:** as defined above, this measure divides total sales by the *distinct count of customers*, i.e. average revenue per customer. 

## Dashboard Layout

![Dashboard](../dashboard/powerbi_dashboard.png)

**Title:** Retail Sales Performance Dashboard

**KPI cards** (top row):
| Metric | Measure |
|---|---|
| Total Customers | `[Total Customers]` |
| Total Quantity Sold | `[Total Quantity]` |
| Total Sales | `[Total Sales]` |
| Average Order Value | `[Average Order Value]` |

**Filters (left panel):**
- **City** slicer (dropdown, default "All")
- **Year** slicer (dropdown, default "All")
- **Period** slicer — date range picker on `dim_date.full_date`, set to "Between"

**Visuals:**

| Visual | Chart type | Axis / Values |
|---|---|---|
| Top 10 Total Sales by Product | Horizontal bar | Axis: `dim_products.product_name` · Values: `[Total Sales]`, filtered to top 10 |
| Total Sales by Country | Filled map | Location: `dim_customers.country` · Values: `[Total Sales]` |
| Total Sales by Month and Year | Line/area chart | Axis: month · Legend: `dim_date.year` · Values: `[Total Sales]` |
| Top 10 Total Sales by Customer | Horizontal bar | Axis: `dim_customers.full_name` · Values: `[Total Sales]`, filtered to top 10 |
| Total Sales by Category | Donut chart | Legend: `dim_products.category` · Values: `[Total Sales]` |


## What the Current Build Shows

Based on the dashboard screenshot in this repository, the loaded dataset produces:

- **990** total customers, **37,374** total units sold, **$9,094,046** in total sales, and an average order value (per the measure definition above) of **$9,186**
- **Sales by category** is fairly evenly split, led by Beauty (24.7%) and Sports (24.1%), with Electronics (18.8%), Clothing (18.4%), and Home & Kitchen (14.0%) following
- The monthly trend line covers 2023–2025 and shows month-to-month fluctuation rather than a steady seasonal pattern
- Top-10 product and customer rankings are populated and sorted correctly by `[Total Sales]`
