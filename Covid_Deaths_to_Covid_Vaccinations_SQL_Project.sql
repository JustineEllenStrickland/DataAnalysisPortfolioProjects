/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- 1. Explore data, fields, and the schema

SELECT *
FROM `covid_data.covid_deaths`
ORDER BY 1,2;

-- 2. Use the data to compare the countries by their total cases, total deaths, total tests, and total vaccinations metrics where the data is not based on the continent only and where the data is compared from the country with the most total cases to country with the least total cases.

SELECT 
  location, 
  MAX(CAST(total_cases AS int)) AS max_total_cases, 
  MAX(CAST(total_deaths AS int)) AS max_total_deaths,
  MAX(CAST(total_tests AS int)) AS max_total_tests,
  MAX(CAST(total_vaccinations AS int)) AS max_total_vaccinations
FROM `covid_data.covid_deaths`
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY max_total_cases DESC;

-- 3. Use the data to compare the countries by their maximum total cases, maximum total deaths, maximum total tests, and maximum total vaccinations metrics where the data is not based on the continent only and the data is compared from the country with the most maximum total cases to the country with the least maximum total cases.

SELECT 
  location,
  MAX(total_cases) AS max_total_cases,
  ROUND((MAX(total_deaths)/MAX(total_cases))*100, 2) AS max_deaths_percent,
  ROUND((MAX(total_deaths)/MAX(population))*100, 2) AS max_deaths_population_percent,
  ROUND((MAX(total_deaths)/MAX(total_tests))*100, 2) AS max_deaths_tests_percent,
  ROUND((MAX(total_deaths)/MAX(total_vaccinations))*100, 2) AS max_deaths_vaccinations_percent
FROM `covid_data.covid_deaths` 
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY max_total_cases DESC;

-- 4. Use the data to compare the countries by their average total cases, average total deaths, average total tests, and average total vaccinations metrics where the data is not based on the continent only and the data is compared from the country with the highest average total cases to the country with the least average total cases.

SELECT 
  location,
  ROUND(AVG(total_cases), 2) AS avg_total_cases,
  ROUND((AVG(total_deaths)/AVG(total_cases))*100, 2) AS avg_deaths_percent,
  ROUND((AVG(total_deaths)/AVG(population))*100, 2) AS avg_deaths_population_percent,
  ROUND((AVG(total_deaths)/AVG(total_tests))*100, 2) AS avg_deaths_tests_percent,
  ROUND((AVG(total_deaths)/AVG(total_vaccinations))*100, 2) AS avg_deaths_vaccinations_percent
FROM `covid_data.covid_deaths` 
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY avg_total_cases DESC;

-- 5. The data is comparing the countries by population, overall total cases, overall total cases to population as a percentage rounded to the 2nd significant digit, overall total deaths to population as a percentage rounded to the 2nd significant digit, overall total tests to population as a percentage rounded to the 2nd significant digit, and overall total vaccinations to population as a percentage rounded to the 2nd significant digit. The data is compared by countries with country data and continent data so as not to falsely inflate the numbers. The data is listed from the country with the largetst population to the country with the smallest population.

SELECT
  location,
  MAX(population) AS population,
  MAX(total_cases) AS total_cases,
  ROUND((MAX(total_cases)/AVG(population))*100, 2) AS cases_to_pop,
  ROUND((MAX(total_deaths)/AVG(population))*100, 2) AS deaths_to_pop,
  ROUND((MAX(total_tests)/AVG(population))*100, 2) AS tests_to_pop,
  ROUND((MAX(total_vaccinations)/AVG(population))*100, 2) vacc_to_pop
FROM `covid_data.covid_deaths` 
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY population DESC;

-- 6. The data from the covid deaths table is joined with an inner join to the covid vaccinations table on both the location fields and the date fields only when the country has values in both the location and continent fields. The data compares the continent, location, date, population, new vaccinations, and the sum of new vaccinations converted into integer values with that data being organized by location. Then the data is listed by country alphabetically and date from oldest to newsest. Then that data is ordered by the 2nd and 3rd fields.

SELECT
  deaths.continent,
  deaths.location,
  deaths.date,
  deaths.population,
  vacc.new_vaccinations,
  SUM(CAST(vacc.new_vaccinations AS int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date)
FROM `covid_data.covid_deaths` AS deaths
INNER JOIN `covid_data.covid_vaccinations` AS vacc
  ON deaths.location = vacc.location
    AND deaths.date = vacc.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3;

-- 7. 

WITH rolling_count AS (
  SELECT 
    deaths.continent,
    deaths.location,
    deaths.date,
    deaths.population,
    vacc.new_vaccinations,
    SUM(CAST(vacc.new_vaccinations AS int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_vacc
  FROM `covid_data.covid_deaths` AS deaths
  INNER JOIN `covid_data.covid_vaccinations` AS vacc
    ON deaths.location = vacc.location
      AND deaths.date = vacc.date
  WHERE deaths.continent IS NOT NULL)
SELECT
  rc.continent,
  rc.location,
  rc.date,
  rc.population,
  rc.new_vaccinations,
  rc.rolling_vacc,
  ROUND((rc.rolling_vacc/d.population)*100, 2) AS vaccinations_to_population
FROM rolling_count AS rc
INNER JOIN `covid_data.covid_deaths` as d
  ON rc.location = d.location
    AND rc.date = d.date
WHERE rc.location LIKE '%States%'
ORDER BY rc.date DESC;

-- 8.

CREATE VIEW percent_population_vaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CAST(v.new_vaccinations AS int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM `covid_data.covid_deaths` AS d
INNER JOIN `covid_data.covid_vaccinations` AS v
  ON d.location = v.location
    AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT *
FROM percent_population_vaccinated;