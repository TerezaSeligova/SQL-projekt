SELECT *
FROM t_tereza_seligova_project_sql_primary_final 

CREATE TABLE seligova_project_SQL_secondary_final AS (
SELECT
	YEAR,
	ROUND(AVG(t.avg_wage)) AS avg_wage,
	ROUND(AVG(t.avg_price)) AS avg_price,
	gdp AS HDP
FROM economies e
LEFT JOIN t_tereza_seligova_project_sql_primary_final t ON t.date_from = e.year
WHERE e.YEAR BETWEEN 2006 AND 2018
	AND e.country ILIKE '%czech%'
GROUP BY 
	YEAR, 
	gdp)

