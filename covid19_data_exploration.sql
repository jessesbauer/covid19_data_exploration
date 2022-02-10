--dataset obtained from https://ourworldindata.org/covid-deaths--

SELECT 
	*
FROM 
	PortfolioProject..covid_deaths
ORDER BY 3,4;

SELECT 
	*
FROM 
	PortfolioProject..covid_vaccinations
ORDER BY 3,4;

SELECT 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM 
	PortfolioProject..covid_deaths
ORDER BY 1,2;

--looking at total cases vs total deaths
--shows likelihood of dying if you contract covid in your country
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100  AS death_percentage
FROM 
	PortfolioProject..covid_deaths
WHERE location LIKE '%states%'
ORDER BY 1,2;

--looking at total cases vs population
--shows percentage of population that were infected in USA
SELECT 
	location, 
	date, 
	total_cases, 
	population,
	(total_cases/population)*100  AS infection_percentage
FROM 
	PortfolioProject..covid_deaths
WHERE location LIKE '%states%'
ORDER BY 1,2;

--looking at countries with highest infection rate per population
SELECT 
	location, 
	population, 
	MAX(total_cases) AS highest_infection_count,
	MAX((total_cases/population)*100) AS percent_population_infected
FROM 
	PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC;

--looking at countries with highest death count per population
--cast total_deaths data type to conver to int
SELECT 
	location, 
	MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM 
	PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;


--BREAKING DOWN BY CONTINENT--

--looking at continents with highest death count per population
--cast total_deaths data type to convert to int
SELECT 
	location, 
	MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM 
	PortfolioProject..covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC;

--looking at north american countries numbers
SELECT 
	location, 
	population, 
	MAX(total_cases) AS highest_infection_count,
	MAX((total_cases/population)*100) AS percent_population_infected,
	MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM 
	PortfolioProject..covid_deaths
WHERE continent = 'North America'
GROUP BY location, population
ORDER BY population DESC;


--GLOBAL NUMBERS--
--cast new_deaths data type to conver to int
--cases and deaths by date
SELECT 
	date, 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

--cases and deaths total
SELECT  
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


--VACCINCATIONS--
SELECT
	*
FROM
	PortfolioProject..covid_vaccinations;


--looking at total population vs vaccincation
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM
	PortfolioProject..covid_deaths dea
JOIN
	PortfolioProject..covid_vaccinations vac
ON
	dea.location = vac.location
AND
	dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--use CTE
WITH PopVsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM
	PortfolioProject..covid_deaths dea
JOIN
	PortfolioProject..covid_vaccinations vac
ON
	dea.location = vac.location
AND
	dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM PopVSVac;


--USE TEMP TABLE
DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
	(continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	rolling_people_vaccinated numeric
	)
INSERT INTO 
	#percent_population_vaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM
	PortfolioProject..covid_deaths dea
JOIN
	PortfolioProject..covid_vaccinations vac
ON
	dea.location = vac.location
AND
	dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT 
	*, 
	(rolling_people_vaccinated/population)*100
FROM 
	#percent_population_vaccinated;


--CREATING VIEWS TO STORE DATA FOR LATER VISUALIZATIONS--
--total population vs vaccincation
CREATE VIEW percent_population_vaccinated AS
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM
	PortfolioProject..covid_deaths dea
JOIN
	PortfolioProject..covid_vaccinations vac
ON
	dea.location = vac.location
AND
	dea.date = vac.date
WHERE dea.continent IS NOT NULL;


--cases and deaths total
CREATE VIEW total_infections_and_deaths AS
SELECT  
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject..covid_deaths
WHERE continent IS NOT NULL;

--cases and deaths by date
CREATE VIEW infections_deaths_by_date AS
SELECT 
	date, 
	SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date;


--shows likelihood of dying if you contract covid in your country
CREATE VIEW death_chance_usa AS
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100  AS death_percentage
FROM 
	PortfolioProject..covid_deaths
WHERE location LIKE '%states%';


--looking at countries with highest infection rate per population
CREATE VIEW percent_population_infected AS
SELECT 
	location, 
	population, 
	MAX(total_cases) AS highest_infection_count,
	MAX((total_cases/population)*100) AS percent_population_infected
FROM 
	PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population;

--looking at countries with highest death count per population
CREATE VIEW percent_population_death AS
SELECT 
	location, 
	MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM 
	PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location;


--looking at continents with highest death count per population
CREATE VIEW percent_continent_death AS
SELECT 
	location, 
	MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM 
	PortfolioProject..covid_deaths
WHERE continent IS NULL
GROUP BY location;
