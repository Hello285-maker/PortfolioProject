--Selecting all of the columns to understand the context
SELECT *
FROM Portfolio_Project_1.dbo.COVIDDeaths
ORDER BY 1,2


--Looking at Total Deaths VS Total Cases. 
--Further,It showcases an estimate of mortality rate due to COVID in the Philippines Since the start of Pandemic.
SELECT location, date, CAST(total_cases AS DECIMAL(15,3)) AS TotalCases, CAST(total_deaths AS DECIMAL(15,3)) AS TotalDeaths, CAST(total_deaths AS DECIMAL(15,3))/CAST(total_cases AS DECIMAL(15,3))*100 AS DeathsPercentage
FROM Portfolio_Project_1.dbo.COVIDDeaths
WHERE location = 'Philippines'
ORDER BY 1,2


--Looking at Total Cases VS Population. 
--Further, It showcases a COVID Case Percentage with respect to the Population of the Philippines.
SELECT location, date, CAST(total_cases AS DECIMAL(15,3)) AS TotalCases, CAST(population AS DECIMAL(15,3)) AS Population, CAST(total_cases AS DECIMAL(15,3))/CAST(population AS DECIMAL(15,3))*100 AS CasePercentage
FROM Portfolio_Project_1.dbo.COVIDDeaths
WHERE location = 'Philippines'
ORDER BY 1,2


--Countries with Highest Infection rate
SELECT location, population, MAX(CAST(total_cases AS DECIMAL(15,3))) AS HighestInfectionCount, MAX((CAST(total_cases AS DECIMAL(15,3)))/CAST(population AS DECIMAL(15,3)))*100 AS HighestInfectionRate
FROM Portfolio_Project_1.dbo.COVIDDeaths
GROUP BY location, population
ORDER BY HighestInfectionRate DESC


--Checking for the Continents included in the Dataset
SELECT DISTINCT continent
FROM Portfolio_Project_1.dbo.COVIDDeaths


--Checking for the Total Death Count for each Continent by finding the Maximum number of Total Death for each continent present in the location column
SELECT location, MAX(cast(total_deaths as DECIMAL(15,3))) AS TotalDeathCount
FROM Portfolio_Project_1.dbo.COVIDDeaths
WHERE location IN ('Asia','Africa','North America', 'Europe','South America','Oceania')
GROUP BY location 
ORDER BY TotalDeathCount DESC


--Checking for the Latest Date
SELECT*
FROM Portfolio_Project_1.dbo.COVIDDeaths
ORDER BY date DESC


--Double Checking the result from the Query of Total Death Count by Summing the latest death count per country and grouping them based on the Continent
SELECT continent, SUM(cast(total_deaths as DECIMAL(15,3))) AS TotalDeathCount
FROM Portfolio_Project_1.dbo.COVIDDeaths death
WHERE date='2023-07-12 00:00:00.000' and continent is not null
GROUP BY death.continent
ORDER BY TotalDeathCount DESC


--Checking Global Numbers based on date
SELECT SUM(CAST(new_cases as int)) AS TotalCases, SUM(CAST(new_deaths as int)) AS TotalDeaths, SUM(CAST(new_deaths as int))/ SUM(CAST(new_cases as int))*100 AS DeathPercentage
FROM Portfolio_Project_1.dbo.COVIDDeaths
WHERE continent is not null 


--Total Population VS Vaccinations Rolled Out
--Shows percentage of population which recieved atleast 1 COVID Vaccination shot

SELECT dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM Portfolio_Project_1.dbo.COVIDDeaths dea
INNER JOIN Portfolio_Project_1.dbo.COVIDVaccinations vac
	ON dea.location=vac.location AND dea.date=vac.date
ORDER BY 2,3 


--Since it is not possible to do calculations using the results from the aggregate function, we will then use a CTL to perform this function

WITH PopVsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
FROM Portfolio_Project_1.dbo.COVIDDeaths dea
INNER JOIN Portfolio_Project_1.dbo.COVIDVaccinations vac
	ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent is not null
)
SELECT  *,(RollingPeopleVaccinated)/Population *100 AS PercentOfPopulationVaccinated
FROM PopVsVac



--Creating a Temp Table for storing the values in the Table for use in different functions later on

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent,dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
FROM Portfolio_Project_1.dbo.COVIDDeaths dea
INNER JOIN Portfolio_Project_1.dbo.COVIDVaccinations vac
	ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated)/Population *100
FROM #PercentPopulationVaccinated
ORDER BY Location, Date


--Creating View to store data for later visualization
CREATE VIEW PercentPopulationVaccinated AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From Portfolio_Project_1.dbo.CovidDeaths dea
Join Portfolio_Project_1.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 