-- SQL BEGINEER/ BASIC

-- CHAPTER 1
-- Create Database
CREATE DATABASE sales;

-- Create Table
CREATE TABLE stores
(
	store_id INT,
    store_name VARCHAR(200)
);

-- Insert Some Records
INSERT INTO stores(store_id)
VALUES
(3);

-- Create Table
CREATE TABLE stores_new
(
	store_id INT UNIQUE,
    store_name VARCHAR(200) NOT NULL
);

-- Insert Some Data
INSERT INTO stores_new
VALUES
(1,"store_xyz");


-- ALTER COMMAND
ALTER TABLE stores_new
RENAME COLUMN store_city to store_location;


-- CHAPTER 3

-- FIRST SELECT 
SELECT * FROM dim_customer;


-- LIMIT 
SELECT 
	customer_id,
	email 
FROM 
	dim_customer
LIMIT 15;


-- WHERE [CONDITION]
-- 1
SELECT 
	* 
FROM 
	dim_customer 
WHERE 
	gender = 'F';

-- 2 (AND/OR)
SELECT 
	* 
FROM 
	dim_customer 
WHERE 
	(gender = 'F') AND ((country = 'France') OR (join_date > '2022-01-01'));
    
    
-- LIKE = kaisa result chaiye . % reminder indicate. T% means first t then baki kuch bhi
-- 1)
SELECT 
	* 
FROM 
	dim_customer
WHERE 
	first_name LIKE 'T%';
-- 2)
SELECT 
	* 
FROM 
	dim_customer
WHERE 
	first_name LIKE 'T__f%y';

    
-- Sorting
SELECT 
	* 
FROM 
	dim_product
ORDER BY 
	unit_price DESC 
LIMIT 3;


-- ALIAS
SELECT 
	product_key,
    product_id,
    product_name AS 'product name',
    category
FROM 
	dim_product;


-- GROUPING
-- 1
SELECT 
	category,
    avg(unit_price) AS avg_price,
    sum(unit_price) AS total_price
FROM 
	dim_product
GROUP BY 
	category;
    
-- 2
SELECT 
	category,
    avg(unit_price) AS avg_price,
    sum(unit_price) AS total_price
FROM 
	dim_product
GROUP BY 
	category
HAVING
	avg_price > 500;
----------------------CHAPTER 3 COMPLETE-------------------------------------------------
#CHAPTER 4
-- JOINS 
-- INNER JOIN
SELECT 
	*
FROM 
	orders o 
INNER JOIN 
	customers c 
    ON 
		o.cust_id = c.id;

-- LEFT JOIN
SELECT 
	*
FROM 
	orders o 
LEFT JOIN 
	customers c 
    ON 
		o.cust_id = c.id;

-- RIGHT JOIN
SELECT 
	*
FROM 
	orders o 
RIGHT JOIN 
	customers c 
    ON 
		o.cust_id = c.id;
        
-- FULL JOIN (Not Supported) in MYSQL
SELECT 
	*
FROM 
	orders o 
FULL JOIN 
	customers c 
    ON 
		o.cust_id = c.id;
        
        
-- UNIONS
SELECT 
	*
FROM 
	orders o 
LEFT JOIN 
	customers c 
    ON 
		o.cust_id = c.id

UNION

SELECT 
	*
FROM 
	orders o 
RIGHT JOIN 
	customers c 
    ON 
		o.cust_id = c.id;
	
----------------------------CHAPTER 4 COMPLETE------------------------------------------------
    


