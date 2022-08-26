SELECT * 
FROM PortfolioProject..CovidDeaths
Order by 3, 4 

SELECT * 
FROM PortfolioProject..CovidVaccinations
Order by 3,4

--Select Data that I will be using, ORDER BY LOC & DATE
SELECT 
	Location,
	Date,
	Total_cases,
	New_cases,
	Total_deaths,
	Population
FROM
	CovidDeaths
WHERE 
	continent is not null
ORDER BY
	1,2

--Looking at Total Cases Vs Total Deaths (%) Likelihood of dying of Covid
SELECT
	Location,
	Date,
	Total_cases,
	Total_deaths,
	Population,
	ROUND((total_deaths/total_cases)*100,2) AS Death_Percentage
FROM
	CovidDeaths
WHERE
	Location like '%japan%' -- CONTAINS 'japan' 
	AND
	continent is not null
ORDER BY
	1, 2

--Looking at the  Total cases Vs Population, % of population has got covid
SELECT
	Location,
	Date,
	Population,
	Total_cases,
	ROUND((total_cases/population)*100,2) AS Percentage
FROM
	CovidDeaths
WHERE
	Location 
	like '%states%' -- CONTAINS ' '
	WHERE 
	continent is not null
ORDER BY
	1, 2

--Country with highest infection rate (OVERALL) 
SELECT TOP 1
	Location,
	Population,
	Total_cases,
	MAX(ROUND((total_cases/population)*100,2)) AS Percentage
FROM
	CovidDeaths
WHERE 
	continent is not null
GROUP BY
	Location,
	Population,
	Total_cases
ORDER BY
	percentage DESC

--OR
SELECT 
	Location,
	Population,
	MAX (Total_cases) as Max_total_cases,
	MAX(ROUND((total_cases/population)*100,2)) AS Percentage
FROM
	CovidDeaths
WHERE 
	continent is not null
GROUP BY
	Location, population
ORDER BY
	Percentage DESC

-- Looking at Top 10 countries with highest death rate 
SELECT TOP 10
	Location,
	Population,
	MAX (cast(Total_deaths as int)) as Max_total_deaths,
	MAX(ROUND((total_deaths/population)*100,2)) AS Percentage_Deaths_Population
FROM
	CovidDeaths
WHERE 
	continent is not null
GROUP BY
	Location, population
ORDER BY
	Percentage_Deaths_Population DESC


-- Looking at Top 10 countries with highest death count
SELECT TOP 10
	Location,
	Population,
	MAX (cast(Total_deaths as int)) as Max_total_deaths
FROM
	CovidDeaths
WHERE 
	continent is not null
GROUP BY
	Location, population
ORDER BY
	Max_total_deaths DESC

--Looking up data highest death count per continent
SELECT 
	continent,
	MAX(cast(Total_deaths as int)) as Max_total_deaths
FROM
	CovidDeaths
WHERE 
	continent is not null
GROUP BY
	continent
ORDER BY
	Max_total_deaths DESC


--Total of new cases and deaths across the world 
SELECT
	SUM(New_cases) as Total_new_cases,
	SUM(cast(new_deaths as int)) as Total_new_deaths,
	ROUND((SUM(cast(new_deaths as int))/SUM(new_cases))*100,2) as RateHmm 
FROM
	CovidDeaths
WHERE
	continent is not null
ORDER BY
	1, 2

--Join to look at total population vs vaccination worldwide 
SELECT 
	dea.continent, dea.location, dea.date, population, vac.new_vaccinations
FROM
	CovidDeaths as dea
JOIN
	CovidVaccinations as vac
ON
	dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3

--Add up, rolling count, partion by:  special table that is divided into segments, after reaching new location it starts over
--Invalid column name 'Rolling_new_vaccinated'. I cannot use a column I jsut created so I need to use CTE of Temp Table
--STEP 0 ERROR
SELECT 
	dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) 
	OVER (Partition by dea.location 
	ORDER BY dea.location, dea.date) as Rolling_new_vaccinated,
	(Rolling_new_vaccinated/population)*100 as Percentage_population_newly_vaccinated
FROM
	CovidDeaths as dea
JOIN
	CovidVaccinations as vac
ON
	dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3


--Add up, rolling count, partion by:  special table that is divided into segments, after reaching new location it starts over
--Use CTE (No of columns in with must be equl to no of columns in select)
--STEP 1 TEMPTABLE
WITH PopVsNewVac (Continent, Location, Date,  New_vaccinations, Population, Rolling_new_vaccinated)
as
	(
SELECT 
	dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) 
	OVER (Partition by dea.location 
	ORDER BY dea.location, dea.date) as Rolling_new_vaccinated
	--- cannot use this here (Rolling_new_vaccinated/population)*100 as Percentage_population_newly_vaccinated
FROM
	CovidDeaths as dea
JOIN
	CovidVaccinations as vac
ON
	dea.location = vac.location
AND dea.date = vac.date
WHERE 
	dea.continent is not null
)
SELECT *
FROM PopVsNewVac

--New query to get Percentage_population_newly_vaccinated
--STEP 2 GET WHAT WE COULD NOT IN STEP 0
WITH PopVsNewVac (Continent, Location, Date, Population, new_vaccinations, Rolling_new_vaccinated)
as
	(
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) 
	OVER (Partition by dea.location 
	ORDER BY dea.location, dea.date) as Rolling_new_vaccinated
	--- cannot use this here (Rolling_new_vaccinated/population)*100 as Percentage_population_newly_vaccinated 
FROM
	CovidDeaths as dea
JOIN
	CovidVaccinations as vac
ON
	dea.location = vac.location
AND dea.date = vac.date
WHERE 
	dea.continent is not null
)
--Now we can perform
SELECT *, ROUND((Rolling_new_vaccinated/population)*100,2) as Percentage_population_newly_vaccinatedRolling 
FROM PopVsNewVac;



--TEMPTABLE, WE NEED TO SPECIFY DATA TYPE
-- You can add DROP table if exists #Percentage_population_newly_vaccinated if error, in case of making alterations 
CREATE TABLE #Percentage_population_newly_vaccinated
(continent nvarchar(255), location nvarchar(255), date datetime, population numeric, new_vaccinations numeric, Rolling_new_vaccinated numeric
)
INSERT INTO #Percentage_population_newly_vaccinated
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) 
	OVER (Partition by dea.location 
	ORDER BY dea.location, dea.date) as Rolling_new_vaccinated
	--- cannot use this here (Rolling_new_vaccinated/population)*100 as Percentage_population_newly_vaccinated 
FROM
	CovidDeaths as dea
JOIN
	CovidVaccinations as vac
ON
	dea.location = vac.location
AND dea.date = vac.date
WHERE 
	dea.continent is not null

SELECT *, ROUND((Rolling_new_vaccinated/population)*100,2) as Percentage_population_newly_vaccinatedRolling 
FROM #Percentage_population_newly_vaccinated;


--Create a view to store data for viz
Create view Percentage_population_newly_vaccinated as
SELECT 
	dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) 
	OVER (Partition by dea.location 
	ORDER BY dea.location, dea.date) as Rolling_new_vaccinated
	--(Rolling_new_vaccinated/population)*100 as Percentage_population_newly_vaccinated
FROM
	CovidDeaths as dea
JOIN
	CovidVaccinations as vac
ON
	dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not null

--It is now permamenent so now we can query on it
SELECT *
FROM Percentage_population_newly_vaccinated;