	--						A. Pizza Metrics

--*1. How many pizzas were ordered?

select count(pizza_id) as TotalPizzaOrder From customer_orders_cleaned

--*2. How many unique customer orders were made?

Select count(distinct customer_id) From customer_orders_cleaned

--*3. How many successful orders were delivered by each runner?

Select runner_Id,count(Order_id) as OrderCount From runner_orders_cleaned 
where duration_mins is not null
group by runner_Id

--*4. How many of each type of pizza was delivered?

Select count(co.Order_Id)as PizzaDelivered,pizza_id
From customer_orders_cleaned CO
join runner_orders_cleaned RO on ro.Order_Id = co.order_id
where duration_mins Is Not Null 
group by pizza_id

--*5. How many Vegetarian and Meatlovers were ordered by each customer?

Select customer_id,count(order_id)as orderCount,pn.pizza_name
From customer_orders_cleaned Co
join pizza_names pn on pn.pizza_id = co.pizza_id
group by customer_id,pn.pizza_id,pn.pizza_name

--*6. What was the maximum number of pizzas delivered in a single order?

Select top 1 co.order_id,count(pizza_id) NumberOfPizzaDelivered
From customer_orders_cleaned Co
join runner_orders_cleaned ro on ro.order_id = co.order_id
where duration_mins Is Not Null 
group by co.order_id
order by count(pizza_id) desc

--*7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

with pizza_changes_counter as (
Select  
co.customer_id,
case when exclusions_cleaned like '%' or extras_cleaned like '%' then 1 else 0 end as PizzaWithChanges,
case when exclusions_cleaned Is Null and extras_cleaned Is Null then 1 else 0 end as PizzaWithNoChanges
From customer_orders_cleaned Co
join runner_orders_cleaned ro on ro.order_id = co.order_id
where duration_mins Is Not Null 
)
Select 
customer_id,
sum(PizzaWithChanges) as PizzaWithChanges,
sum(PizzaWithNoChanges) as PizzaWithNoChanges
from pizza_changes_Counter
group by customer_id

--*8. How many pizzas were delivered that had both exclusions and extras?

with pizza_changes_counter as (
Select  
co.customer_id,
case when exclusions_cleaned like '%' and extras_cleaned like '%' then 1 else 0 end as PizzaWithChanges
From customer_orders_cleaned Co
join runner_orders_cleaned ro on ro.order_id = co.order_id
where duration_mins Is Not Null 
)
Select 
customer_id,
sum(PizzaWithChanges) as PizzaWithChanges
from pizza_changes_Counter
where PizzaWithChanges != 0
group by customer_id


--*9. What was the total volume of pizzas ordered for each hour of the day?

Select 
count(order_id) OrderCount,
Format(order_time, 'HH') as OrderHour
From customer_orders_cleaned Co
Group By Format(order_time, 'HH')


--*10.What was the volume of orders for each day of the week?

Select 
count(order_id) OrderCount,
Datename(WEEKDAY,order_time) as OrderDay
From customer_orders_cleaned Co
Group By Datename(WEEKDAY,order_time)


--						B. Runner and Customer Experience

--*1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

Select 
Count(runner_id) as RunnersCount,
datename(week,registration_date) as week
From runners
group by datename(week,registration_date)


--*2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

Select 
runner_id,
avg(DATEDIFF(Minute, order_time, pick_up_time)) as TimeInMinutes
From runner_orders_cleaned ro
join customer_orders_cleaned co on co.order_id = ro.order_id
group by runner_id

--#3. Is there any relationship between the number of pizzas and how long the order takes to prepare?


--*4. What was the average distance travelled for each customer?

Select 
co.customer_id,
avg(distance_km) as DistanceTravelled
From runner_orders_cleaned ro
join customer_orders_cleaned co on co.order_id = ro.order_id
group by co.customer_id


--*5. What was the difference between the longest and shortest delivery times for all orders?

Select 
MAX(duration_mins) - MIN(duration_mins) as Diffrence
From runner_orders_cleaned

--*6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

Select 
runner_id
,AVG(distance_km) as AvgDistance
,AVG(duration_mins) as AvgDuration
From runner_orders_cleaned
group by runner_id

Yes, as expected.
As the distance increases, the time it takes to deliver an order, increases as well.

--*7. What is the successful delivery percentage for each runner?

with DeliveryCount as(
select runner_id, 
sum(case when distance_km != 0 then 1 else 0 end) as OrderDelivered, 
count(order_id) as TotalOrders
from runner_orders_cleaned
group by runner_id
)
select runner_id,
((OrderDelivered/TotalOrders)*100) as Successfulpercentage 
from DeliveryCount
order by runner_id;



