-první období
WITH cte_first_milk_bread AS (
	SELECT 
		date_from, 
		avg_price,
		food_name
	FROM t_tereza_seligova_project_sql_primary_final
	WHERE food_name LIKE 'Mléko%' OR food_name LIKE 'Chléb%'
	ORDER BY date_from ASC 
	LIMIT 2
),
cte_wage AS (
	SELECT 
		DATE_FROM, 
		Avg(avg_wage) AS average_wage
	FROM t_tereza_seligova_project_sql_primary_final
	WHERE food_name LIKE 'Mléko%' OR food_name LIKE 'Chléb%'
	GROUP BY date_from
	ORDER BY date_from ASC
	LIMIT 1
)
	SELECT 
		m.food_name,
		w.date_from,
		w.average_wage,
		m.avg_price,
		ROUND(w.average_wage/m.avg_price) AS amount_of_bought_units
	FROM cte_wage w
	CROSS JOIN cte_first_milk_bread m;
- poslední období
WITH cte_last_milk_bread AS (
	SELECT 
		date_from, 
		avg_price,
		food_name
	FROM t_tereza_seligova_project_sql_primary_final
	WHERE food_name LIKE 'Mléko%' OR food_name LIKE 'Chléb%'
	ORDER BY date_from DESC 
	LIMIT 2
),
cte_wage AS (
	SELECT 
		DATE_FROM, 
		Avg(avg_wage) AS average_wage
	FROM t_tereza_seligova_project_sql_primary_final
	WHERE food_name LIKE 'Mléko%' OR food_name LIKE 'Chléb%'
	GROUP BY date_from
	ORDER BY date_from DESC
	LIMIT 1
)
	SELECT 
		m.food_name,
		w.date_from,
		w.average_wage,
		m.avg_price,
		ROUND(w.average_wage/m.avg_price) AS amount_of_bought_units
	FROM cte_wage w
	CROSS JOIN cte_last_milk_bread m;
		
	


