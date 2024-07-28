-- Create Schema
CREATE SCHEMA dannys_diner
GO

-- Drop if exists tables
DROP TABLE IF EXISTS dannys_diner.sales;
DROP TABLE IF EXISTS dannys_diner.menu;
DROP TABLE IF EXISTS dannys_diner.members;

-- Create table menu
CREATE TABLE dannys_diner.menu (
  product_id INT PRIMARY KEY,
  product_name VARCHAR(5),
  price INT
);
GO

-- Insert data into menu table
INSERT INTO dannys_diner.menu (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);
GO

-- Create table members
CREATE TABLE dannys_diner.members (
  customer_id CHAR(1) PRIMARY KEY,
  join_date DATE
);
GO

-- Insert data into members table
INSERT INTO dannys_diner.members (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09'),
  ('C', '2021-01-15');
GO


-- Create table sales
CREATE TABLE dannys_diner.sales (
  customer_id CHAR(1),
  order_date DATE,
  product_id INT,
  FOREIGN KEY (customer_id) REFERENCES dannys_diner.members(customer_id),
  FOREIGN KEY (product_id) REFERENCES dannys_diner.menu(product_id)
);
GO

-- Insert data into sales table
INSERT INTO dannys_diner.sales (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);
GO