--						C. Ingredient Optimisation

--*1. What are the standard ingredients for each pizza?

Select
pizza_id,
topping_name
From pizza_recipes_cleaned prc
join pizza_toppings pt on pt.topping_id = prc.topping
order by pizza_id


--*2. What was the most commonly added extra?

Select 
extras_cleaned as extras
,COUNT(extras_cleaned) as extras_counted
From customer_orders_cleaned
where extras_cleaned like '%'
and extras_cleaned Is not null
group by extras_cleaned


--*3. What was the most common exclusion?

Select 
exclusions_cleaned as extras
,COUNT(exclusions_cleaned) as extras_counted
From customer_orders_cleaned
where exclusions_cleaned like '%'
group by exclusions_cleaned

--*4. Generate an order item for each record in the customers_orders table in the format of one of the following:
    Meat Lovers

		Select 
		order_id
		,customer_id
		From customer_orders_cleaned
		where pizza_id = 1

	Meat Lovers - Exclude Beef

		Select 
		order_id
		,customer_id
		From customer_orders_cleaned
		where pizza_id = 1
		and exclusions_cleaned = '3' or exclusions_cleaned like '%3%'
		
		There No Order Which has Beef Excluded 


    Meat Lovers - Extra Bacon

		Select 
		order_id
		,customer_id
		From customer_orders_cleaned
		where pizza_id = 1
		and extras_cleaned = '1' or extras_cleaned like '%1%'


    Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

			WITH exc_ext_counter AS (
		SELECT
			order_id,
			customer_id,
		    CASE
				WHEN exclusions_cleaned IN ('1,4') OR exclusions_cleaned LIKE '%1%' OR exclusions_cleaned LIKE '%4%' THEN 1
				WHEN extras_cleaned IN ('6,9') AND extras_cleaned LIKE '%6%' OR extras_cleaned LIKE '%9%' THEN 1
			END AS exc_ext_count
		FROM customer_orders_cleaned
		WHERE pizza_id = 1
		)
		
		SELECT order_id,
		customer_id
		FROM exc_ext_counter
		WHERE exc_ext_count = 1
		GROUP BY order_id,customer_id

--*5. Generate an alphabetically ordered comma separated ingredient list for each pizza 
--   order from the customer_orders table and add a 2x in front of any relevant ingredients
--    For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH exc_ext_bool AS (
	SELECT
	order_id,
	pizza_id,
	exclusions_cleaned,
	extras_cleaned,
	case when CHARINDEX(',', exclusions_cleaned)> 0 then 1 else 0 end AS exclusions_bool,
	case when CHARINDEX(',', extras_cleaned)> 0 then 1 else 0 end AS extras_bool
	FROM customer_orders_cleaned
),
base_exc_ext AS (
SELECT
	eeb.order_id,
    eeb.pizza_id,
	pn.pizza_name,
	case when extras_bool = 0 then extras_cleaned else Null end as base_extras,
	case when exclusions_bool = 0 then exclusions_cleaned else Null end as base_exclusions,
	case when exclusions_bool = 1 then SUBSTRING(exclusions_cleaned, 1,1) else null end as exclusions_1,
	case when exclusions_bool = 1 then SUBSTRING(exclusions_cleaned, 3,3) else null end as exclusions_2,
	case when extras_bool = 1 then SUBSTRING(extras_cleaned, 1,1) else null end as extras_1,
	case when extras_bool = 1 then SUBSTRING(extras_cleaned, 3,3) else null end as extras_2
FROM exc_ext_bool eeb
INNER JOIN pizza_names pn ON eeb.pizza_id = pn.pizza_id
),
m1 AS (
SELECT
    order_id, 
    pizza_id, 
    pizza_name, 
    base_exclusions, 
    base_extras, 
    exclusions_1, 
    topping_name AS exclusions_1_txt,
    exclusions_2, 
    extras_1, 
    extras_2
FROM base_exc_ext
LEFT JOIN pizza_toppings pt ON pt.topping_id = exclusions_1
),
m2 AS (
SELECT 
    order_id, 
    pizza_id, 
    pizza_name, 
    base_exclusions, 
    base_extras, 
    exclusions_1, 
    exclusions_2, 
    extras_1, 
    extras_2, 
    exclusions_1_txt, 
    topping_name AS exclusions_2_txt
FROM m1
LEFT JOIN pizza_toppings pt 
    ON pt.topping_id = exclusions_2
),
m3 AS (
SELECT 
    order_id, 
    pizza_id, 
    pizza_name, 
    base_exclusions, 
    base_extras, 
    exclusions_1, 
    exclusions_2, 
    extras_1, 
    extras_2, 
    exclusions_1_txt, 
    exclusions_2_txt, 
    topping_name AS extras_1_txt
FROM m2
LEFT JOIN pizza_toppings pt 
    ON pt.topping_id = extras_1
),

