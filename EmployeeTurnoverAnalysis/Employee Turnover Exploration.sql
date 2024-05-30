/*
	Data Exploration of Employee Layoffs Worldwide
*/

SELECT *
FROM layoffs;

-- Basic exploration:
-- Max and min values for percentage_total_laid_off
SELECT max(percentage_laid_off) MaximumTurnover, min(percentage_laid_off) MinimumTurnover
FROM layoffs
WHERE total_laid_off IS NOT NULL;

-- Which company had a percentage value of 1 in their layoffs, essentially the entire company was laid off?
SELECT *
FROM layoffs
WHERE percentage_laid_off = 1;

-- Ordering by funds_raised to see who large these companies are in their operations
SELECT *
FROM layoffs
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
-- Funds raised were quite small, indicating they were most startups that failed


-- Companies with the highest number of laid off employees each year
SELECT company , total_laid_off, YEAR(layoffs.date) current_year
FROM layoffs
WHERE layoffs.date IS NOT NULL
ORDER BY total_laid_off DESC;

-- Average funds raised in each country around the world
SELECT country, AVG(funds_raised_millions) avg_funds_raised_millions
FROM layoffs
GROUP BY country
ORDER BY avg_funds_raised_millions DESC;

-- Finding the average percentage of laid off employees during each stage of a company?
SELECT stage, avg(percentage_laid_off) avg_percentage_laid_off
FROM layoffs
GROUP BY stage
ORDER BY avg_percentage_laid_off DESC;

-- Which industries garner the highest number of employee turnover?
SELECT industry, sum(total_laid_off) sum_employee_turnover
FROM layoffs
GROUP BY industry
ORDER BY sum_employee_turnover DESC;

-- Which location (cities) have the highest employee turnover each year and is there an increasing trend?
SELECT location, max(total_laid_off) max_employee_turnover
FROM layoffs
GROUP BY location
ORDER BY max_employee_turnover DESC;

-- Tougher queries
-- Were computing rankings for the companies total_laid_off each year using dense rank and partition by, we're also using subqueries, we're getting the top 5 companies
WITH Company_Year AS 
(
	SELECT company, YEAR(date) AS years, sum(total_laid_off) AS total_laid_off
	FROM layoffs
	GROUP BY company, YEAR(date)
)
, Company_Year_Rank AS (
	SELECT company, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
    FROM Company_Year
)
SELECT company, years, total_laid_off, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;

-- Rolling total of layoffs per month
SELECT SUBSTRING(date,1,7) AS Months, SUM(total_laid_off) AS total_laid_off
FROM layoffs
GROUP BY dates
ORDER BY dates ASC;

-- We will use rolling total query as a CTE
WITH DATE_CTE AS 
(
SELECT SUBSTRING(date,1,7) AS dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) AS rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;