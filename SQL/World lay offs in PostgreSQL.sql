-- Data Cleaning 
 -- Original Dataset

SELECT *
FROM public.layoffs;


-- Creating a copy of an original dataset

CREATE TABLE layoffs_staging (LIKE layoffs INCLUDING ALL);


INSERT INTO layoffs_staging
  (SELECT *
   FROM layoffs);


SELECT *
FROM layoffs_staging;

-- Changing data types 

SELECT "date",
CAST("date" AS DATE)
FROM layoffs_staging;

 -- Let's run a query to find strings that 
 -- do not follow the MM/DD/YYYYYY format:
SELECT "date"
FROM layoffs_staging
WHERE "date" !~ '^\d{1,2}/\d{1,2}/\d{4}$';

 -- And delete them from table 
DELETE FROM layoffs_staging
WHERE "date" !~ '^\d{1,2}/\d{1,2}/\d{4}$';

 -- Now change data type from varchar to date
ALTER TABLE layoffs_staging
ALTER COLUMN "date" TYPE DATE
USING TO_DATE("date", 'MM/DD/YYYY');

-- Updading NULL values 
UPDATE layoffs_staging
SET industry = NULL 
WHERE TRIM(industry) = ''
OR LOWER(industry) = 'null';

-- Let's change blank values to NULL values
UPDATE layoffs_staging
SET total_laid_off = NULL 
WHERE total_laid_off LIKE 'NULL';

UPDATE layoffs_staging
SET percentage_laid_off = NULL 
WHERE percentage_laid_off LIKE 'NULL';

-- Let's change data type to INTEGER OR FLOAT

ALTER TABLE layoffs_staging
ALTER COLUMN total_laid_off TYPE INTEGER
USING total_laid_off::INTEGER;

ALTER TABLE layoffs_staging
ALTER COLUMN percentage_laid_off TYPE INTEGER
USING percentage_laid_off::INTEGER;

UPDATE layoffs_staging
SET funds_raised_millions = NULL 
WHERE funds_raised_millions = 'NULL';

ALTER TABLE layoffs_staging
ALTER COLUMN funds_raised_millions TYPE FLOAT
USING funds_raised_millions::FLOAT;


-- Deleting duplicates
 -- Creating CTE which include all rows and number of those rows. If number is greater than 1 then we can call it a duplicate
 WITH duplicates_cte AS
  (SELECT *,
          ROW_NUMBER () OVER (PARTITION BY company, "location", industry, total_laid_off, percentage_laid_off, "date", stage, country, funds_raised_millions) AS row_num
   FROM layoffs_staging)
SELECT *
FROM duplicates_cte
WHERE row_num > 1;

-- Deleting duplicates using subquery:

DELETE
FROM layoffs_staging
WHERE ctid IN
    (SELECT ctid
     FROM
       (SELECT ctid,
               ROW_NUMBER() OVER(PARTITION BY company, "location", industry, total_laid_off, percentage_laid_off, "date", stage, country, funds_raised_millions) AS row_num
        FROM layoffs_staging) ls
     WHERE ls.row_num > 1);

-- Standardizing data
 
    -- First let's look at 'company' field
SELECT DISTINCT company
FROM layoffs_staging;

-- Looking for typos in company names - white spaces in the beggining of the name

SELECT company,
       TRIM(company)
FROM layoffs_staging
WHERE company LIKE ' %' 

 -- Using TRIP function to update company field and get rid of spaces in the beggining of the name

UPDATE layoffs_staging
SET company = TRIM(company);

 -- Looking into industry field 
SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1;

 -- We have found industry name 'Crypto' and 'Cryptocurrency' which is the same name, 
 -- let's filter on 'Crypto%'
 -- and see how many duplicates are there
SELECT *
FROM layoffs_staging
WHERE industry LIKE 'Crypto%';

 -- Looks like "Crypto" and "Cryptocurrency" is the same thing, so let's just update that
UPDATE	layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

 -- Looks like there is no issue with location filed
SELECT "location"
FROM layoffs_staging;

 -- Let's see if there any promlebs with country field
