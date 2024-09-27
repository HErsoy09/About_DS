CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
 -----------------------------------------
 
 -- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price)
FROM sales s
	JOIN menu m ON s.product_id = m.product_id 
GROUP BY s.customer_id; 


-- 2. How many days has each customer visited the restaurant?
SELECT s.customer_id, COUNT(DISTINCT s.order_date)
FROM sales s 
GROUP BY s.customer_id


-- 3. What was the first item from the menu purchased by each customer?
SELECT DISTINCT 
	s.customer_id, s.order_date, m.product_name	
FROM sales s 
	JOIN menu m ON s.product_id = m.product_id
ORDER BY s.order_date 
LIMIT 3;


-- Farklı Yol
WITH tablo AS(
SELECT
	s.customer_id, s.order_date, m.product_name,
	ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date),
	RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date),
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS dr
FROM sales s 
	JOIN menu m ON s.product_id = m.product_id
)
SELECT customer_id, product_name
FROM tablo
WHERE dr = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(m.product_name) 
FROM sales s
	JOIN menu m ON s.product_id = m.product_id 
GROUP BY m.product_name 
ORDER BY COUNT(m.product_name) DESC
LIMIT 1;


-- 5. Which item was the most popular for each customer?
WITH tablo AS(
SELECT s.customer_id, m.product_name, COUNT(m.product_name) AS total,
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(m.product_name) DESC) AS dr
FROM sales s 
	JOIN menu m ON s.product_id = m.product_id 
GROUP BY s.customer_id, m.product_name)
SELECT customer_id, product_name, total
FROM tablo
WHERE dr = 1;


-- 6. Which item was purchased first by the customer after they became a member?
WITH tablo AS(
SELECT s.customer_id, s.order_date, m.product_name,
	ROW_NUMBER() OVER(PARTITION BY mb.customer_id ORDER BY s.order_date) AS rn
FROM sales s 
	JOIN members mb ON s.customer_id = mb.customer_id
	JOIN menu m ON s.product_id = m.product_id 
WHERE s.order_date >= mb.join_date 
ORDER BY s.customer_id, s.order_date
)
SELECT customer_id, product_name
FROM tablo
WHERE rn = 1


-- 7. Which item was purchased just before the customer became a member?
WITH tablo AS(
SELECT s.customer_id, s.order_date, m.product_name,
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS dr
FROM sales s 
	JOIN menu m ON s.product_id = m.product_id 
	JOIN members mb ON s.customer_id = mb.customer_id 
WHERE s.order_date < mb.join_date
)
SELECT customer_id, product_name
FROM tablo
WHERE dr = 1;


-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(s.product_id), SUM(m.price)
FROM sales s 
	JOIN menu m ON s.product_id = m.product_id 
	JOIN members mb ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id 
ORDER BY s.customer_id;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id,
	SUM(CASE
		WHEN m.product_name = 'sushi' THEN m.price * 10 * 2
		ELSE m.price * 10
	END
	) AS points
FROM sales s
	JOIN menu m ON s.product_id = m.product_id 
GROUP BY s.customer_id
ORDER BY points DESC


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH tablo AS(
SELECT s.customer_id, s.order_date, mb.join_date, m.product_name, m.price 
FROM sales s 
	JOIN menu m ON s.product_id = m.product_id 
	JOIN members mb ON s.customer_id = mb.customer_id
WHERE s.order_date BETWEEN mb.join_date AND '2021-01-31'
ORDER BY s.customer_id, s.order_date 
)
SELECT customer_id,
	SUM(CASE 
		WHEN order_date < (join_date + 7) THEN price * 10 * 2
		WHEN product_name = 'sushi' THEN price * 10 * 2
		ELSE price * 10
	END) AS points	
FROM tablo
GROUP BY customer_id


-- BONUS
--1. Recreate the following table output using the available data: customer_id, order_date, product_name, price, member
CREATE VIEW V_tablo AS(
SELECT s.customer_id, s.order_date, m.product_name, m.price,
	CASE 
		WHEN s.order_date >= mb.join_date THEN 'Y'
		ELSE 'N'
	END AS ismember
FROM sales s 
	JOIN menu m ON s.product_id = m.product_id
	LEFT JOIN members mb ON s.customer_id = mb.customer_id
ORDER BY customer_id, order_date
)

SELECT *
FROM V_tablo

--2. Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
CREATE OR REPLACE VIEW V_tablo AS(
SELECT s.customer_id, s.order_date, m.product_name, m.price,
	CASE 
		WHEN s.order_date >= mb.join_date THEN 'Y'
		ELSE 'N'
	END AS ismember,
	CASE 
		WHEN s.order_date >= mb.join_date THEN
			DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date)
		ELSE null
	END AS ranking
FROM sales s 
	JOIN menu m ON s.product_id = m.product_id
	LEFT JOIN members mb ON s.customer_id = mb.customer_id
ORDER BY customer_id, order_date
)

SELECT * FROM v_tablo








