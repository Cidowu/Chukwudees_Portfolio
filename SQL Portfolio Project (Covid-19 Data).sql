
/*

Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


SELECT *
FROM PortfolioProject..covidDeaths
ORDER BY 3, 4

-- SELECT DATASET OF INTEREST

SELECT Location, date, population, total_cases, new_cases, total_deaths
FROM PortfolioProject..covidDeaths
ORDER BY 1, 2

-- TOTAL CASES vs TOTAL DEATHS
-- Shows the likelihood of a covid patient dying by country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate
FROM PortfolioProject..covidDeaths
ORDER BY 1, 2

-- TOTAL CASES BY POPULATION
-- understanding the rate at which the covid disease was contracted in each country

SELECT Location, date, population, (new_cases/total_cases)*100 as daily_rate, (total_cases/population)*100 as PopulationAffected
FROM PortfolioProject..covidDeaths
--WHERE location like '%states%'
ORDER BY 1, 2

-- COUNTRIES WITH HIGHEST INFECTION RATE PER POPULATION

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((new_cases/total_cases)*100) as max_daily_rate, 
	 MAX((total_cases/population)*100) as PercentPopulationAffected 

FROM PortfolioProject..covidDeaths
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY PercentPopulationAffected desc

-- COUNTRIES WITH HIGHEST INFECTION COUNT BY LOCATION

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((new_cases/total_cases)*100) as max_daily_rate, 
	 MAX((total_cases/population)*100) as PercentPopulationAffected 

FROM PortfolioProject..covidDeaths
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY HighestInfectionCount desc


-- COUNTRIES WITH HIGHEST DEATH COUNT
-- use the cast function to convert the "total_deaths" column from nvarchar to int

SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..covidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount desc

-- COUNTRIES WITH HIGHEST DEATH COUNT BY POPULATION
-- Shows the percentage of a country's percentage lost during the Covid-19 pandemic

SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount, 
	SUM(cast(new_deaths as int))/MAX(population)*100 as DeathPercentage
FROM PortfolioProject..covidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY DeathPercentage desc

--CONTINENTS WITH HIGHEST DEATH COUNT

SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..covidDeaths
WHERE continent is null AND location not like '%income%'
GROUP BY Location
ORDER BY TotalDeathCount desc


--DEATH RATES PER INCOME LEVEL

SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount, 
	SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProject..covidDeaths
WHERE continent is null AND location like '%income%'
GROUP BY Location
ORDER BY TotalDeathCount desc

--CONTINENTS WITH HIGHEST DEATH COUNT (has error)

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..covidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc



-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--Where location like '%states%'
WHERE continent is not null 
Group By date
ORDER BY 1,2

--GLOBAL TOTAL DEATH RATE

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--Where location like '%states%'
WHERE continent is not null 
--Group By date
ORDER BY 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, MAX(CAST(vac.new_vaccinations as int)) 
	OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, MAX(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and new_vaccinations is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, MAX(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

--Check View

select *
from PercentPopVaccinated
