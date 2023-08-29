select *
from PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

--select *
--from PortfolioProject..CovidVaccinations

--BREAK THINGS DOWN BY COUNTRY

-- 1)Looking at Total Cases vs. Total Deaths (Shows likelihood of dying if you contact covid in your country)

select location, date, total_cases, total_deaths, 
(cast(total_deaths as float) / cast(total_cases as float))*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location = 'United States' -- showing the chance of you getting Covid by date
order by 1,2

-- 2)Looking at total cases vs. population
-- Shows what percentage of population has gotten Covid

select location, date, population, total_cases,
(cast(total_cases as float) / population)*100 as PopPercentage
from PortfolioProject..CovidDeaths
--where location = 'United States' -- showing the chance of you getting the virus by date in the US
order by 1,2

-- 3) Looking at countries with highest infection rate compared to population

select location, population, max(total_cases) as HighestInfCount, 
max((cast(total_cases as float) / population)*100) as PerPopInfected
from PortfolioProject..CovidDeaths
group by Location, Population
order by 4 desc

-- 4) Showing countries with highest death count per population

select location, max(total_deaths) as HighestDeathCount
from PortfolioProject..CovidDeaths
where continent is not null -- excluding whole world, continent, income groups 
group by location
order by HighestDeathCount desc


--Let's break things down by continent--

-- 5) Showing continents with the highest death count per population
select continent, max(total_deaths) as HighestDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent -- just change from location to continent
order by HighestDeathCount desc


-- GLOBAL NUMBERS--

--1)See how many total cases vs. total death each day had across the world

select --date,-- 
sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths 
--(sum(new_deaths) / sum(new_cases))*100 as DeathPercentage
from PortfolioProject..CovidDeaths
--where location = 'United States'
where continent is not null
--group by date --if not group by date then shows overall cases vs. deaths
order by 1,2

--JOINING THE TWO TABLE--

--1)Looking at Total pop vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as TotalVacCount
-- adds up every consecutive vaccine number as time goes (Rolling count)-- 
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null  
order by 2,3


--USE CTE when we want to look at the percentage on new vac/ population--
--See how much percent of the pop has received vaccination--


With PopVsVac (continent, location, date, population, new_vaccinations, TotalVacCount)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as TotalVacCount
-- adds up every consecutive vaccine number as time goes (Rolling count)-- 
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and dea.location = 'China'
--order by 2,3

)

select * , (TotalVacCount / population) * 100
from PopVsVac


--TEMP TABLE VERSION--

DROP TABLE if exists #PercentPopVac -- leave this here in case you want to make any alterations

Create Table #PercentPopVac( 
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	TotalVacCount numeric
)

insert into #PercentPopVac
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as TotalVacCount
-- adds up every consecutive vaccine number as time goes (Rolling count)-- 
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and dea.location = 'China'
--order by 2,3

select * , (TotalVacCount / population) * 100
from #PercentPopVac





--CREATE A VIEW TO STORE DATA FOR LATER VISUALISATION--

--Save this temp table into a view--
Create View PercentPopVac as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as TotalVacCount
-- adds up every consecutive vaccine number as time goes (Rolling count)-- 
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3


select *
from PercentPopVac