m4 AS (
SELECT 
    order_id, 
    pizza_id, 
    pizza_name, 
    base_exclusions,
    base_extras,
    exclusions_1,
    exclusions_2,
    extras_1,
    extras_2,
    exclusions_1_txt,
    exclusions_2_txt, 
    extras_1_txt, 
    topping_name AS extras_2_txt
FROM m3
LEFT JOIN pizza_toppings pt 
    ON pt.topping_id = extras_2
),
m5 AS (
SELECT 
    order_id, 
    pizza_id, 
    pizza_name, 
    base_exclusions, 
    base_extras, 
    exclusions_1, 
    exclusions_2, 
    extras_1, 
    extras_2, 
    exclusions_1_txt, 
    exclusions_2_txt, 
    extras_1_txt, 
    extras_2_txt, 
    topping_name AS base_exclusions_1
FROM m4
LEFT JOIN pizza_toppings pt ON pt.topping_id = base_exclusions
),

m6 AS (
SELECT 
    order_id, 
    pizza_id, 
    pizza_name, 
    base_exclusions, 
    base_extras, 
    exclusions_1, 
    exclusions_2, 
    extras_1, 
    extras_2, 
    exclusions_1_txt, 
    exclusions_2_txt, 
    extras_1_txt, 
    extras_2_txt, 
    base_exclusions_1, 
    topping_name AS base_extras_1
FROM m5
LEFT JOIN pizza_toppings pt 
    ON pt.topping_id = base_extras
),
abc_exc_ext AS (
SELECT 
	order_id, 
    pizza_id,
	pizza_name,
    base_exclusions,
    base_extras,
    base_extras_1,
    exclusions_1,
    exclusions_2,
    extras_1,
    extras_2,
CASE
    WHEN base_exclusions_1 IS NULL AND COALESCE(exclusions_1_txt, exclusions_2_txt) IS NOT NULL THEN CONCAT(exclusions_1_txt, ', ', exclusions_2_txt)
    WHEN base_exclusions_1 IS NOT NULL THEN base_exclusions_1
    WHEN COALESCE(base_exclusions_1, exclusions_1_txt, exclusions_2_txt) IS NOT NULL THEN CONCAT(base_exclusions_1, ', ', exclusions_1_txt, ', ', exclusions_2_txt)
END AS exclusions_list,
CASE
    WHEN base_extras_1 IS NULL AND COALESCE(extras_1_txt, extras_2_txt) IS NOT NULL and pizza_id = 1 AND extras_1 in (1,2,3,4,5,6,8,10) AND extras_2 IN (1,2,3,4,5,6,8,10) THEN CONCAT('2x ', extras_1_txt, ', ', '2x ',extras_2_txt)
    WHEN base_extras_1 IS NOT NULL AND pizza_id = 1 AND base_extras IN (1,2,3,4,5,6,7,10) THEN CONCAT('2x ', base_extras_1)
    WHEN base_extras_1 IS NOT NULL THEN base_extras_1
END AS extras_list
FROM m6
)
SELECT
	order_id,
	CASE
	WHEN exclusions_list IS NOT NULL AND extras_list IS NULL THEN CONCAT(pizza_name, ' - ', ' |Exclude| ', exclusions_list)
	WHEN extras_list IS NOT NULL AND exclusions_list IS NULL THEN CONCAT(pizza_name, ' - ', ' |Extras| ' , extras_list)
		WHEN COALESCE(exclusions_list, extras_list) IS NULL THEN pizza_name
	WHEN COALESCE(exclusions_list, extras_list) IS NOT NULL THEN CONCAT(pizza_name, ' - ', ' |Exclude| ', exclusions_list, ' |Extras| ', extras_list)
	END AS pizza_type
FROM abc_exc_ext

--*6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?


WITH topping_list AS (
SELECT
	cr.pizza_id,
	cr.topping,
	pt.topping_name
FROM pizza_recipes_cleaned cr
LEFT JOIN pizza_toppings pt ON cr.topping = pt.topping_id
),

pizza_counter AS (
SELECT
	c.order_id,
	c.pizza_id,
	COUNT(c.pizza_id) AS pizza_count
FROM customer_orders_cleaned c
GROUP BY c.pizza_id,order_id
)

SELECT
	topping_name, 
	COUNT(topping_name) * pizza_count AS total_topping_count
FROM topping_list tl
INNER JOIN pizza_counter PC ON tl.pizza_id = PC.pizza_id
join runner_orders_cleaned ROC on roc.order_id = pc.order_id
where roc.duration_mins Is Not Null
GROUP BY topping_name,pizza_count
ORDER BY total_topping_count DESC


