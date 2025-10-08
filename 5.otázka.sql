WITH cte_base AS ( 
	SELECT 
		YEAR,
		avg_price,
		avg_wage AS current_wage,
		lag(avg_wage) OVER (ORDER BY year) AS previous_wage,
		avg_price AS current_price,
		lag(avg_price) OVER (ORDER BY year) AS previous_price,
		hdp,
		lag(hdp) OVER (ORDER BY year) AS previous_hdp
	FROM t_seligova_project_sql_secondary_final 
),
	cte_YOY_diff AS(   
	SELECT 
		YEAR,
		avg_price,
		previous_price, 
		current_wage,
		previous_wage,
		((current_wage-previous_wage)/previous_wage)*100 AS diff_per_wage,
		((current_price-previous_price)/previous_price)*100 AS diff_per_price,
		((hdp-previous_hdp)/hdp)*100 AS diff_hdp	
	FROM 
		cte_base		
),
	cte_diff_next_year AS (
	SELECT 
		YEAR,
		diff_per_wage,
		diff_per_price,
		diff_hdp,
		LEAD (diff_per_wage) OVER (ORDER BY year) AS next_year_wage,
		LEAD (diff_per_price) OVER (ORDER BY YEAR) AS next_year_price
	FROM cte_YOY_diff
)	
SELECT 
	corr(diff_hdp, diff_per_wage) AS corr_hdp_wage_same_year,
	corr(diff_hdp, diff_per_price) AS corr_hdp_price_same_year,
	corr(diff_hdp, next_year_wage) AS corr_hdp_wage_next_year,
	corr(diff_hdp, next_year_price) AS corr_hdp_price_next_year
FROM cte_diff_next_year;

