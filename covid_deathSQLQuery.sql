--select all fields from covid_death table 
select * 
from covid_death
order by location, date 

--select location, date, total_cases, new_cases, total_deaths, population from covid_death
select  location, date, total_cases, 
		new_cases, total_deaths, population

from covid_death
where continent IS NOT NULL
	order by location, date 

--total cases vs total deaths
select  location, date, total_cases, 
		 total_deaths, 
		 CASE 
				WHEN total_cases <> 0 THEN ROUND(total_deaths/total_cases * 100, 3)
				ELSE NULL
				END AS outcome 
from covid_death
	order by location, date 

--EXEC sp_HELP to view all information on covid_death
	EXEC sp_HELP covid_death

--ALTER TABLE covid_death and ALTER COLUMN total_cases & total_deaths as float
	ALTER TABLE covid_death
	ALTER COLUMN total_cases float

	ALTER TABLE covid_death
	ALTER COLUMN total_deaths float

	ALTER TABLE covid_death
	ALTER COLUMN population  float

--chance of death if you contract covid in United State
--percentage of deaths by covid cases
select  location, date, total_cases, 
		 total_deaths, 
		 CASE 
				WHEN total_cases <> 0 THEN ROUND(total_deaths/total_cases * 100, 3)
				ELSE NULL
				END AS outcome 
from covid_death
where location ='United States'
	order by location, date 

--percentage of total cases by population
select  location, date, total_cases, 
		 population, ROUND((total_cases/population) * 100, 3) AS popu_cases
from covid_death
where location = 'United States'
order by location, date

--countries with highest covid cases compared to population
select  location,population, MAX(total_cases) AS highCases, 
		 MAX(ROUND((total_cases/population) * 100, 3)) AS popu_cases
from covid_death
where continent IS NOT NULL
group by location, population
order by popu_cases desc

--countries with highest covid death per popuplation
select  location,population, MAX(total_deaths) AS highdeaths, 
		 MAX(ROUND((total_deaths/population) * 100, 3)) AS popu_deaths
from covid_death
where continent IS NOT NULL
group by location, population
order by popu_deaths desc

--continent with highest covid death per popuplation
select  continent, MAX(total_deaths) AS highdeaths, 
		 MAX(ROUND((total_deaths/population) * 100, 3)) AS popu_deaths
from covid_death
where continent IS NOT NULL
group by continent
order by popu_deaths desc

--Alter new_deaths column & new_cases column 
ALTER TABLE covid_death
ALTER COLUMN new_deaths float

ALTER TABLE covid_death
ALTER COLUMN new_cases float


--Global Number of covid cases 
select location, date, SUM(new_cases) as total_newcases, SUM(new_deaths) as total_newdeaths, 
		CASE
			WHEN SUM(new_cases) <> 0 THEN  SUM(new_deaths)/SUM(new_cases)
			ELSE NULL
			END AS new_outcome
		
from covid_death
where continent IS NOT NULL
group by location, date
order by date

select  SUM(new_cases) as total_newcases, SUM(new_deaths) as total_newdeaths
		--CASE
			--WHEN SUM(new_cases) <> 0 THEN  SUM(new_deaths)/SUM(new_cases)
			--ELSE NULL
			--END AS new_outcome
		
from covid_death
where continent IS NOT NULL
order by 1,2

--join covid_death to covidvaccination table on location and date
select top 10 *
from covid_death as cd
JOIN covidvaccination as cv
	ON cd.location = cv.location
	AND cd.date = cv.date

--CTE PopuVacc
	WITH PopuVacc 
				(continent,location, date, population, new_vaccinations, Rollingvaccination)
				AS
				( 
				select cd.continent, cd.location, cd.date, cd.population, 
		cv.new_vaccinations, 
--using function to calculate running total of new vaccination partition by location order by date
		SUM(convert(float, cv.new_vaccinations)) 
		OVER(PARTITION BY cd.location order by cd.date) as Rollingvaccination 
from covid_death as cd
JOIN covidvaccination as cv
	ON cd.location = cv.location
	AND cd.date = cv.date
where cd.continent IS NOT NULL) 

-- select all fields from PopuVacc
select * from PopuVacc

--perecentage of rollingvaccination vs population 
 select *, Rollingvaccination/population * 100 from PopuVacc

				
--total population vs vaccination 
 (select cd.continent, cd.location, cd.date, cd.population, 
		cv.new_vaccinations, 
--using function to calculate running total of new vaccination partition by location order by date
		SUM(convert(float, cv.new_vaccinations)) 
		OVER(PARTITION BY cd.location order by cd.date) as Rollingvaccination 
from covid_death as cd
JOIN covidvaccination as cv
	ON cd.location = cv.location
	AND cd.date = cv.date
where cd.continent IS NOT NULL 
--	order by  location, date
)
--using temp table(VaccinatedPopu)to calculate percentage of vaccinated population
DROP TABLE IF EXISTS VaccinatedPopu
CREATE TABLE VaccinatedPopu
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population float,
new_vaccinations float,
Rollingvaccination float
)

insert into VaccinatedPopu
select cd.continent, cd.location, cd.date, cast(cd.population as float), 
		cast(cv.new_vaccinations as float), 
--using function to calculate running total of new vaccination partition by location order by date
		SUM(convert(cv.new_vaccinations,  float)) 
		OVER(PARTITION BY cd.location order by cd.date) as Rollingvaccination 
from covid_death as cd
JOIN covidvaccination as cv
	ON cd.location = cv.location
	AND cd.date = cv.date

select top 20 * from VaccinatedPopu

-- CREATE VIEW later visualization 
Create view percentpopulation as
select cd.continent, cd.location, cd.date, cd.population, 
		cv.new_vaccinations, 
--using function to calculate running total of new vaccination partition by location order by date
		SUM(convert(float, cv.new_vaccinations)) 
		OVER(PARTITION BY cd.location order by cd.date) as Rollingvaccination 
from covid_death as cd
JOIN covidvaccination as cv
	ON cd.location = cv.location
	AND cd.date = cv.date
where cd.continent IS NOT NULL 

--select all fields in the view 
select * from [dbo].[percentpopulation]