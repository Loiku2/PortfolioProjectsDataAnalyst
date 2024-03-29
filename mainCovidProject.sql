
-- Select data that we're going to be using

select location, date, total_cases, new_cases, total_deaths
from [PortfolioProject].[dbo].CovidDeaths
order by 1,2

--Looking at total cases vs total deaths
select location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as deathsPercent
from [PortfolioProject].[dbo].CovidDeaths
where location like '%states%'
order by 1,2

-- Looking an countries with the highest infection rate
select location, population, max(total_cases) as highestInfectionCount, max((total_cases/population)*100) as 
	percentOfPopulationInfected
from [PortfolioProject].[dbo].CovidDeaths
group by location, population
order by percentOfPopulationInfected desc

--Countries with the highest death count per population
select location, population, max(total_deaths) as highestTotalDeaths, (max(total_deaths/population))*100 as deathPercent
from [PortfolioProject].[dbo].CovidDeaths
where continent is not null
group by location, population
order by deathPercent desc

--Continents with the highest death count per population
select continent, population, max(total_deaths) as highestTotalDeaths, (max(total_deaths/population))*100 as deathPercent
from [PortfolioProject].[dbo].CovidDeaths
where continent is not null
group by continent, population
order by deathPercent desc

-- Global numbers
select date, sum(new_cases) as totalCases, sum(new_deaths) as totalDeaths, (sum(new_deaths)/sum(new_cases))*100 as deathPercent
from [PortfolioProject].[dbo].CovidDeaths
where new_cases <> 0 and continent is not null
group by date
order by 1


-- Looking at total population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(vac.new_vaccinations) over (partition by dea.location order by dea.location
, dea.date) as rollingPeopleVaccinated
from [PortfolioProject].[dbo].CovidDeaths dea
join [PortfolioProject].[dbo].CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3 desc

--Use CTE to re-use calculated column in another column
with PopVsVac (continent, location, date, population, new_vaccinations, rollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(vac.new_vaccinations) over (partition by dea.location order by dea.location
, dea.date) as rollingPeopleVaccinated
from [PortfolioProject].[dbo].CovidDeaths dea
join [PortfolioProject].[dbo].CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3 desc
)
select *, (rollingPeopleVaccinated/population)*100 as rollingPercentVaccinated
from PopVsVac

--Use temp table to re-use calculated column in another column
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population float,
new_vaccinations float,
rollingPeopleVaccinated float
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(vac.new_vaccinations) over (partition by dea.location order by dea.location
, dea.date) as rollingPeopleVaccinated
from [PortfolioProject].[dbo].CovidDeaths dea
join [PortfolioProject].[dbo].CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3 desc

select *, (rollingPeopleVaccinated/population)*100 as rollingPercentVaccinated
from #PercentPopulationVaccinated

-- Creating view to store data for later visualizations
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(vac.new_vaccinations) over (partition by dea.location order by dea.location
, dea.date) as rollingPeopleVaccinated
from [PortfolioProject].[dbo].CovidDeaths dea
join [PortfolioProject].[dbo].CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null