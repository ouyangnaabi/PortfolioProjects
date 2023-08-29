-- Queries for the Tableau Project--
-- 24 Aug 2023--
-- Final Project Dashboard on Tableau : https://public.tableau.com/views/SQLPortfolioProject_16929040157530/Dashboard1?:language=en-GB&:display_count=n&:origin=viz_share_link


--1. Overall total case vs overall total death & their percentage of death

select sum(new_cases) as totalcases, sum(cast(new_deaths as float)) as totaldeaths, 
(sum(cast(new_deaths as float)) / sum(new_cases)) *100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- Just a double check based off the data provided
-- numbers are extremely close so we will keep them - The Second includes "International"  Location


-- 2. Rank of death numbers by continents exclude world, EU, International, other income groups

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

/*
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
where location = 'World'
Group By date
order by 1,2
*/

Select location, sum(cast(new_deaths as float)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is null
and location not in('World','European Union','International','High income','Upper middle income','Lower middle income','Low income')
group by location
order by TotalDeathCount desc


--3. Overall pop vs infection number vs how many percent is infected by each country
Select location, population, max(total_cases) as HighestInfCount, 
max(cast(total_cases as float) / cast(population as float))*100 as PercentPopInf
from PortfolioProject..CovidDeaths
group by location, population
order by PercentPopInf desc

--4.Shows the percent of death by different date for each country
Select location, population, date, max(total_cases) as HighestInfCount, 
max(cast(total_cases as float) / cast(population as float))*100 as PercentPopInf
from PortfolioProject..CovidDeaths
group by location, population, date
order by PercentPopInf desc



