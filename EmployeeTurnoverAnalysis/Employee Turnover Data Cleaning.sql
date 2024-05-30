/*
	Data Cleaning of Employee Layoffs Worldwide
*/

SELECT *
FROM layoffs_staging;

-- First let's create a staging table. This table will be the one we work on as we don't want to alter the original table.
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * FROM layoffs;

-- ------------------------------------------------------------------------------------
 
/*
 1. Checking for duplicates and removing them
*/

SELECT company, industry, total_laid_off, `date`, 
		ROW_NUMBER() OVER (PARTITION BY company, industry, total_laid_off, `date`) AS row_num -- If there is a duplicate, the row number would be 2 or more, 1 is a unique value.
FROM layoffs_staging;

-- Using a subquery to find duplicates 
SELECT *
FROM (
	SELECT company, industry, total_laid_off, `date`, 
		ROW_NUMBER() OVER (PARTITION BY company, industry, total_laid_off, `date`) AS row_num -- If there is a duplicate, the row number would be 2 or more, 1 is a unique value.
	FROM layoffs_staging
) AS duplicates
WHERE row_num > 1;

-- Checking to see if oda is indeed duplicates or not
SELECT *
FROM layoffs_staging
WHERE company = 'oda';
-- Results show us that these are genuine entries because there are differing values in the funds_raised column


-- Let's find the duplicates that are exactly matching in all fields of the table
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (PARTITION BY  company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num -- If there is a duplicate, the row number would be 2 or more, 1 is a unique value.
	FROM layoffs_staging
) AS duplicates
WHERE row_num > 1;



-- Now we delete those rows using a delete CTE
WITH DELETE_CTE AS 
(
	SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		layoffs_staging
) duplicates
WHERE 
	row_num > 1
)
DELETE
FROM DELETE_CTE;

-- We can delete by adding a new column with the row number and deleting any observation with a row number greater than 1, so let's try that!
ALTER TABLE layoffs_staging 
ADD row_num INT;

CREATE TABLE `layoffs_staging2` (
`company` text,
`location`text,
`industry`text,
`total_laid_off` INT,
`percentage_laid_off` text,
`date` text,
`stage`text,
`country` text,
`funds_raised_millions` int,
row_num INT
);

INSERT INTO `layoffs_staging2`
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		layoffs_staging;
        
SELECT *
FROM layoffs_staging2;

-- Now we delete the rows with row number of 2 or greater
DELETE FROM layoffs_staging2
WHERE row_num >= 2;

-- ----------------------------------------------------------------------------------

/*
	2. Standardizing data
*/ 

-- Checking for null or empty string values for each field

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL or industry = ''
ORDER BY industry; -- Industry has 4 null or empty values, let's explore whether they are intentionally left as such or it is a mistake

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Airbnb%';

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Carvana%';

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Juul%';

-- Based on the 4 queries above, Bally's is fine but the other 3 have other records with the industry. So we need to populate the null or empty values with the industry of the
-- corresponding company. 

-- Write a query that if there is another row with same company name, it will populate the industry using the other row

-- Let's set blanks to nulls as they are easier to work with
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Lets check that they are all null
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL or industry = ''
ORDER BY industry;

-- Let's populate these fields using existing values of other records with the same company name. Use Self-Join.
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
	AND t2.industry IS NOT NULL;


-- Crypto has many different variations, lets standardize to Crypto for all of them
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry IN ('Crypto Currency', 'CryptoCurrency');

-- We standardized it!
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

-- Let's fix the country field as some rows have United States and United States. with a period
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

-- We have null values in our date column and it is in text format, let's change the format
SELECT *
FROM layoffs_staging2
WHERE `date` IS NULL;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoffs_staging2;

-- ----------------------------------------------------------------------------------

/*
	3. Look at null values
*/ 

-- Checking null values for total_laid_off, percentage_laid_off, and funds_raised_millions, but these are meaningful 
-- values as it is not required to provide a value here so we will move on.
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL or percentage_laid_off IS NULL or funds_raised_millions IS NULL;

/*
	4. Remove any columns and rows we don't need
*/ 

-- Let's remove the rows that don't provide any information in these fields, they won't help us later on in performing aggregations or analysis
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
	AND percentage_laid_off IS NULL;

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL 
	AND percentage_laid_off IS NULL;
    
-- And finally let's drop the row number as we no longer need it 
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;