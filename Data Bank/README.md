# Data Bank (SQL case study)
![image](https://github.com/user-attachments/assets/7845048f-6ad4-466c-9d9a-cd5216898ef0)

## The Guide

I use Microsoft SQL Sever for this case study walkthrough

1. Create a database
2. Run ```schema.sql``` file in the database
3. Use ```solutions.sql``` file to check the solutions

## The Relationship Diagram
![diagram](https://github.com/user-attachments/assets/f86d4153-283c-40e2-8603-98ab5e6b3130)

## Questions
### A. Customer Nodes Exploration
1. How many unique nodes are there on the Data Bank system?
2. What is the number of nodes per region?
3. How many customers are allocated to each region?
4. How many days on average are customers reallocated to a different node?
5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

### B. Customer Transactions
1. What is the unique count and total amount for each transaction type?
2. What is the average total historical deposit counts and amounts for all customers?
3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
4. What is the closing balance for each customer at the end of the month?
5. What is the percentage of customers who increase their closing balance by more than 5%?


## Solutions

### A. Customer Nodes Exploration
**1. How many unique nodes are there on the Data Bank system?**
```
SELECT COUNT(DISTINCT node_id) AS number_of_unique_nodes 
FROM DB.customer_nodes;
```
![image](https://github.com/user-attachments/assets/e978a32e-792d-4e8c-9948-b3582df74ed9)

**2. What is the number of nodes per region?**
```
SELECT R.region_id, R.region_name, COUNT(N.node_id) AS node_count
FROM DB.regions R
INNER JOIN DB.customer_nodes N
ON R.region_id = N.region_id
GROUP BY R.region_id, R.region_name;
```
![image](https://github.com/user-attachments/assets/d867e2d5-4c03-4c84-bf25-7840f2d1b2cc)

**3. How many customers are allocated to each region?**
```
SELECT R.region_id, R.region_name, COUNT(DISTINCT C.customer_id) AS number_of_customer
FROM DB.customer_nodes AS C
JOIN DB.regions AS R
ON C.region_id = R.region_id
GROUP BY R.region_id, R.region_name;
```
![image](https://github.com/user-attachments/assets/6c47b028-9b47-4de6-9473-a3c67277e52d)

**4. How many days on average are customers reallocated to a different node?**
```
SELECT AVG(DATEDIFF(day, start_date, end_date)) AS Days_on_average
FROM DB.customer_nodes
WHERE end_date != '9999-12-31';
```
![image](https://github.com/user-attachments/assets/ba2e9a24-b38d-4969-a267-1c2e0cfc9838)

**5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?**
```
WITH DS AS (
    SELECT region_id, DATEDIFF(day, start_date, end_date) AS allocation_days
    FROM DB.customer_nodes
    WHERE end_date != '9999-12-31'
)

SELECT DISTINCT region_id, 
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY allocation_days) OVER (PARTITION BY region_id) AS median,
       PERCENTILE_DISC(0.8) WITHIN GROUP (ORDER BY allocation_days) OVER (PARTITION BY region_id) AS #80percentile,
       PERCENTILE_DISC(0.95) WITHIN GROUP (ORDER BY allocation_days) OVER (PARTITION BY region_id) AS #95percentile
FROM DS;
```
![image](https://github.com/user-attachments/assets/62e65073-f095-4f20-9bfd-a05a184a9a54)

### B. Customer Transactions
**1. What is the unique count and total amount for each transaction type?**
```
SELECT txn_type, COUNT(*) AS unique_count, SUM(txn_amount) AS total_amount
FROM DB.customer_transactions
GROUP BY txn_type;
```
![image](https://github.com/user-attachments/assets/ce89ab85-bd14-4560-8667-875bcff4ab01)

**2. What is the average total historical deposit counts and amounts for all customers?**
```
WITH DS AS (
    SELECT customer_id, COUNT(customer_id) AS count_deposit, AVG(txn_amount) AS amount_deposit
    FROM DB.customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)
SELECT AVG(count_deposit) AS average_count, AVG(amount_deposit) AS average_amount
FROM DS;
```
![image](https://github.com/user-attachments/assets/414eafb5-c6a0-4ae8-ae11-a28ae3198843)

**3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?**
```
WITH DS AS (
    SELECT customer_id, DATEPART(month, txn_date) AS M,
           SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS Count_deposit,
           SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS Count_purchase,
           SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS Count_withdrawal
    FROM DB.customer_transactions
    GROUP BY customer_id, DATEPART(month, txn_date)
)
SELECT M as month, COUNT(*) AS amount_customer
FROM DS
WHERE count_deposit > 1 AND (count_purchase > 1 OR count_withdrawal > 1)
GROUP BY M;
```
![image](https://github.com/user-attachments/assets/32291ce7-a6d6-4ed9-9a73-5d95b266f32c)

**4. What is the closing balance for each customer at the end of the month?**
```
WITH 
DS1 AS (
    SELECT customer_id, DATEPART(month, txn_date) AS monthh,
           SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) AS count_deposit,
           SUM(CASE WHEN txn_type = 'purchase' THEN -txn_amount ELSE 0 END) AS count_purchase,
           SUM(CASE WHEN txn_type = 'withdrawal' THEN -txn_amount ELSE 0 END) AS count_withdrawal
    FROM DB.customer_transactions
    GROUP BY customer_id, DATEPART(month, txn_date)
),
DS2 AS (
    SELECT customer_id, monthh, count_deposit + count_purchase + count_withdrawal AS balance
    FROM DS1
),
DS3 AS (
    SELECT customer_id, monthh, balance, 
           LAG(balance, 1) OVER (PARTITION BY customer_id ORDER BY customer_id) AS pre_balance
    FROM DS2
)
SELECT customer_id, monthh, balance, 
       CASE WHEN pre_balance IS NULL THEN balance ELSE balance - pre_balance END AS chanced_balance
FROM DS3
ORDER BY customer_id;
```
![image](https://github.com/user-attachments/assets/0f53a5d6-97da-4160-b9b2-e1b014f4456c)

**5. What is the percentage of customers who increase their closing balance by more than 5%?**
```
WITH 
DS1 AS (
    SELECT customer_id, DATEPART(month, txn_date) AS monthh,
           SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) AS count_deposit,
           SUM(CASE WHEN txn_type = 'purchase' THEN -txn_amount ELSE 0 END) AS count_purchase,
           SUM(CASE WHEN txn_type = 'withdrawal' THEN -txn_amount ELSE 0 END) AS count_withdrawal
    FROM DB.customer_transactions
    GROUP BY customer_id, DATEPART(month, txn_date)
),
DS2 AS (
    SELECT customer_id, monthh, count_deposit + count_purchase + count_withdrawal AS balance
    FROM DS1
),
DS3 AS (
    SELECT customer_id, monthh, balance, 
           FIRST_VALUE(balance) OVER (PARTITION BY customer_id ORDER BY customer_id) AS opening_balance,
           LAST_VALUE(balance) OVER (PARTITION BY customer_id ORDER BY customer_id DESC) AS ending_balance
    FROM DS2
),
DS4 AS (
    SELECT *, 
           ((ending_balance - opening_balance) * 100 / ABS(opening_balance)) AS growing_rate
    FROM DS3
    WHERE ((ending_balance - opening_balance) * 100 / ABS(opening_balance)) >= 5 AND ending_balance > opening_balance
)
SELECT 
    CAST(COUNT(DISTINCT(customer_id)) AS FLOAT) * 100 /
    (SELECT CAST(COUNT(DISTINCT(customer_id)) AS FLOAT) FROM DB.customer_transactions) AS percentage_of_customer
FROM DS4;
```
![image](https://github.com/user-attachments/assets/56d3209b-e29f-417c-8abf-37c3681d7f61)
