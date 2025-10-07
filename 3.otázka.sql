WITH cte_prices AS 
	(SELECT 
	date_from,
	AVG(avg_price) AS avg_price_food,
	food_name
	FROM t_tereza_seligova_project_sql_primary_final
	GROUP BY date_from, food_name
),
	cte_previous_price AS (
	SELECT 
		date_from, 
		avg_price_food, 
		lag(avg_price_food) OVER (PARTITION BY food_name ORDER BY date_from) AS previous_price,
		food_name
	FROM cte_prices
),
	cte_percentage AS ( 
	SELECT 
		date_from, 
		previous_price,
		avg_price_food,
		food_name,
		((avg_price_food - previous_price) / previous_price)*100  AS percentage_of_grow
	FROM cte_previous_price 
)
SELECT 
	food_name,
	AVG(percentage_of_grow) AS total_grow_percentage
FROM cte_percentage
GROUP BY food_name
ORDER BY total_grow_percentage ASC;


		
		

		
	
	
		
		
	


