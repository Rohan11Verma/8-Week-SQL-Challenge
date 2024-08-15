/*(SQL 8 Week Challenge)
   Challenge 1               */
/* Danny's Dinner Case Study */

# 1. What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(m.price) as total_amount_spent from sales s
join menu m
on s.product_id=m.product_id
group by customer_id
order by total_amount_spent desc;

# 2. How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as no_of_days_visited from sales s
group by customer_id;

# 3. What was the first item from the menu purchased by each customer?
with cte as (
select s.customer_id, s.order_date, row_number() over(partition by customer_id) as rn, s.product_id
from sales s)
select cte.customer_id, m.product_name from cte 
join menu m on cte.product_id = m.product_id
where rn=1;
 
# 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name as most_purchased_item, count(s.product_id) as frequency_count from sales s
join menu m
on s.product_id = m.product_id
group by product_name
order by frequency_count desc limit 1;

# 5. Which item was the most popular for each customer?
with cte as (select s.customer_id ,m.product_name, count(s.product_id) as frequency_count, rank() over(partition by customer_id order by count(s.product_id) desc) as rnk from sales s
join menu m
on s.product_id = m.product_id
group by customer_id,product_name)
select customer_id, product_name as most_popular_item_for_customer from cte where rnk = 1 
;

# 6. Which item was purchased first by the customer after they became a member?
with cte as
(select s.customer_id, s.order_date, s.product_id, mn.product_name, m.join_date, row_number() over(partition by customer_id order by order_date) as rn from sales s
join menu mn on s.product_id = mn.product_id
join members m on s.customer_id = m.customer_id where s.order_date >= m.join_date)
select cte.customer_id, cte.product_name as first_purchase_as_member from cte where rn = 1;

# 7. Which item was purchased just before the customer became a member?
with cte as 
(select s.customer_id, s.order_date, s.product_id, mn.product_name, m.join_date, rank() over(partition by customer_id order by order_date desc) as rn from sales s
join menu mn on s.product_id = mn.product_id
join members m on s.customer_id = m.customer_id where s.order_date < m.join_date)
select customer_id, product_name from cte where rn = 1
;

# 8. What is the total items and amount spent for each member before they became a member?
with cte as
(select s.customer_id, s.product_id, mn.product_name, mn.price, row_number() over(partition by customer_id) from sales s
join menu mn on s.product_id = mn.product_id
join members m on s.customer_id = m.customer_id where s.order_date < m.join_date)
select customer_id, count(product_name) as total_number_of_items, sum(price) as amount_spent_before_membership from cte group by customer_id;
;

# 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte as 
(select customer_id, m.product_id, product_name, price 
from sales s join menu m on s.product_id = m.product_id)
select customer_id,
sum(case when product_id = 2 or product_id = 3 
     then (price*10)
     else (price*20) 
end) as points
from cte group by customer_id;

/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
   not just sushi - how many points do customer A and B have at the end of January?*/
with cte as 
(select s.customer_id, s.order_date, s.product_id, mb.join_date, m.price, row_number() over(partition by customer_id) as rn from sales s
join members mb on s.customer_id = mb.customer_id
join menu m on s.product_id = m.product_id)
select
customer_id, 
sum(case when order_date < join_date
	 then (case when product_id = 2 or product_id = 3 
		   then (price*10)
           else (price*20) 
	       end)
	 else (price*20)
end) as total_points_in_january
from cte where month(order_date) = 1
group by customer_id
;
   