
-- 1 What is the total amount each customer spent at the restaurant? 
SELECT 
    customer_id, SUM(m.price) AS total_spent
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY customer_id;

-----------------------------------------------------------------------------------------------------------------------------------------------

-- 2 How many days has each customer visited the restaurant?
SELECT 
    customer_id, COUNT(DISTINCT order_date) AS days_visited
FROM
    sales
GROUP BY customer_id; 

------------------------------------------------------------------------------------------------------------------------------------------------

-- 3 What was the first item from the menu purchased by each customer?
with cte as (
select s.customer_id ,order_date, s.product_id ,m.product_name, rank() over(partition by s.customer_id order by order_date) as rn from sales s 
join menu m on s.product_id=m.product_id)
select customer_id,  product_name from  cte where rn=1;

-------------------------------------------------------------------------------------------------------------------------------------------------

-- 4 What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
    m.product_name, COUNT(s.product_id) AS total_purchase
FROM
    menu m
        JOIN
    sales s ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY COUNT(s.product_id) DESC
LIMIT 1; 

--------------------------------------------------------------------------------------------------------------------------------------------------

-- 5  Which item was the most popular for each customer?

with cte as
(select product_name ,customer_id ,count(product_name) as order_count ,rank() over(partition by customer_id order by count(m.product_name)desc ) as rn  from sales s join menu m on s.product_id=m.product_id 
group by customer_id,product_name)
select distinct  (customer_id),product_name,order_count from cte where rn=1 ;

---------------------------------------------------------------------------------------------------------------------------------------------------

-- 6 Which item was purchased first by the customer after they became a member?
with cte as (SELECT 
    menu.product_name,sales.customer_id,dense_rank() over(partition by sales.customer_id order by order_date ) as rn 
FROM
    menu
        JOIN
    sales ON sales.product_id = menu.product_id
        JOIN
    members ON sales.customer_id = members.customer_id 
WHERE
    sales.order_date > members.join_date
   )
   select distinct customer_id,product_name from cte where rn=1 ;

-----------------------------------------------------------------------------------------------------------------------------------------------------
    
-- 7 Which item was purchased just before the customer became a member?
with cte as (SELECT 
    menu.product_name,sales.customer_id,dense_rank() over(partition by sales.customer_id order by order_date desc ) as rn 
FROM
    menu
        JOIN
    sales ON sales.product_id = menu.product_id
        JOIN
    members ON sales.customer_id = members.customer_id 
WHERE
    sales.order_date < members.join_date
   )
   select distinct customer_id,product_name from cte where rn=1 ;

-------------------------------------------------------------------------------------------------------------------------------------------------------

-- 8 What is the total items and amount spent for each member before they became a member?
SELECT 
    s.customer_id,
    COUNT(s.product_id) AS total_items_purchased,
    SUM(m.price) AS amt_spent
FROM
    sales s
        INNER JOIN
    menu m ON s.product_id = m.product_id
        INNER JOIN
    members mem ON s.customer_id = mem.customer_id
WHERE
    s.order_date < mem.join_date
GROUP BY s.customer_id;

--------------------------------------------------------------------------------------------------------------------------------------------------------

-- 9 if each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
    customer_id,
    SUM(CASE
        WHEN product_name = 'sushi' THEN price * 20
        ELSE price * 10
    END) AS total_points
FROM
    sales
        JOIN
    menu ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;

---------------------------------------------------------------------------------------------------------------------------------------------------------

-- 10  In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
 SELECT 
    sales.customer_id,
    SUM(CASE
        WHEN
            sales.order_date BETWEEN members.join_date AND DATE_ADD(members.join_date,
                INTERVAL 6 DAY)
        THEN
            menu.price * 20
    END)AS points
FROM
    sales
        JOIN
    menu ON sales.product_id = menu.product_id
        JOIN
    members ON sales.customer_id = members.customer_id
WHERE
    order_date <= '2021-01-31'
GROUP BY sales.customer_id;

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Bonus questions
-- 1
SELECT 
    s.customer_id,
    order_date,
    product_name,
    price,
    CASE
        WHEN mem.join_date <= s.order_date THEN 'Y'
        ELSE 'N'
    END AS Member
FROM
    sales s
        LEFT JOIN
    menu m ON s.product_id = m.product_id
        LEFT JOIN
    members mem ON s.customer_id = mem.customer_id;


-- 2
with ifmember as(
SELECT 
    s.customer_id,
    order_date,
    product_name,
    price,
    CASE
        WHEN mem.join_date <= s.order_date THEN 'Y'
        ELSE 'N'
    END AS Member
FROM
    sales s
        LEFT JOIN
    menu m ON s.product_id = m.product_id
        LEFT JOIN
    members mem ON s.customer_id = mem.customer_id)
select customer_id,order_date,product_name ,price,Member,case when Member='N' then null else rank() over(partition by s.customer_id,Member  order by order_date  )end as ranking from ifmember ;

