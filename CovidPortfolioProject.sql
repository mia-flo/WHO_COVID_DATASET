SELECT * 
FROM COVIDPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

--percent deaths
--likelihood of dying if contracted COVID
SELECT
	location
	,date
	,total_cases
	,total_deaths
	,CAST((total_deaths / CAST(total_cases AS DECIMAL(15, 2))) * 100 AS DECIMAL(15, 2))
		AS percent_deaths
FROM COVIDPortfolioProject..CovidDeaths
WHERE total_cases > 0 AND total_deaths > 0


--total cases vs population
--percentage of population who contracted COVID
SELECT
	location
	,date
	,total_cases
	,population
	,CAST((total_Cases / CAST(population AS DECIMAL(15, 2))) * 100 AS DECIMAL(15, 2)) AS percent_contracted
FROM COVIDPortfolioProject..CovidDeaths
WHERE total_cases >0 AND population > 0


--countries w/ the highest infection rate
SELECT 
	location
	,MAX(total_cases) AS highest_infection_count
	,population
	,MAX(CAST((total_Cases / CAST(population AS DECIMAL(15, 2))) * 100 AS DECIMAL(15, 2))) AS percent_contracted
FROM COVIDPortfolioProject..CovidDeaths
WHERE total_cases > 0 AND population > 0 
GROUP BY location, population
ORDER BY percent_contracted DESC


--highest death count
SELECT
	location
	,MAX(total_deaths) AS total_death_count
FROM COVIDPortfolioProject..CovidDeaths
WHERE total_deaths > 0 
GROUP BY location
ORDER BY total_death_count DESC

--death count based on continent
SELECT 
	continent
	,MAX(total_deaths) AS total_death_count
FROM COVIDPortfolioProject..CovidDeaths
WHERE total_deaths > 0
	AND continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC


--global numbers
--divide by zero error encountered
SELECT
	date
	,SUM(new_cases) AS newCases
	,SUM(new_deaths) AS newDeaths
	,CAST((new_deaths / CAST(new_cases AS DECIMAL(15, 2))) * 100 AS DECIMAL(15, 2)) 
	AS totalDeaths
FROM COVIDPortfolioProject..CovidDeaths
WHERE new_cases > 0 AND new_deaths > 0
	AND continent is not null
GROUP BY date, new_cases, new_deaths
ORDER BY date



--total population vs vaccination
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
ORDER BY 1, 2, 3


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
SELECT
	location
	,date
	,CAST(total_vaccinations AS DECIMAL(15,0)) totalVac
	,CAST(people_vaccinated AS DECIMAL(15,0)) peopleVac
	,CAST(people_fully_vaccinated AS DECIMAL(15,0)) fullVac
	,CAST(total_boosters AS DECIMAL(15,0)) boosters
FROM COVIDPortfolioProject..CovidVaccinations
WHERE CAST(total_vaccinations AS DECIMAL(15,0)) > 0
	AND CAST(people_vaccinated AS DECIMAL(15,0)) > 0
	AND CAST(people_fully_vaccinated AS DECIMAL(15,0)) > 0
	AND CAST(total_boosters AS DECIMAL(15,0)) > 0
	AND continent IS NOT NULL
GROUP BY location, date, total_vaccinations, people_vaccinated, people_fully_vaccinated, total_boosters


