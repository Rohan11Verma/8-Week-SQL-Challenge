#Case Study #2 - Pizza Runner
/* ******************************************************************************************* */
/*A. Pizza Metrics */
# 1. How many pizzas were ordered?
SELECT 
    COUNT(order_id) AS no_of_pizzas_ordered
FROM
    customer_orders;
    
# 2. How many unique customer orders were made?
SELECT 
    COUNT(DISTINCT order_id)
FROM
    customer_orders;
    
# 3. How many successful orders were delivered by each runner?
SELECT 
    runner_id, COUNT(order_id)
FROM
    runner_orders
WHERE
    duration IS NOT NULL
GROUP BY runner_id;

# 4. How many of each type of pizza was delivered?
SELECT 
    pizza_id, COUNT(pizza_id) AS number
FROM
    customer_orders c
        JOIN
    runner_orders AS ro ON c.order_id = ro.order_id
WHERE
    ro.duration IS NOT NULL
GROUP BY pizza_id;

# 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
    c.customer_id,
    pn.pizza_name,
    COUNT(pn.pizza_name) AS number_of_pizzas
FROM
    customer_orders c
        JOIN
    pizza_names pn ON c.pizza_id = pn.pizza_id
GROUP BY pizza_name , customer_id
ORDER BY customer_id;

# 6. What was the maximum number of pizzas delivered in a single order?
SELECT 
    order_id, COUNT(pizza_id) AS pizzas_ordered
FROM
    customer_orders
GROUP BY order_id
ORDER BY pizzas_ordered DESC
LIMIT 1;

# 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
/*with cte as 
(select order_id 
from customer_orders
where (exclusions IS NOT NULL
        AND exclusions <> '')
        OR (extras IS NOT NULL AND extras <> 'NaN'
        AND extras <> '')),
	cte_2 as (select order_id
from customer_orders
where (exclusions IS NULL
        or exclusions = '')
        and (extras IS NULL
        or extras <> '' or extras <> " "))
select  c.customer_id, count(cte.order_id) as at_least_1_change, count(cte_2.order_id) as no_change
from customer_orders c
left join cte on cte.order_id = c.order_id
left join cte_2 on cte_2.order_id = c.order_id
join runner_orders r on c.order_id = r.order_id
where r.pickup_time is not null
group by customer_id;*/

# 8. How many pizzas were delivered that had both exclusions and extras?
SELECT 
    COUNT(pizza_id) AS pizzas_with_exclusions_and_extras
FROM
    customer_orders c
        JOIN
    runner_orders ro ON c.order_id = ro.order_id
WHERE
    (c.exclusions IS NOT NULL
        AND exclusions <> 'null'
        AND exclusions <> '')
        AND (c.extras IS NOT NULL AND extras <> 'NaN'
        AND extras <> ''
        AND extras <> 'null')
        AND ro.duration IS NOT NULL;
        
# 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
    CONCAT(HOUR(order_time), ':00') AS hour,
    COUNT(pizza_id) AS volume
FROM
    customer_orders
GROUP BY hour;

# 10. What was the volume of orders for each day of the week?
SELECT 
    dayofweek( order_time) as day_of_week, COUNT(pizza_id) AS volume
FROM
    customer_orders
GROUP BY day_of_week;

/******************************************************************************************/

/* B. Runner and Customer Experience*/
# 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
    COUNT(runner_id) AS number_of_runners,
    WEEK(registration_date + 4) AS week_signed_up
FROM
    runners
GROUP BY week_signed_up;

# 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT 
    runner_id,
    CONCAT(ROUND(AVG(MINUTE(TIMEDIFF(TIMESTAMP(pickup_time),
                                TIMESTAMP(order_time))))),
            ' minutes') AS avg_pickup_time
FROM
    customer_orders c
        JOIN
    runner_orders r ON c.order_id = r.order_id
WHERE
    pickup_time IS NOT NULL
GROUP BY runner_id;

# 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
with cte as
(SELECT 
    c.order_id,
    COUNT(pizza_id) as no_of_pizzas,
    MAX(MINUTE(TIMEDIFF(TIMESTAMP(pickup_time),
                TIMESTAMP(order_time)))) AS prep_time
FROM
    customer_orders c
        JOIN
    runner_orders r ON c.order_id = r.order_id
WHERE
    pickup_time IS NOT NULL
GROUP BY c.order_id)
select no_of_pizzas, avg(prep_time) from cte group by no_of_pizzas;

# 4. What was the average distance travelled for each customer?
SELECT 
    c.customer_id,
    CONCAT(ROUND(AVG(distance)), ' Km') AS avg_distance_travelled
FROM
    customer_orders c
        JOIN
    runner_orders r ON c.order_id = r.order_id
GROUP BY c.customer_id;

# 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT 
    CONCAT(MAX(duration) - MIN(duration), ' mins') AS max_time_gap
FROM
    runner_orders;

# 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
	row_number() over(partition by runner_id) as rn,
    order_id,
    runner_id,
    CONCAT(ROUND(distance*60 / duration), ' Km/hour') AS speed
FROM
    runner_orders
WHERE
    pickup_time IS NOT NULL;

# 7. What is the successful delivery percentage for each runner?
with cte3 as (
with cte as(
select runner_id, 
count(case when pickup_time is null
then (order_id)
else null
end) as no_of_orders_not_delivered
from runner_orders group by runner_id),
cte_2 as (select runner_id, 
count(case when pickup_time is not null
then (order_id)
else null
end) as no_of_orders_delivered
from runner_orders group by runner_id)
select cte.runner_id, no_of_orders_delivered, no_of_orders_not_delivered from cte join cte_2 on cte.runner_id = cte_2.runner_id)
select runner_id,
concat(round((no_of_orders_delivered)*100/(no_of_orders_delivered + no_of_orders_not_delivered)),'%') as success_percent
from cte3;
