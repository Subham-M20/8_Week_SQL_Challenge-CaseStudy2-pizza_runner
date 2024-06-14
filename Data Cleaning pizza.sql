CREATE TABLE [dbo].[runners](
	[runner_id] [int] NULL,
	[registration_date] [date] NULL
) 

INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');

DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);


select 
 order_id
 ,customer_id
 ,pizza_id
 ,Case	When exclusions = '' Then Null
		When exclusions = 'null' Then Null
  Else exclusions end as exclusions_cleaned
 ,Case	When extras = '' Then Null
		When extras = 'null' Then Null
  Else extras end as extras_cleaned
 ,order_time
into customer_orders_cleaned 
From customer_orders

--Function For remove all lower case latters

CREATE FUNCTION dbo.RemoveLowercaseLetters (@input NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @position INT = 1;
    DECLARE @output NVARCHAR(MAX) = @input;
    DECLARE @char NCHAR(1);

    -- Loop through each character in the string
    WHILE @position <= LEN(@output)
    BEGIN
        SET @char = SUBSTRING(@output, @position, 1);

        -- Check if the character is a lowercase letter
        IF @char LIKE '[a-z]'
        BEGIN
            -- Remove the character
            SET @output = STUFF(@output, @position, 1, '');
        END
        ELSE
        BEGIN
            -- Move to the next character
            SET @position = @position + 1;
        END
    END

    RETURN @output;
END;


SELECT
	order_id,
	runner_id,
	CASE
		WHEN pickup_time = 'null' THEN null
		ELSE pickup_time
	END AS pick_up_time,
	CASE
		WHEN distance = 'null' THEN null
		ELSE dbo.RemoveLowercaseLetters(distance)
	END AS distance_km,
	CASE
		WHEN duration = 'null' THEN null
		ELSE dbo.RemoveLowercaseLetters(duration)
		END AS duration_mins,
	CASE
		WHEN cancellation = '' THEN null
		WHEN cancellation = 'null' THEN null
		ELSE cancellation
		END AS cancellation               
	into runner_orders_post 
FROM runner_orders


SELECT
		order_id,
		runner_id,
		pick_up_time,
		CAST(distance_km AS DECIMAL(3,1)) AS distance_km, 
		CAST(duration_mins AS Integer) AS duration_mins,
		cancellation
		into runner_orders_cleaned
FROM runner_orders_post;

Select
	pizza_id
	,cast(toppings as varchar) as toppings_Var
  into pizza_recipes_pre
From pizza_recipes

WITH ToppingCTE AS (
    SELECT 
        pizza_id,
        CAST(SUBSTRING(toppings_var + ',', 1, CHARINDEX(',', toppings_Var + ',') - 1) AS INT) AS topping,
        CAST(SUBSTRING(toppings_Var + ',', CHARINDEX(',', toppings_Var + ',') + 1, LEN(toppings_Var)) AS NVARCHAR(MAX)) AS remaining_toppings
    FROM 
        pizza_recipes_pre
    UNION ALL
    SELECT 
        pizza_id,
        CAST(SUBSTRING(remaining_toppings, 1, CHARINDEX(',', remaining_toppings) - 1) AS INT),
        CAST(SUBSTRING(remaining_toppings, CHARINDEX(',', remaining_toppings) + 1, LEN(remaining_toppings)) AS NVARCHAR(MAX))
    FROM 
        ToppingCTE
    WHERE 
        LEN(remaining_toppings) > 0
)
SELECT 
    pizza_id, 
    topping
  into pizza_recipes_cleaned
FROM 
    ToppingCTE
ORDER BY 
    pizza_id, topping;






