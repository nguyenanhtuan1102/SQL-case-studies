-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(me.price) AS "Total amount each customer spent"
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu me ON s.product_id = me.product_id
GROUP BY s.customer_id;
GO

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS "Total days visited"
FROM dannys_diner.sales
GROUP BY customer_id;
GO

-- 3. What was the first item from the menu purchased by each customer?
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

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 s.product_id, product_name, COUNT(s.product_id) AS "Times it was purchased"
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY [Times it was purchased] DESC;
GO

-- 5. Which item was the most popular for each customer?
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

-- 6. Which item was purchased first by the customer after they became a member?
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

-- 7. Which item was purchased just before the customer became a member?
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

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id,
       COUNT(s.product_id) AS "Total items",
       SUM(me.price) AS "Total amount spent"
FROM dannys_diner.sales s 
INNER JOIN dannys_diner.members mb ON s.customer_id = mb.customer_id
INNER JOIN dannys_diner.menu me ON s.product_id = me.product_id
WHERE join_date > order_date
GROUP BY s.customer_id;
GO

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
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

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
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
