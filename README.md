# SQL-projekt
Dostupnost základních potravin v ČR vs. mzdy

**Technologie:** PostgreSQL

**Úvod do projektu**
Na analytickém oddělení nezávislé společnosti, která se zabývá životní úrovní občanů, jste se dohodli, že se pokusíte odpovědět na pár definovaných výzkumných otázek, které adresují dostupnost základních potravin široké veřejnosti. Kolegové již vydefinovali základní otázky, na které se pokusí odpovědět a poskytnout tuto informaci tiskovému oddělení. Toto oddělení bude výsledky prezentovat na následující konferenci zaměřené na tuto oblast.

**Výzkumné otázky**
1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší procentuální meziroční nárůst)?
4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

**Cíl projektu**
Zodpovědět na dané otázky za cílem co nejpřesněji zab

**K zodpovězení výše uvedených otázek byly připraveny 2 tabulky.**
Primární tabulka t_tereza_seligova_project_sql_primary_final obsahuje robustní datové podklady, ve kterých je možné vidět porovnání dostupnosti potravin na základě průměrných příjmů za určité časové období. Struktura tabulky:
date_from - sloupec obsahuje rok, ve kterém jsou data získána
avg_wage - sloupec obsahuje průměrnou mzdu za dané období
sector_name - sloupec obsahuje název odvětví
avg_price - sloupec obsahuje průměrnou cenu potravin
food_name - sloupec obsahuje název potravin 
price_value - sloupec obsahuje základní hodnotu, ve které jsou potraviny uváděny
price_unit - sloupec obsahuje název měrné jednotky, ve které jsou potraviny uváděny.

Primární tabulka vznikla spojením faktových a dimenzních tabulek, které byly následující: czechia_price, czechia_payroll, czechia_price_category, czechia_payroll_industry_branch, czechia_payroll_calculation. Při spojování tabulek bylo nejdříve využito zredukování dat na data, která jsou nezbytná pro výpočet daných otázek. Postup byl následující:
U faktové tabulky mezd jsem postupovala následovně:
  - odstranila jsem unit_code, který vysvětloval jendotku měny, se kterou následně operuji při vysvětlení. Pro zjištění průměrných mezd jsem počítala s přepočtenými hodnotami, abych dále zabezpečila jednotkou strukturu.
  - v prvním kroku čistím data a zjednodušuji pomocí CTE, odstraňují NULL hodnoty ve sloupci value, filtruji pouze přepočtené hodnoty a průměrnou hrubou mzdu na zaměstnance, jelikož se mi kříží u unit_code jednotka měny s počtem zaměstnanaců, počítám bez unit_code,
  - poté groupuji jednotlivá čtvrtletí na roky a na odvětví (sector) abych měla stejnou časovou osu společně s ceny potravin a zároveň i počítám průměrnou mzdu u jednotlivých let
  - třetí krok je join, kde spojuji industry_branch_code se zkratkami, které mám ve faktové tabulce czechia_payroll
  - 4. krok je již klauzule SELECT, kde mám zredukovanou tabulku z 8 sloupců na 3
  - vytvářím materializované view, abych měla zjednodušenou tabulku, nicméně musím dávat pozor, abych ji případně nezapomínala obnovovat
U faktové tabulky cen byl postup následovný:
  - jelikož jsem měla 2 sloupce s daty, kdy byly data sesbírány musela jsem nejdříve zjistit zda se mi neliší v řádcích roky -> zjistila jsem, že si mi dané roky neliší
  - v druhém kroku jsem si už za pomocí CTE extrahovala pouze rok a odstraňovala NULL hodnoty u region code, aby nedocházelo ke zkreslení neúplných hodnot
  - v třetím kroku jsem počítala průměrné ceny za jednotlivá období příčemž jsem zde již i groupovala podle kategorie a datumu
  - v 4. kroku jsem stejně jako ve mzdách udělala join mezi posledními kroky, aby operace nebyla tak náročná - u join jsem si přepsala zkratky u názvů potravin an celé názvy
  - vytvářím materializované view
Spojuji 2 materializované view a vytvářím tabulku z údajů přes INNER JOIN, kde se mi protínají hodnoty za období 2006-2018.

**Odpovědi na otázky**
1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
     V některých odvětvích v průběhu let mzdy kelsají, například Zemědělství, lesnictví, rybářství v roce 2009 nebo
   
3. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
   
     Za první období (2006) je možné si koupit 1466 litrů mléka a 1313 kg chleba. Při výpočtu jsem využívala CTE pro napočítávání jednotlivých hodnot a postupovala jsem krok po kroku, aby dotaz byl přehledný. Zároveň jsem si vždy zjistila jaký rok je ten první. 
     Za poslední (2018) období je možné si zakoupit 1670 litrů mléka a 1365 kg chleba. Při výpočtu jsem postupovala stejně jako za období 2006, měnila jsem pouze ASC na DESC.
   
3.Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
    
    Cukr krystalový zdražuje nejpomaleji, celkově zde dokonce dochází i ke zlevnění. Naopak nejvíce zdražují papriky. K výpočtu jsem zde kromě CTE na napočítávání hodnot a přehlednosti využívala i window functions, kde jsem si za pomocí funkce LAG zapsala předešlou hodnotu. Pak jsem již využila vzorec pro zjištění meziroční hodnoty a seřadila si jednotlivé výsledky sestupně, aby se mi na první hodnotě ukázala nejnižší hodnota.
    
4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
   
    Tento rok neexistuje, nejvyšší hodnoty jsou v roce 2013, kdy docházelo k 6% rozdílu cen a mezd, nicméně ostatní roky se pohybujeme v záporných %, tzn. že u mezd docházelo v průměru k vyššímu nárůstu, než u cen. K zjištění výsledku jsem využívala CTE, přičemž prvním kroku jsem využila vypočítání průměru mzdy za jendotlivé roky, poté jsem využívala k zjištění předchozí hodnoty funkci LAG, při následným kroku jsem napočítávala procentuální změnu a to jak pro mzdu, tak i pro ceny, u kterých jsem počítala s LAG, konečný výsledek jsem si přes podmínku CASE WHEN vydefinovala jaké hodnoty jsou ty, které mi splňují danou podmínku.

5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

   Vliv HDP na změny ve mzdách má. Nejvýrazněji koreluje změna HDP se změnou mzdy v následujícím roce. Tudíž pokud vzroste HDP v jednom roce, mzda vzroste v následujícím roce. Naopak nejmenší korelace, tedy spíše žádný vztah je u HDP a cen potravin v následujícím roce. Výsledky zde vycházejí v záporných hodnotách a velmi blízko nule. Přičemž na cenu potravin v daném roce má HDP vliv. Hodnota je zde kladná a blíží se 1, přičemž, ale stále nejvíce koreluje mzda v následujícícm roce s HDP. 
     


