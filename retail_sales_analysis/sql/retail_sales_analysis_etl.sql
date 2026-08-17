-- OLAP - Online Analytics Processes
------------------------------------------------
-- Step 1
-- Create OLAP Database
CREATE DATABASE retail_olap ;

USE retail_olap ;

-- Create Dimension Tables
-- 1. dim_customers
CREATE TABLE dim_customers (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    full_name VARCHAR(150),
    email VARCHAR(100),
    city VARCHAR(100),
    country VARCHAR(100)
);

-- 2. dim_products
CREATE TABLE dim_products (
    product_key INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT,
    product_name VARCHAR(150),
    category VARCHAR(100),
    price DECIMAL(10,2)
);


-- 3. dim_date
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE,
    DAY INT,
    MONTH INT,
    month_name VARCHAR(20),
    QUARTER INT,
    YEAR INT
);

-- Step 2
-- Create Fact Table
-- This table holds the actual sales transactions — linking to all the dimensions.
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



-- ETL Transformation (OLTP → OLAP)
----------------------------------------------------
-- ETL: Extract + Transform + Load
-- Update the dimension and fact tables by pulling from our retail_oltp database.

--  Insert into dim_customers
INSERT INTO dim_customers (customer_id, full_name, email, city, country)
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.email,
    c.city,
    c.country
FROM retail_oltp.customers c;

-- Insert into dim_products
INSERT INTO dim_products (product_id, product_name, category, price)
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.price
FROM retail_oltp.products p;

-- Insert into dim_date
-- Generate unique dates from order_dates column in orders table:
INSERT INTO dim_date (date_key, full_date, DAY, MONTH, month_name, QUARTER, YEAR)
SELECT DISTINCT
    DATE_FORMAT(order_date, '%Y%m%d') AS date_key,
    DATE(order_date) AS full_date,
    DAY(order_date) AS DAY,
    MONTH(order_date) AS MONTH,
    MONTHNAME(order_date) AS month_name,
    QUARTER(order_date) AS QUARTER,
    YEAR(order_date) AS YEAR
FROM retail_oltp.orders;

-- Insert into fact_sales
-- We join across OLTP tables to form the fact table:
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

-- Verification
-- Run checks to ensure all data migrated properly:
SELECT COUNT(*) FROM dim_customers;
SELECT COUNT(*) FROM dim_products;
SELECT COUNT(*) FROM dim_date;
SELECT COUNT(*) FROM fact_sales;

SELECT * FROM fact_sales limit 5;


-- Preview the star schema:
SELECT 
    fs.sales_key, dc.full_name, dp.product_name, dd.full_date, fs.quantity, fs.total_amount
FROM fact_sales fs
JOIN dim_customers dc ON fs.customer_key = dc.customer_key
JOIN dim_products dp ON fs.product_key = dp.product_key
JOIN dim_date dd ON fs.date_key = dd.date_key
LIMIT 10;

