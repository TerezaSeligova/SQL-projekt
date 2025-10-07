
-- odstranila jsem unit_code, který budu vysvětlovat, že ho poté doplním jako text, a to buď do popisu nebo jako další sloupec, čistila jsem tabulku a join jsem udělala naposledy, jelikož je to nejnákladnější operace na zprocesování 
-- tohle je vyčištěná tabulka pro sjednocení - mzdy zde hrajou hlavní roli
-- jsou pro mě nejdůležitější  přepočítané mzdy a průměrná hrubá mzda na zaměstnance, mám to ve stejných jednotkách
-- tady vytahuji informace, které potřebuji, čtvrtletí již nedávám, protože to budu groupovat níže
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

-- sjednotit ceny 
-- nejdřív si zjistím, jestli mi datum nazasahuje do jiného roku, jelikož pracuji na úrovni let
-- zjistila jsem, že mi žádné rozmezí nezasahuje do dalšího roku, tím pádem si mohu vzít jen jedno datum a vyextrahovat z toho pouze rok 
WITH cte_zkouska_datumu AS (
	SELECT 
		EXTRACT (YEAR FROM date_from) AS date_from,
		EXTRACT (YEAR FROM date_to) AS date_to
 	FROM czechia_price
 )
 SELECT *
 FROM cte_zkouska_datumu
 WHERE date_from != date_to;

-- zjistím si jaké hodnoty potřebuji k tomu, abych mohla spojit cenu tabulek se mzdou
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

	---vxtvořím si materialized view 
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

--- vyberu si z toho všechny hodnoty co potřebuji, abych si mohla vytvořit tabulku, zároveň ještě přetypuju hodnoty na stejný typ

SELECT 
	m.date_from,
	avg_value AS avg_wage, 
	sector_name,
	avg_price:: numeric, 
	name,
	price_value,
	price_unit
FROM mv_mzdy m
INNER JOIN mv_ceny c ON m.date_from = c.date_from;

--- tohle je mazání předchozích tabulek---

DROP VIEW IF EXISTS tabulka_pro_1_otazku;
DROP VIEW IF EXISTS tabulka_pro_3_otazku;
DROP VIEW IF EXISTS tabulka_pro_3_otazku;
DROP VIEW IF EXISTS tabulka_pro_4_otazku;

DROP TABLE IF EXISTS t_tereza_seligova_project_sql_primary_final;

DROP MATERIALIZED VIEW IF EXISTS mzdy;
DROP MATERIALIZED VIEW IF EXISTS ceny;

----

-- vytvořím si tabulku primární -- mám tam inner join 
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

--- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
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
			LAG(avg_wage) OVER (Partition BY sector_name ORDER BY date_from) AS previous_wage,
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
			
		--- v některých odvětvích mzdy klesají meziročně klesají
-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
-- mléko - za nejstarší období
WITH cte_milk AS (
	SELECT 
		date_from, 
		avg_price,
		food_name
	FROM t_tereza_seligova_project_sql_primary_final
	WHERE food_name = 'Mléko polotučné pasterované'
	ORDER BY date_from ASC 
	LIMIT 1
),
cte_wage AS (
	SELECT 
		DATE_FROM, 
		Avg(avg_wage) AS average_wage
	FROM t_tereza_seligova_project_sql_primary_final
	WHERE food_name = 'Mléko polotučné pasterované'
	GROUP BY date_from
	ORDER BY date_from ASC
	LIMIT 1
)
	SELECT 
		w.date_from,
		w.average_wage,
		m.avg_price,
		w.average_wage/m.avg_price AS amount_of_milk
	FROM cte_wage w
	CROSS JOIN cte_milk m;
		
-- chléb - za nejdřívější období
WITH cte_bread AS (
	SELECT 
		date_from, 
		avg_price,
		food_name
	FROM t_tereza_seligova_project_sql_primary_final
	WHERE food_name = 'Chléb konzumní kmínový'
	ORDER BY date_from DESC 
	LIMIT 1
),
cte_wage AS (
	SELECT 
		DATE_FROM, 
		Avg(avg_wage) AS average_wage
	FROM t_tereza_seligova_project_sql_primary_final
	WHERE food_name = 'Chléb konzumní kmínový'
	GROUP BY date_from
	ORDER BY date_from DESC
	LIMIT 1
)
	SELECT 
		w.date_from,
		w.average_wage,
		b.avg_price,
		w.average_wage/b.avg_price AS amount_of_bread
	FROM cte_wage w
	CROSS JOIN cte_bread b;
	
	-- chléb - za nejstarší období
WITH cte_bread AS (
	SELECT 
		date_from, 
		avg_price,
		food_name
	FROM t_tereza_seligova_project_sql_primary_final
	WHERE food_name = 'Chléb konzumní kmínový'
	ORDER BY date_from DESC 
	LIMIT 1
),
cte_wage AS (
	SELECT 
		DATE_FROM, 
		Avg(avg_wage) AS average_wage
	FROM t_tereza_seligova_project_sql_primary_final
	WHERE food_name = 'Chléb konzumní kmínový'
	GROUP BY date_from
	ORDER BY date_from DESC
	LIMIT 1
)
	SELECT 
		w.date_from,
		w.average_wage,
		b.avg_price,
		w.average_wage/b.avg_price AS amount_of_bread
	FROM cte_wage w
	CROSS JOIN cte_bread b;	
	
-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 
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

---Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
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
		ELSE 'NO' END AS RESULT
	FROM cte_difference_wage_price;
		
		

		
	
	
		
		
	


