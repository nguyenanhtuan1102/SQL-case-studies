# SQL USE CASE: Danny's Dinner

![cover](https://github.com/user-attachments/assets/8fa22898-b4ab-4f6d-a983-6a2ee99a41f4)

## The Guide

I use Microsoft SQL Sever for this case study walkthrough

1. Create a database
2. Run ```schema.sql``` file in the database
3. Use ```solutions.sql``` file to check the solutions

## The Relationship Diagram

![relationship-diagram](https://github.com/user-attachments/assets/82c3fa1e-47ba-408e-b9a8-4145b5ed2127)

## Questions

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


## Solutions

**1. What is the total amount each customer spent at the restaurant?**
```
SELECT s.customer_id, SUM(me.price) AS "Total amount each customer spent"
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu me ON s.product_id = me.product_id
GROUP BY s.customer_id;
GO
```

![solution-1](https://github.com/user-attachments/assets/c81192cc-4056-478e-aaff-6f79c75d32ef)

**2. How many days has each customer visited the restaurant?**
```
SELECT customer_id, COUNT(DISTINCT order_date) AS "Total days visited"
FROM dannys_diner.sales
GROUP BY customer_id;
GO
```

![solution-2](https://github.com/user-attachments/assets/141c3a8d-8aff-4c2c-af59-d71e4dc7edd3)

**3. What was the first item from the menu purchased by each customer?**
```
WITH PURCHASED_RANK AS (
  SELECT customer_id, 
         order_date,
         product_name, 
         RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) as ranked
  FROM dannys_diner.sales s
  LEFT JOIN dannys_diner.menu me ON s.product_id = me.product_id
)
SELECT DISTINCT customer_id, product_name
FROM PURCHASED_RANK 
WHERE ranked = 1;
GO
```
![solution-3](https://github.com/user-attachments/assets/ba81cb48-4926-4ac0-add0-5eaaecd69604)

**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**
```
SELECT TOP 1 s.product_id, product_name, COUNT(s.product_id) AS "Times it was purchased"
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY [Times it was purchased] DESC;
GO
```

![solution-4](https://github.com/user-attachments/assets/309f5470-e35f-4d7b-b65e-5971997f20f2)

**5. Which item was the most popular for each customer?**
```
WITH ITEM_RANKED AS (
  SELECT customer_id, s.product_id, COUNT(s.product_id) AS "Most_popular_items"
  FROM dannys_diner.sales s
  INNER JOIN dannys_diner.menu m ON s.product_id = m.product_id
  GROUP BY customer_id, s.product_id
),
ITEM_RANKED2 AS (
  SELECT customer_id, product_id, Most_popular_items, 
         RANK() OVER (PARTITION BY customer_id ORDER BY Most_popular_items DESC) AS ranked 
  FROM ITEM_RANKED
)
SELECT customer_id, product_id, Most_popular_items 
FROM ITEM_RANKED2
WHERE ranked = 1;
GO
```

![solution-5](https://github.com/user-attachments/assets/732428bf-1128-4a6d-aaa8-491e3e9b4889)

**6. Which item was purchased first by the customer after they became a member?**
```
WITH RANK_PURCHASED_DATE_ITEM AS (
  SELECT s.customer_id, 
         s.product_id, 
         product_name, 
         order_date, 
         RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date ASC) AS ranked
  FROM dannys_diner.members mb
  INNER JOIN dannys_diner.sales s ON mb.customer_id = s.customer_id
  INNER JOIN dannys_diner.menu me ON me.product_id = s.product_id
  WHERE order_date >= join_date
)
SELECT customer_id, product_id, product_name, order_date 
FROM RANK_PURCHASED_DATE_ITEM
WHERE ranked = 1;
GO
```

![solution-6](https://github.com/user-attachments/assets/d74a1851-995a-46e3-ac67-c3c4f109eb1d)

**7. Which item was purchased just before the customer became a member?**
```
WITH RANK_PURCHASED_DATE_ITEM AS (
  SELECT s.customer_id, 
         s.product_id, 
         product_name, 
         order_date, 
         RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date DESC) AS ranked
  FROM dannys_diner.sales s
  INNER JOIN dannys_diner.members mb ON s.customer_id = mb.customer_id
  INNER JOIN dannys_diner.menu me ON s.product_id = me.product_id
  WHERE order_date < join_date
)
SELECT customer_id, product_id, product_name, order_date 
FROM RANK_PURCHASED_DATE_ITEM
WHERE ranked = 1;
GO
```

![solution-7](https://github.com/user-attachments/assets/48de5b0a-0a84-41e0-b6ed-7e68ae396b30)

**8. What is the total items and amount spent for each member before they became a member?**
```
SELECT s.customer_id,
       COUNT(s.product_id) AS "Total items",
       SUM(me.price) AS "Total amount spent"
FROM dannys_diner.sales s 
INNER JOIN dannys_diner.members mb ON s.customer_id = mb.customer_id
INNER JOIN dannys_diner.menu me ON s.product_id = me.product_id
WHERE join_date > order_date
GROUP BY s.customer_id;
GO
```

![solution-8](https://github.com/user-attachments/assets/6d9757f4-c351-4f19-b41c-2135ea2f8db0)

**9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**
```
SELECT s.customer_id,
       SUM(
         CASE
           WHEN me.product_name = 'sushi' THEN me.price * 2 * 10
           ELSE me.price * 10
         END
       ) AS Points
FROM dannys_diner.sales s
FULL OUTER JOIN dannys_diner.menu me ON s.product_id = me.product_id
GROUP BY s.customer_id;
GO
```

![solution-9](https://github.com/user-attachments/assets/bc603779-97e7-43f5-a7b0-7e1d267d5b38)

**10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**
```
SELECT s.customer_id,
       SUM(
         CASE
           WHEN me.product_name = 'sushi' THEN me.price * 2 * 10
           WHEN ((order_date >= join_date) AND (order_date <= DATEADD(DAY, 7, join_date))) THEN me.price * 2 * 10
           ELSE me.price * 10
         END
       ) AS Points
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu me ON s.product_id = me.product_id
INNER JOIN dannys_diner.members mb ON s.customer_id = mb.customer_id
WHERE (s.customer_id = 'A' OR s.customer_id = 'B') AND MONTH(order_date) <= 1
GROUP BY s.customer_id;
GO
```

![solution-10](https://github.com/user-attachments/assets/007647f3-fb45-4f11-a09c-4c8440dbefed)
