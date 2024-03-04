-- Select Data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelyhood of dying if you contract covid in your country

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%states%'
and continent is not NULL
order by 1,2


-- Total cases vs Population
-- Shows what percentage of population got Covid

select location, date, total_cases, population, (total_cases/population)*100 as InfectionPercentage
from PortfolioProject..CovidDeaths
where location like '%states%'
order by 1,2


-- Counries with the highest infection rate compared to Population

select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as MaxInfectionPercentage
from PortfolioProject..CovidDeaths
group by location, population
order by MaxInfectionPercentage desc


-- Continents with total death count

select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is NULL
group by location
order by TotalDeathCount desc


-- GLOBAL NUMBER: Total cases vs Death
-- Shows what percentage of death in the world

select SUM(total_cases) as total_cases, SUM(cast(total_deaths as int)) as total_deaths, SUM(cast(total_deaths as int))/SUM(total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not NULL
order by 1,2 


-- Looking at Total Population vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, 
dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccionations vac
	on  dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not NULL
order by 2,3


-- USE CTE

with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as (

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, 
dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccionations vac
	on  dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not NULL
)
select *, (RollingPeopleVaccinated/population)*100
from PopvsVac


-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(155),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, 
dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccionations vac
	on  dea.location = vac.location
	and dea.date = vac.date
select *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated


-- Create view to store data for later visualisations
USE PortfolioProject
GO
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, 
dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccionations vac
	on  dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not NULL


select *
from PercentPopulationVaccinated