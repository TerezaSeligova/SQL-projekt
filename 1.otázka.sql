WITH cte_prepare AS (
		SELECT 
			date_from,
			AVG(avg_wage) AS avg_wage,
			sector_name 
		FROM t_tereza_seligova_project_sql_primary_final
		GROUP BY date_from, sector_name
),
	cte_previous_wage AS ( 
		SELECT 
			date_from,
			avg_wage,
			LAG(avg_wage) OVER (PARTITION BY sector_name ORDER BY date_from) AS previous_wage,
			sector_name
		FROM cte_prepare
),
	cte_diff AS (
		SELECT 
			date_from, 
			avg_wage, 
			previous_wage,
			avg_wage - previous_wage AS difference,
			sector_name
		FROM cte_previous_wage
),
	cte_result AS ( 
		SELECT 
			date_from,
			sector_name,
			CASE WHEN difference > 0 THEN 'INCREASING'
				WHEN difference < 0 THEN 'DECREASING'
				ELSE 'STAGNACE' 
				END AS outcome
		FROM cte_diff
)
SELECT * 
FROM cte_result
WHERE outcome = 'DECREASING'
ORDER BY date_from;
			
	


		
	
	
		
		
	


