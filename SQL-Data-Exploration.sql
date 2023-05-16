--SELECT *
--FROM PortfolioExploration..CovidDeaths
--ORDER BY 3,4

--SELECT *
--FROM PortfolioExploration..CovidVaccinations
--ORDER BY 3,4



-- Select data to be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioExploration..CovidDeaths
ORDER BY 1,2


-- Total Cases v Total Deaths (Likelihood of dying if you contract covid in India)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioExploration..CovidDeaths
WHERE location like '%india%'
ORDER BY 1,2


-- Total cases vs population (Percentage of indian population that got covid)
SELECT location, date, total_cases, population, (total_cases/population)*100 AS ContractedPercentage
FROM PortfolioExploration..CovidDeaths
WHERE location like '%india%'
ORDER BY 1,2


-- Looking at countries with highest infection rate compared to population
SELECT location, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentInfectedPercentage
FROM PortfolioExploration..CovidDeaths
GROUP BY location, population
ORDER BY PercentInfectedPercentage DESC


-- Breaking down by continent
SELECT location ,MAX(cast(total_deaths as int)) as TotalDeaths
FROM PortfolioExploration..CovidDeaths
where continent is null and location <> 'World' and location <> 'International'
GROUP BY location
ORDER BY TotalDeaths DESC


-- Countries with highest death count per population
SELECT location,MAX(cast(total_deaths as int)) as TotalDeaths
FROM PortfolioExploration..CovidDeaths
where continent is not null
GROUP BY location
ORDER BY TotalDeaths DESC


-- Continents with highest death count per population
SELECT continent ,MAX(cast(total_deaths as int)) as TotalDeaths
FROM PortfolioExploration..CovidDeaths
where continent is not null
GROUP BY continent
ORDER BY TotalDeaths DESC


-- Global Numbers
SELECT date, SUM(new_cases), SUM(cast(new_deaths as int)), SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioExploration..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


-- Joining both tables
SELECT *
FROM PortfolioExploration..CovidDeaths d
JOIN PortfolioExploration..CovidVaccinations v
	ON d.location = v. location
	AND d.date = v.date
ORDER BY 1,2


-- Total population vs Vaccinations
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingCount
FROM PortfolioExploration..CovidDeaths d
JOIN PortfolioExploration..CovidVaccinations v
	ON d.location = v. location
	AND d.date = v.date
WHERE d.continent is not null
ORDER BY 2,3

-- Using CTE
WITH PopVac (continent, location, date, population, new_vaccinations, RollingCount)
AS 
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingCount
FROM PortfolioExploration..CovidDeaths d
JOIN PortfolioExploration..CovidVaccinations v
	ON d.location = v. location
	AND d.date = v.date
WHERE d.continent is not null
)
SELECT *, (RollingCount/population)*100
FROM PopVac

-- Using Temp Table
DROP TABLE IF EXISTS #temp
CREATE TABLE #temp
(
continent nvarchar(225),
location nvarchar(225),
date datetime,
population numeric,
new_vaccinations numeric,
RollingCount numeric
) 
INSERT INTO #temp
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingCount
FROM PortfolioExploration..CovidDeaths d
JOIN PortfolioExploration..CovidVaccinations v
	ON d.location = v. location
	AND d.date = v.date
WHERE d.continent is not null

SELECT *, (RollingCount/population)*100
FROM #temp


-- View to store data for later viz
CREATE VIEW percent_vaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(int, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingCount
FROM PortfolioExploration..CovidDeaths d
JOIN PortfolioExploration..CovidVaccinations v
	ON d.location = v. location
	AND d.date = v.date
WHERE d.continent is not null