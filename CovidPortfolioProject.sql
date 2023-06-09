SELECT * 
FROM COVIDPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

--global numbers
SELECT
	SUM(CAST(total_cases AS DECIMAL(15,0))) AS totalCases
	,SUM(CAST(total_deaths AS DECIMAL(15,0))) AS totalDeaths
	,(SUM(CAST(total_deaths AS DECIMAL(15,0)))/SUM(CAST(total_cases AS DECIMAL(15,0))))*100
		AS percentDeaths
FROM COVIDPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL


--death counts by continent
SELECT 
	location
	,SUM(new_cases) AS total_death_count
FROM COVIDPortfolioProject..CovidDeaths
WHERE new_cases > 0
	AND continent IS NULL
	AND location NOT IN ('World', 'Europian Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC


--highest infection rates
SELECT 
	location
	,MAX(total_cases) AS highest_infection_count
	,population
	,MAX(CAST((total_Cases / CAST(population AS DECIMAL(15, 2))) * 100 AS DECIMAL(15, 2))) 
		AS percent_pop_contracted
FROM COVIDPortfolioProject..CovidDeaths
WHERE total_cases > 0 AND population > 0 
GROUP BY location, population
ORDER BY percent_pop_contracted DESC


--
SELECT 
	location
	,MAX(total_cases) AS highest_infection_count
	,population
	,date
	,MAX(CAST((total_Cases / CAST(population AS DECIMAL(15, 2))) * 100 AS DECIMAL(15, 2))) 
		AS percent_pop_contracted
FROM COVIDPortfolioProject..CovidDeaths
WHERE total_cases > 0 AND population > 0 
	AND YEAR(date) = 2020
	OR YEAR(date) = 2021
GROUP BY location, population, date
ORDER BY percent_pop_contracted DESC





--percent deaths
--likelihood of dying if contracted COVID
--SELECT
--	location
--	,SUM(total_cases) AS total_cases
--	,SUM(total_deaths) AS total_deaths
--	,CAST((SUM(CAST(total_deaths AS DECIMAL(15,2))) / CAST(total_cases AS DECIMAL(15, 2))) * 100 AS DECIMAL(15, 2))
--		AS percent_deaths
--FROM COVIDPortfolioProject..CovidDeaths
--WHERE total_cases > 0 AND total_deaths > 0
--	AND continent IS NULL
--	AND location NOT IN ('World', 'Europian Union', 'International')
--GROUP BY location, date, total_cases, total_deaths


--total vaccination vs population
--SELECT
--	death.continent
--	,death.location
--	,death.date
--	,death.population
--	,CAST(new_vaccinations AS DECIMAL(15,0)) AS newVaccinations
--	,SUM(CAST(vac.new_vaccinations AS DECIMAL(15,0))) 
--		OVER (PARTITION BY death.location ORDER BY death.location, death.date) 
--		AS rollingVaccinationCount
--FROM COVIDPortfolioProject..CovidDeaths death
--JOIN COVIDPortfolioProject..CovidVaccinations vac
--	ON (death.location = vac.location 
--	AND death.date = vac.date)
--WHERE population > 0 AND new_vaccinations > 0
--	AND death.continent IS NOT NULL
--	AND death.location NOT IN ('World', 'Europian Union', 'International')



--SELECT
--	death.location
--	,death.population
--	,(SUM(CAST(death.population AS BIGINT))/SUM(CAST(people_fully_vaccinated AS BIGINT)))*100
--		AS newVaccinations
--FROM COVIDPortfolioProject..CovidDeaths death
--JOIN COVIDPortfolioProject..CovidVaccinations vac
--	ON (death.location = vac.location)
--WHERE population > 0 AND people_fully_vaccinated > 0
--	AND total_vaccinations < 2161206739
--	AND death.continent IS NULL
--	AND death.location NOT IN ('World', 'Europian Union', 'International')
--GROUP BY death.location, death.population, people_fully_vaccinated


--how much of the population is vaccinated
WITH PopvsVac(continent, location, date, population, new_vaccinations, rollingVaccinationCount)
AS
(
SELECT
	death.continent
	,death.location
	,death.date
	,death.population
	,CAST(new_vaccinations AS DECIMAL(15,0)) AS newVaccinations
	,SUM(CAST(vac.new_vaccinations AS DECIMAL(15,0))) 
		OVER (PARTITION BY death.location ORDER BY death.location, death.date) 
		AS rollingVaccinationCount
FROM COVIDPortfolioProject..CovidDeaths death
JOIN COVIDPortfolioProject..CovidVaccinations vac
	ON (death.location = vac.location 
	AND death.date = vac.date)
WHERE population > 0 AND new_vaccinations > 0
	AND death.continent IS NOT NULL
)
SELECT
	*
	,(rollingVaccinationCount/population)*100 rateVaccination
FROM PopvsVac


--temp table
DROP TABLE IF EXISTS #PercentPopVaccinated
CREATE TABLE #PercentPopVaccinated
(
continent NVARCHAR(255)
,location NVARCHAR(255)
,date DATETIME
,population NUMERIC
,new_vaccinations NUMERIC
,rollingVaccinationCount NUMERIC
)


INSERT INTO #PercentPopVaccinated
SELECT
	death.continent
	,death.location
	,death.date
	,death.population
	,CAST(new_vaccinations AS DECIMAL(15,0)) AS newVaccinations
	,SUM(CAST(vac.new_vaccinations AS DECIMAL(15,0))) 
		OVER (PARTITION BY death.location ORDER BY death.location, death.date) 
		AS rollingVaccinationCount
FROM COVIDPortfolioProject..CovidDeaths death
JOIN COVIDPortfolioProject..CovidVaccinations vac
	ON (death.location = vac.location 
	AND death.date = vac.date)
WHERE population > 0 AND new_vaccinations > 0
	AND death.continent IS NOT NULL

SELECT
	*
	,(rollingVaccinationCount/population)*100
FROM #PercentPopVaccinated



CREATE VIEW	PercentPopVaccinated AS
SELECT
	death.continent
	,death.location
	,death.date
	,death.population
	,CAST(new_vaccinations AS DECIMAL(15,0)) AS newVaccinations
	,SUM(CAST(vac.new_vaccinations AS DECIMAL(15,0))) 
		OVER (PARTITION BY death.location ORDER BY death.location, death.date) 
		AS rollingVaccinationCount
FROM COVIDPortfolioProject..CovidDeaths death
JOIN COVIDPortfolioProject..CovidVaccinations vac
	ON (death.location = vac.location 
	AND death.date = vac.date)
WHERE population > 0 AND new_vaccinations > 0
	AND death.continent IS NOT NULL

SELECT * FROM PercentPopVaccinated


--death rate, hospitalization rate, and pre-existing conditions
SELECT
	death.location
	,death.date
	,death.new_cases
	,death.hosp_patients
	,death.icu_patients
	,(CAST(death.hosp_patients AS FLOAT)/CAST(death.new_cases AS FLOAT))*100 AS hospitalAdmissionsRate
	,(CAST(death.icu_patients AS FLOAT)/CAST(death.new_cases AS FLOAT))*100 AS icuAdmissionsRate
	,vac.diabetes_prevalence
	,CAST(vac.female_smokers AS FLOAT) AS femaleSmokers
	,CAST(vac.male_smokers AS FLOAT) AS maleSmokers
FROM COVIDPortfolioProject..CovidDeaths death
JOIN COVIDPortfolioProject..CovidVaccinations vac
	ON (death.location = vac.location
	AND death.date = vac.date)
WHERE death.hosp_patients > 0 
	AND death.icu_patients > 0
	AND death.new_cases > 0
ORDER BY diabetes_prevalence DESC, femaleSmokers DESC, maleSmokers DESC


--which countries have the highest rate of vaccination?
--SELECT
--	location
--	,date
--	,CAST(total_vaccinations AS DECIMAL(15,0)) totalVac
--	,CAST(people_vaccinated AS DECIMAL(15,0)) peopleVac
--	,CAST(people_fully_vaccinated AS DECIMAL(15,0)) fullVac
--	,CAST(total_boosters AS DECIMAL(15,0)) boosters
--FROM COVIDPortfolioProject..CovidVaccinations
--WHERE CAST(total_vaccinations AS DECIMAL(15,0)) > 0
--	AND CAST(people_vaccinated AS DECIMAL(15,0)) > 0
--	AND CAST(people_fully_vaccinated AS DECIMAL(15,0)) > 0
--	AND CAST(total_boosters AS DECIMAL(15,0)) > 0
--	AND continent IS NOT NULL
--GROUP BY location, date, total_vaccinations, people_vaccinated, people_fully_vaccinated, total_boosters


--
--SELECT
--	location
--	,SUM(CAST(total_vaccinations AS DECIMAL(15,0))) totalVac
--	,SUM(CAST(people_vaccinated AS DECIMAL(15,0))) peopleVac
--	,SUM(CAST(people_fully_vaccinated AS DECIMAL(15,0))) fullVac
--	,SUM(CAST(total_boosters AS DECIMAL(15,0))) boosters
--FROM COVIDPortfolioProject..CovidVaccinations
--WHERE CAST(total_vaccinations AS DECIMAL(15,0)) > 0
--	AND CAST(people_vaccinated AS DECIMAL(15,0)) > 0
--	AND CAST(people_fully_vaccinated AS DECIMAL(15,0)) > 0
--	AND CAST(total_boosters AS DECIMAL(15,0)) > 0
--	AND continent IS NOT NULL
--GROUP BY location


--hospitalizations by month, for each yr

WITH monthly (location, mo) AS
		(SELECT
			location
			,MONTH(date) mo
		FROM CovidDeaths
		WHERE YEAR(date) = 2020
		),
	admissions (location, icu) AS
		(SELECT
			location
			,CAST(icu_patients AS INT) AS icu
		FROM CovidDeaths
		),
	total_admisions_over_time (location, total_icu) AS
		(SELECT
			c.location
			,SUM(a.icu) 
				OVER (PARTITION BY m.mo) AS total_icu
		FROM CovidDeaths c
		JOIN monthly m 
			ON (c.location = m.location)
		JOIN admissions a
			ON (m.location = a.location)
		)
SELECT 
	ta.location
	,total_icu
FROM total_admisions_over_time ta
GROUP BY location, total_icu

