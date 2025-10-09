# SQL-projekt
Dostupnost základních potravin a porovnání mezd v ČR

**Technologie:** PostgreSQL

##  **Úvod do projektu**

Na analytickém oddělení nezávislé společnosti, která se zabývá životní úrovní občanů, jste se dohodli, že se pokusíte odpovědět na pár definovaných výzkumných otázek, které adresují dostupnost základních potravin široké veřejnosti. Kolegové již vydefinovali základní otázky, na které se pokusí odpovědět a poskytnout tuto informaci tiskovému oddělení. Toto oddělení bude výsledky prezentovat na následující konferenci zaměřené na tuto oblast.

##  **Výzkumné otázky**
1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší procentuální meziroční nárůst)?
4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

##  **Cíl projektu**

Cílem projektu je **zodpovědět výše uvedené otázky** a analyzovat, jak se v průběhu času mění mzdy, ceny potravin a jejich vzájemná dostupnost na území České republiky.

### **K zodpovězení výše uvedených otázek byly připraveny 2 tabulky.**


#### **Primární tabulka** 

  Vznikla spojením faktových a dimenzních tabulek czechia_price, czechia_payroll, czechia_price_category, czechia_payroll_industry_branch a czechia_payroll_calculation.
Nejdříve byla data zredukována pouze na hodnoty potřebné pro výpočty výzkumných otázek.

U **dat o mzdách** proběhlo čištění a úprava pomocí CTE – odstranění NULL hodnot, odstranění unit_code (přiřazení jednotek bylo protichůdné a matoucí, nicméně s jednotkami je počítáno), filtrování přepočtených hodnot a výběr přepočteného průměrné hrubé mzdy na zaměstnance. Dále byla data agregována z čtvrtletí na roky a odvětví,   doplněna o názvy sektorů a převedena do materializovaného pohledu pro jednodušší práci.
    
U **dat o cenách** byly zkontrolovány a sjednoceny roky, odstraněny chybějící hodnoty regionů a pomocí CTE vypočítány průměrné ceny potravin podle kategorií a let. Stejně jako u mezd vznikl materializovaný pohled, který byl následně spojen s předešlým pomocí INNER JOIN.
Výsledná tabulka (vzniklá z materializovaných view a spojená pomocí INNER JOIN) tak obsahuje ucelená data o průměrných mzdách a cenách potravin za období 2006–2018, připravená pro analýzu výzkumných otázek. 

##### Struktura tabulky:

date_from - sloupec obsahuje rok, ve kterém jsou data získána

avg_wage - sloupec obsahuje průměrnou mzdu za dané období

sector_name - sloupec obsahuje název odvětví

avg_price - sloupec obsahuje průměrnou cenu potravin

food_name - sloupec obsahuje název potravin 

price_value - sloupec obsahuje základní hodnotu, ve které jsou potraviny uváděny

price_unit - sloupec obsahuje název měrné jednotky, ve které jsou potraviny uváděny.


#### **Sekundární tabulka** 

  Byla vytvořena výběrem relevantních sloupců z primární tabulky a doplněna o údaje o HDP České republiky pro roky **2006–2018**. Data byla propojena pomocí **LEFT JOIN** podle klíče year, čímž vznikl rozšířený dataset určený k analýze vztahu mezi HDP, mzdami a cenami potravin.

 ##### Struktura tabulky:

  year -  sloupec obsahuje rok, ve kterém jsou data získána
  
  avg_wage - sloupec obsahuje průměrnou mzdu za dané období
  
  avg_price - sloupec obsahuje průměrnou cenu potravin
  
  hdp - sloupec obsahuje hdp za jednotlivé roky

## **Odpovědi na otázky**
1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají? 

Ne. V některých odvětvích v průběhu let mzdy klesaly, jedná se například o rok 2013 Peněžnictví a pojišťovniství nebo v roce 2013 Výroba a rozvod elektřiny, plynu, tepla a klimatiz. vzduchu. 
   
2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

Rok 2006: 1466 litrů mléka a 1313 kg chleba
Rok 2018: 1670 litrů mléka a 1365 kg chleba
   
Při výpočtu jsem využila CTE pro přehledné napočítávání hodnot a krokové ověřování výsledků.
Vždy jsem si nejprve určila počáteční rok (2006), následně jsem výpočet zopakovala pro poslední rok (2018) se změnou řazení (ASC → DESC).
Tento postup umožnil jasně porovnat kupní sílu v obou obdobích.

 3. Která kategorie potravin zdražuje nejpomaleji - je u ní nejnižší percentuální meziroční nárůst?
    
Nejpomaleji zdražuje **cukr krystalový**, u kterého dokonce dochází ke zlevnění. Naopak nejrychleji zdražuje kategorie **papriky**.

Pro výpočet jsem využila kombinaci CTE a window funkcí. Pomocí funkce LAG() jsem zjistila předchozí hodnotu ceny a následně spočítala meziroční procentuální změnu.
Výsledky jsem poté seřadila sestupně, aby se na první pozici zobrazila potravina s nejnižším nárůstem cen.

4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
   
Ne, takový rok neexistuje. Nejvyšší rozdíl mezi růstem cen a mezd byl zaznamenán v roce 2013 (6 %). Ve většině let byl růst mezd vyšší než růst cen, přičemž rozdíly se často pohybovaly v záporných hodnotách. 

Při výpočtu jsem opět využila CTE a funkci LAG() k získání předchozí hodnoty. V následujícím kroku jsem vypočítala procentuální meziroční změnu jak pro mzdy, tak pro ceny potravin. Nakonec jsem pomocí podmínky CASE WHEN identifikovala roky, kdy rozdíl překročil hranici 10 %. Žádný rok tuto podmínku nesplnil.

5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

Ano, výše HDP má vliv především na vývoj mezd, a to s ročním zpožděním. Z výpočtů vyplynulo, že nejvyšší korelace je mezi změnou HDP v daném roce a změnou mezd v následujícím roce. To znamená, že pokud HDP v jednom roce výrazně vzroste, mzdy se zvýší v roce následujícím. Naopak vztah mezi HDP a cenami potravin v následujícím roce je minimální až zanedbatelný – korelace vyšla v záporných hodnotách a blízko nule. Vliv HDP na ceny potravin ve stejném roce je však mírně pozitivní, hodnota korelace je kladná a blíží se 1. Celkově tedy HDP nejvýrazněji ovlivňuje mzdy v následujícím roce, zatímco na ceny potravin má pouze slabý krátkodobý vliv.
K získání výsledku jsem využívala CTE, LAG, LEAD a poté CORR k získání korelace mezi jednotlivými údaji.   


