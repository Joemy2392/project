# OLTP Schema — `retail_oltp`

## Purpose

`retail_oltp` is the transactional (source) database. It holds retail sales data in third normal form (3NF): each entity has its own table, foreign keys enforce referential integrity, and data is not duplicated across tables. This layer is designed for data entry and transactional consistency, not for analytical querying.

## Entity-Relationship Diagram

![OLTP ERD](../erd/retail_sales_oltp_erd.png)

**Relationships:**
- `customers` (1) → `orders` (many) via `customer_id`
- `orders` (1) → `order_items` (many) via `order_id`
- `products` (1) → `order_items` (many) via `product_id`

## Database and Table Creation

```sql
CREATE DATABASE retail_oltp;
USE retail_oltp;
```

### `customers`

```sql
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(50),
    address VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100),
    created_at DATE
);
```

### `products`

```sql
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(150),
    category VARCHAR(100),
    price DECIMAL(10, 2)
);
```

### `orders`

```sql
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATETIME,
    status ENUM('Completed', 'Pending', 'Cancelled'),
    total_amount DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
```

### `order_items`

```sql
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10, 2),
    subtotal DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
```

## Loading Source Data

Source data is loaded from CSV files using `LOAD DATA INFILE`. This requires:
- CSV files placed in a directory the MySQL server can read (e.g., `C:/data/` on Windows, `/home/user/data/` on Linux).
- The MySQL user has the `FILE` privilege.
- `local_infile` enabled on the server/client if loading from a client-side path.

```sql
-- Load Customers
LOAD DATA INFILE 'C:/data/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, first_name, last_name, email, phone, address, city, country, created_at);

-- Load Products
LOAD DATA INFILE 'C:/data/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_name, category, price);

-- Load Orders
LOAD DATA INFILE 'C:/data/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_date, status, total_amount);

-- Load Order_Items
LOAD DATA INFILE 'C:/data/order_items.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_item_id, order_id, product_id, quantity, price, subtotal);
```

## Verification

```sql
-- Row counts
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;

-- Spot checks
SELECT * FROM orders LIMIT 5;
SELECT * FROM order_items LIMIT 5;
```

At this point, `retail_oltp` is a normalized MySQL database with enforced foreign key relationships and is ready to serve as the source for the ETL step described in [`02_etl_olap_schema.md`](02_etl_olap_schema.md).
