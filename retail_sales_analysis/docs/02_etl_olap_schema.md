# ETL & OLAP Schema — `retail_olap`

## Purpose

`retail_olap` is the analytical layer, modeled as a star schema: one fact table (`fact_sales`) surrounded by dimension tables (`dim_customers`, `dim_products`, `dim_date`). This structure is denormalized by design — dimension attributes (e.g., customer city, product category) are flattened into single tables to keep analytical queries simple and fast, at the cost of some data redundancy.

The ETL (Extract, Transform, Load) step is implemented as a set of SQL `INSERT ... SELECT` statements that read from `retail_oltp` and write into `retail_olap`, run manually inside MySQL as a batch job.

## Entity-Relationship Diagram (Star Schema)

![OLAP Star Schema](../erd/retail_sales_olap_erd.png)

`fact_sales` holds one row per order line item and references each dimension by its surrogate key (`customer_key`, `product_key`, `date_key`).

## Database and Table Creation

```sql
CREATE DATABASE retail_olap;
USE retail_olap;
```

### `dim_customers`

```sql
CREATE TABLE dim_customers (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    full_name VARCHAR(150),
    email VARCHAR(100),
    city VARCHAR(100),
    country VARCHAR(100)
);
```

### `dim_products`

```sql
CREATE TABLE dim_products (
    product_key INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    product_name VARCHAR(150),
    category VARCHAR(100),
    price DECIMAL(10,2)
);
```

### `dim_date`

```sql
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE,
    day INT,
    month INT,
    month_name VARCHAR(20),
    quarter INT,
    year INT
);
```

### `fact_sales`

```sql
CREATE TABLE fact_sales (
    sales_key INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    order_item_id INT,
    customer_key INT,
    product_key INT,
    date_key INT,
    quantity INT,
    total_amount DECIMAL(10,2),
    FOREIGN KEY (customer_key) REFERENCES dim_customers(customer_key),
    FOREIGN KEY (product_key) REFERENCES dim_products(product_key),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
);
```

## ETL: Extract, Transform, Load

### Populate `dim_customers`

```sql
INSERT INTO dim_customers (customer_id, full_name, email, city, country)
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.email,
    c.city,
    c.country
FROM retail_oltp.customers c;
```

`first_name` and `last_name` are concatenated into a single `full_name` field — a transformation, not just a copy, aligning the dimension with how the attribute will be used for reporting.

### Populate `dim_products`

```sql
INSERT INTO dim_products (product_id, product_name, category, price)
SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.price
FROM retail_oltp.products p;
```

### Populate `dim_date`

```sql
INSERT INTO dim_date (date_key, full_date, day, month, month_name, quarter, year)
SELECT
    DATE_FORMAT(order_date, '%Y%m%d') AS date_key,
    DATE(order_date) AS full_date,
    DAY(order_date) AS day,
    MONTH(order_date) AS month,
    MONTHNAME(order_date) AS month_name,
    QUARTER(order_date) AS quarter,
    YEAR(order_date) AS year
FROM retail_oltp.orders
GROUP BY DATE(order_date);
```

`dim_date` is generated from the distinct dates present in `orders.order_date`, not from a pre-built calendar table. This means the dimension only contains dates on which at least one order occurred — there are no rows for days with zero orders.

### Populate `fact_sales`

```sql
INSERT INTO fact_sales (order_id, order_item_id, customer_key, product_key, date_key, quantity, total_amount)
SELECT
    oi.order_id,
    oi.order_item_id,
    dc.customer_key,
    dp.product_key,
    DATE_FORMAT(o.order_date, '%Y%m%d') AS date_key,
    oi.quantity,
    oi.subtotal AS total_amount
FROM retail_oltp.order_items oi
JOIN retail_oltp.orders o ON oi.order_id = o.order_id
JOIN retail_oltp.customers c ON o.customer_id = c.customer_id
JOIN retail_oltp.products p ON oi.product_id = p.product_id
JOIN dim_customers dc ON c.customer_id = dc.customer_id
JOIN dim_products dp ON p.product_id = dp.product_id;
```

The fact table grain is one row per **order line item** (`order_items` row), not one row per order. `total_amount` on the fact table is the line-item `subtotal`, so summing it gives total revenue across all line items — this differs from summing `orders.total_amount`, which is one value per order.

## Verification

```sql
SELECT COUNT(*) FROM dim_customers;
SELECT COUNT(*) FROM dim_products;
SELECT COUNT(*) FROM dim_date;
SELECT COUNT(*) FROM fact_sales;
```

Preview the joined star schema:

```sql
SELECT
    fs.sales_key, dc.full_name, dp.product_name, dd.full_date, fs.quantity, fs.total_amount
FROM fact_sales fs
JOIN dim_customers dc ON fs.customer_key = dc.customer_key
JOIN dim_products dp ON fs.product_key = dp.product_key
JOIN dim_date dd ON fs.date_key = dd.date_key
LIMIT 10;
```

At this point, `retail_olap` is a populated star schema ready to be connected to Power BI, described in [`03_powerbi_dashboard.md`](03_powerbi_dashboard.md).