--						D. Pricing and Ratings

--*1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
   how much money has Pizza Runner made so far if there are no delivery fees?

With OrderCount as (
Select 
COUNT(order_id) as OrderCount,
pizza_id
From customer_orders_cleaned
group by pizza_id
)
Select 
sum(case when pizza_id = 1 then OrderCount*12 else OrderCount*10 end) as totalSale
From OrderCount


--*2. What if there was an additional $1 charge for any pizza extras?
--    Add cheese is $1 extra

	With ExtraBoolList as (
	Select 
	order_id,
	pizza_id,
	extras_cleaned,
	case when pizza_id = 1 then 12 else
		 10 end as PizzaCost,
	case when charindex(',' ,extras_cleaned)> 0 then 1 else 0 end as ExtraBool
	From customer_orders_cleaned
	group by pizza_id,order_id,extras_cleaned
	),

	ExtrasList as (
	Select
	order_id,
	PizzaCost,
	Case when ExtraBool = 0 and extras_cleaned Is Not Null then extras_cleaned else null end as BaseExtraCleaned,
	case when ExtraBool = 1 then SUBSTRING(extras_cleaned, 1, 1) else Null end as Extra1,
	case when ExtraBool = 1 then SUBSTRING(extras_cleaned, 3, 3) else Null end as Extra2
	From ExtraBoolList
	)
	Select
	order_id,
	Case 
		When coalesce(BaseExtraCleaned, Extra1, Extra2) Is Null Then PizzaCost 
		When BaseExtraCleaned Is Not Null and coalesce(Extra1, Extra2) Is Null Then  1 + PizzaCost 
		--When BaseExtraCleaned Is Null and coalesce(Extra1, Extra2) Is Not Null Then  2+PizzaCost 
		When BaseExtraCleaned Is Null and Extra1 is not Null and Extra2 != 4 Then  2 + PizzaCost 
		When BaseExtraCleaned Is Null and Extra1 is not Null and Extra2 = 4 Then 3 + PizzaCost 
		Else 0 End as TotalPizzaCost
	From ExtrasList

3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
   how would you design an additional table for this new dataset - generate a schema for this new table and insert
   your own data for ratings for each successful customer order between 1 to 5.

    CREATE TABLE Runner_Ratings
	(
		OrderId int NULL,
		RunnerId int NULL,
		Rating int NULL
	)

	insert into Runner_Ratings
	(OrderId,RunnerId,Rating)
values
	(1,1,4),
	(2,1,3),
	(3,1,5),
	(4,2,2),
	(5,3,4),
	(7,2,5),
	(8,2,3),
	(10,1,5)



4. Using your newly generated table - can you join all of the information together to form a table which has the
   following information for successful deliveries?
    customer_id
    order_id
    runner_id
    rating
    order_time
    pickup_time
    Time between order and pickup
    Delivery duration
    Average speed
    Total number of pizzas


		Select 
	customer_id,
	coc.order_id,
	roc.runner_id,
	Rating,
	order_time,
	pick_up_time,
	(pick_up_time - order_time) as TimeBetweenOrderAndPickup,
	duration_mins
	From customer_orders_cleaned coc
	join runner_orders_cleaned roc on roc.order_id = coc.order_id
	join Runner_Ratings rr on rr.RunnerId =roc.runner_id



5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid 
   $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

With OrderCount as 
(
	Select 
	COUNT(order_id) as OrderCount,
	pizza_id
	From customer_orders_cleaned
	group by pizza_id
),
PizzaCost_CTE as
(
	Select 
	sum(case when pizza_id = 1 then OrderCount*12 else OrderCount*10 end) as totalSale
	From OrderCount OC
),
DeliveryFee_CTE as
(
	select 
	order_id,
	distance_km,
	distance_km * 0.30 as DeliveryFee
	From runner_orders_cleaned
	Where distance_km Is Not Null
),
TotalDeliveryCost_CTE as
(
	Select Sum(DeliveryFee) as TotalDeliveryFee From DeliveryFee_CTE
)
	Select
		totalSale - TotalDeliveryFee
	From PizzaCost_CTE,TotalDeliveryCost_CTE



--						E. Bonus Questions

Q. If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT
   statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?


Because the pizza recipes table was modified to reflect foreign key designation for each topping linked to the base pizza, 
the pizza_id will have multiple 3s and align with the standard toppings (individually) within the toppings column.

In addition, because the data type was casted to an int to take advantage of numerical functions, insertion of data would not
affect the existing data design, unlike the original dangerous approach of comma separated values in a singular row (list)
