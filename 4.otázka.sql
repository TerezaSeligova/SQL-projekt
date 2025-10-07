WITH cte_wage AS ( 
	SELECT 
		date_from,
		AVG(avg_wage) AS avg_wage
	FROM t_tereza_seligova_project_sql_primary_final 
	GROUP BY date_from
),
	cte_YOY_diff AS (
	SELECT 
		date_from,
		avg_wage,
		LAG(avg_wage) OVER (ORDER BY date_from) AS previous_wage
	FROM cte_wage
),
	cte_diff AS (  ---tohle potom propojuju
	SELECT 
		date_from,
		((avg_wage - previous_wage)/ (previous_wage))*100 AS diff_wage
	FROM cte_YOY_diff 
),
cte_price AS ( 
	SELECT 
		date_from,
		AVG(avg_price) AS avg_price
	FROM t_tereza_seligova_project_sql_primary_final 
	GROUP BY date_from
),
	cte_YOY_diff_price AS (
	SELECT 
		date_from,
		avg_price,
		LAG(avg_price) OVER (ORDER BY date_from) AS previous_price
	FROM cte_price
),
	cte_diff_price AS (  ---tohle potom propojuju
	SELECT 
		date_from,
		((avg_price - previous_price)/ (previous_price))*100 AS diff_price
	FROM cte_YOY_diff_price 
),
	cte_difference_wage_price AS ( 
	SELECT 
		w.date_from,
		p.diff_price - w.diff_wage AS difference_wage_price
	FROM cte_diff_price p 
	JOIN cte_diff w ON p.date_from = w.date_from
)
	SELECT 
		date_from,
		difference_wage_price,
		CASE WHEN difference_wage_price > 10 THEN 'YES'
		ELSE 'NO' END AS result
	FROM cte_difference_wage_price;		
		

		
	
	
		
		
	