SELECT DISTINCT country
FROM layoffs_staging;

 -- Looks like there is a dot at the end of 'United States' 
 -- which we want to get rid of
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging;

 -- Updating table 
UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'


-- Populating data 
 -- Let's try and find NULL or blank values and try to populate them using data that we are working with

SELECT *
FROM layoffs_staging
WHERE  industry IS NULL;

 -- We've got several companies with blank or NULL values in industry field
 -- Let's try to filter on those company names and see if there are data about industry 
	 -- Companies to check: 
	 -- Juul
	 -- Carvana
	 -- Airbnb
	 -- Bally's Interactive

SELECT *
FROM layoffs_staging
WHERE company = 'Airbnb'; -- Change Industry : Travel

SELECT *
FROM layoffs_staging
WHERE company = 'Juul'; -- Change Industry : Consumer

SELECT *
FROM layoffs_staging
WHERE company = 'Carvana'; -- Change Industry : Transportation

SELECT *
FROM layoffs_staging
WHERE company LIKE 'Bally%'; -- Cannot CHANGE Industry because there IS NO DATA TO populate FROM

 -- Airbnb has another row that sais that industry they are working in is 'Travel'
 -- so let's try to populate the data using subquery

 -- Populating the data
UPDATE layoffs_staging
SET industry = subquery.industry
FROM ( SELECT *
		FROM layoffs_staging ls
		WHERE ls.industry IS NOT NULL
) AS subquery 
WHERE layoffs_staging.company = subquery.company
  AND layoffs_staging.industry IS NULL;
  
 
 -- And now let's filter on fields: 'total_laid_off' and 'percentage_laid_off'
 -- to try to find row where both of those fields and NULL
SELECT *
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
 -- In this project we dont need that data, so we will just delete those rows 

DELETE
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;



-- And now let's do some Exploratory Data Analysis using PostgreSQL

 -- I want to take a look at:
	-- Range of dates this data provides
	-- Sum of total laid offs for each company, industry, counry
	-- Rolling total of laid offs per month, per year
	-- Top 5 companies with most total laid offs per year, per month

-- Range of dates this data provides

SELECT MAX("date"), MIN("date")
FROM layoffs_staging;

-- Sum of total laid offs for each company, industry, counry

-- Let's find total sum for each company

SELECT company, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging
GROUP BY company
HAVING  SUM(total_laid_off) IS NOT NULL -- filtering ONLY NOT NULL VALUES 
ORDER BY 2 DESC;

-- And for each industry:

SELECT industry, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging
GROUP BY industry
HAVING  SUM(total_laid_off) IS NOT NULL -- filtering ONLY NOT NULL VALUES 
ORDER BY 2 DESC;

-- And for each country:

SELECT country, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging
GROUP BY country
HAVING  SUM(total_laid_off) IS NOT NULL -- filtering ONLY NOT NULL VALUES 
ORDER BY 2 DESC;

-- Rolling total of laid offs per year and per month

WITH company_laid_off(date_laid_off, sum_laid_off) AS (
SELECT 
date_trunc('month', "date")::date,
SUM(total_laid_off)
FROM layoffs_staging
GROUP BY 1
HAVING SUM(total_laid_off) IS NOT NULL
ORDER BY 1 ASC
)
SELECT date_laid_off,
	sum_laid_off,
SUM(sum_laid_off) OVER(ORDER BY date_laid_off) AS rolling_total
FROM company_laid_off;

-- Top 5 companies with most total laid offs per year

WITH Company_laid_off(company, date_laid_off, sum_laid_off) AS (
SELECT company,
	EXTRACT(YEAR FROM "date"),
	SUM(total_laid_off)
FROM layoffs_staging
GROUP BY 1,2
HAVING SUM(total_laid_off) IS NOT NULL
ORDER BY 3 DESC
), Ranking AS (
SELECT company, date_laid_off, sum_laid_off,
	DENSE_RANK() OVER (PARTITION BY date_laid_off ORDER BY sum_laid_off DESC) AS ranking
FROM Company_laid_off
)
SELECT *
FROM Ranking
WHERE ranking <= 5
; 



