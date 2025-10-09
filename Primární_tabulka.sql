WITH cte_clear_table AS ( 
	SELECT 
		value,
		industry_branch_code AS sector,
		payroll_year
	FROM czechia_payroll 
	WHERE 1=1
		AND calculation_code = 200
		AND value IS NOT NULL
		AND industry_branch_code IS NOT NULL
		AND value_type_code = 5958	
),
cte_grouped AS (
	SELECT 
		AVG(value) AS avg_value, 
		sector,
		payroll_year
	FROM cte_clear_table
	GROUP BY payroll_year,sector
),
cte_join AS (
	SELECT
		c.payroll_year AS date_from, --bigint 
		c.avg_value, -- numeric 
		b.name AS sector_name -- character varying
	FROM cte_grouped c
	JOIN czechia_payroll_industry_branch  b ON c.sector = b.code
)
SELECT *
FROM cte_join;



CREATE MATERIALIZED VIEW mv_mzdy AS (
	WITH cte_clear_table AS ( 
		SELECT 
			value,
			industry_branch_code AS sector,
			payroll_year
		FROM czechia_payroll 
		WHERE 1=1
			AND calculation_code = 200
			AND value IS NOT NULL
			AND industry_branch_code IS NOT NULL
			AND value_type_code = 5958	
	),
	cte_grouped AS (
		SELECT 
			AVG(value) AS avg_value, 
			sector,
			payroll_year
		FROM cte_clear_table
		GROUP BY payroll_year,sector
	),
	cte_join AS (
		SELECT
			c.payroll_year AS date_from, --bigint 
			c.avg_value, -- numeric 
			b.name AS sector_name -- character varying
		FROM cte_grouped c
		JOIN czechia_payroll_industry_branch  b ON c.sector = b.code
	)
	SELECT *
	FROM cte_join);


	
WITH cte_zkouska_datumu AS (
	SELECT 
		EXTRACT (YEAR FROM date_from) AS date_from,
		EXTRACT (YEAR FROM date_to) AS date_to
 	FROM czechia_price
 )
 SELECT *
 FROM cte_zkouska_datumu
 WHERE date_from != date_to;


WITH cte_clear_table AS (
	 SELECT 
	 	EXTRACT (YEAR FROM date_from) AS date_from,
	 	value,
	 	category_code
	 FROM czechia_price
	 WHERE region_code IS NOT NULL
),
cte_group AS (
	SELECT 
		AVG(value) AS avg_price,
		category_code, 
		date_from
	FROM cte_clear_table
	GROUP BY category_code, date_from
),
cte_join AS ( 
	SELECT 
		g.date_from, --numeric
		g.avg_price, --double precison
		p.name,		-- character varying
		p.price_value, -- double precision
		p.price_unit -- character varying 
	FROM cte_group g
	JOIN czechia_price_category p ON g.category_code = p.code
)
SELECT * 
FROM cte_join;



CREATE MATERIALIZED VIEW mv_ceny AS 
	( WITH cte_clear_table AS (
			 SELECT 
			 	EXTRACT (YEAR FROM date_from) AS date_from,
			 	value,
			 	category_code
			 FROM czechia_price
			 WHERE region_code IS NOT NULL
		),
		cte_group AS (
			SELECT 
				AVG(value) AS avg_price,
				category_code, 
				date_from
			FROM cte_clear_table
			GROUP BY category_code, date_from
		),
		cte_join AS ( 
			SELECT 
				g.date_from, --numeric
				g.avg_price, --double precison
				p.name,		-- character varying
				p.price_value, -- double precision
				p.price_unit -- character varying 
			FROM cte_group g
			JOIN czechia_price_category p ON g.category_code = p.code
			)
	SELECT * 
	FROM cte_join);



CREATE TABLE t_tereza_seligova_project_sql_primary_final AS 
	(SELECT 
		m.date_from,
		avg_value AS avg_wage, 
		sector_name,
		avg_price, 
		name AS food_name ,
		price_value,
		price_unit
	FROM mv_mzdy m
	INNER JOIN mv_ceny c ON m.date_from = c.date_from);
-- zkouším jak vypadá

SELECT *
FROM t_tereza_seligova_project_sql_primary_final;


		
		

		
	
	
		
		
	


