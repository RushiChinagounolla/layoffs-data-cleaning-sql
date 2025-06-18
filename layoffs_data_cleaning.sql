-- ===============================================================
-- 🧹 LAYOFFS DATA CLEANING PROJECT
-- Dataset Source: https://www.kaggle.com/datasets/swaptr/layoffs-2022
-- Purpose: Cleaning and preparing raw layoffs data for analysis using SQL.
-- Note: This project includes all intermediate steps to showcase the full data cleaning workflow.
-- ===============================================================


-- STEP 1: Viewing the raw dataset
-- Displaying the raw data from the 'layoffs' table to understand its structure.
SELECT *
FROM layoffs;


-- STEP 2: Creating a staging table
-- Creating a working copy of the original table to preserve the raw dataset.
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Displaying the newly created staging table.
SELECT * FROM layoffs_staging;

-- Inserting data from the original 'layoffs' table into the staging table.
INSERT layoffs_staging
SELECT *
FROM layoffs;


-- STEP 3: Exploring column names
-- Listing all column names in the 'layoffs_staging' table.
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'layoffs_staging'
AND TABLE_SCHEMA = 'world_layoffs';


-- STEP 4: Manually checking for known duplicates
-- Looking at specific companies known to have duplicates for inspection.
SELECT *
FROM layoffs_staging
WHERE company = 'Casper' OR company = 'Yahoo';


-- STEP 5: Creating a second staging table with row numbers
-- Preparing a new table with row numbers assigned to identify duplicates.
CREATE TABLE layoffs_staging2 (
  company TEXT,
  location TEXT,
  industry TEXT,
  total_laid_off TEXT,
  percentage_laid_off TEXT,
  date TEXT,
  stage TEXT,
  country TEXT,
  funds_raised_millions TEXT,
  row_num INT
);

-- Populating layoffs_staging2 with data and row numbers for each duplicate group.
INSERT INTO layoffs_staging2
SELECT *, ROW_NUMBER() OVER (
  PARTITION BY total_laid_off, stage, percentage_laid_off, location,
               industry, funds_raised_millions, `date`, country, company
) AS row_num
FROM layoffs_staging;

-- Displaying the contents of the second staging table.
SELECT * 
FROM layoffs_staging2;

-- Filtering and displaying the duplicate records (row_num > 1).
SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;


-- STEP 6: Deleting duplicate rows
-- Removing duplicate rows by keeping only the first occurrence in each group.
DELETE
FROM layoffs_staging2
WHERE row_num > 1;


-- STEP 7: Replacing empty string values with NULL
-- Converting empty string values ('') to SQL NULLs to standardize missing data entries.
UPDATE layoffs_staging2
SET
  total_laid_off = NULLIF(total_laid_off, ''),
  stage = NULLIF(stage, ''),
  percentage_laid_off = NULLIF(percentage_laid_off, ''),
  location = NULLIF(location, ''),
  industry = NULLIF(industry, ''),
  funds_raised_millions = NULLIF(funds_raised_millions, ''),
  `date` = NULLIF(`date`, ''),
  country = NULLIF(country, ''),
  company = NULLIF(company, '');


-- STEP 8: Exploring missing industry values
-- Finding records where the 'industry' field is missing.
SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL;

-- Looking up specific company entries for potential data reuse.
SELECT * 
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Investigating possible fill-in values from similar company + location
SELECT *
FROM layoffs_staging2 ls1
JOIN layoffs_staging2 ls2
  ON ls1.company = ls2.company
 AND ls1.location = ls2.location
WHERE ls1.industry IS NULL
  AND ls2.industry IS NOT NULL
ORDER BY ls1.company;

-- Showing before and after values for reference
SELECT ls1.industry, ls2.industry
FROM layoffs_staging2 ls1
JOIN layoffs_staging2 ls2
  ON ls1.company = ls2.company
 AND ls1.location = ls2.location
WHERE ls1.industry IS NULL
  AND ls2.industry IS NOT NULL;


-- STEP 9: Filling missing industry values
-- Using a self-join to fill in missing industry values based on matching company and location.
UPDATE layoffs_staging2 ls1
JOIN layoffs_staging2 ls2
  ON ls1.company = ls2.company AND ls1.location = ls2.location
SET ls1.industry = ls2.industry
WHERE ls1.industry IS NULL
  AND ls2.industry IS NOT NULL;


-- STEP 10: Standardizing company and industry names
-- Viewing all distinct company names before cleaning.
SELECT DISTINCT company
FROM layoffs_staging2;

-- Checking how company names appear with and without TRIM applied.
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- Trimming extra spaces from company names.
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Verifying cleaned results.
SELECT * 
FROM layoffs_staging2;

-- Viewing distinct industry values before standardization.
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Displaying rows where industry starts with 'Crypto' for review.
SELECT * 
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Standardizing industry values that start with 'Crypto'.
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Viewing distinct industry values after update.
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- STEP 11: Cleaning country field
-- Viewing distinct country values.
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- Displaying rows with country name variations for the United States.
SELECT * 
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;

-- Viewing cleaned version of country names by trimming trailing punctuation.
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- Applying the TRIM to clean United States entries.
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'; 

-- Verifying the updated results.
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- STEP 12: Converting date strings to DATE format
-- Viewing date values before format conversion.
SELECT `date`
FROM layoffs_staging2;

-- Displaying date conversion preview using STR_TO_DATE.
SELECT `date`, 
STR_TO_DATE(`date`, '%m/%d/%Y') 
FROM layoffs_staging2;

-- Updating date field to proper DATE format.
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Modifying the column type to SQL DATE.
ALTER TABLE layoffs_staging2
MODIFY `date` DATE;

-- STEP 13: Changing data types for numeric columns
-- Converting columns that should be numeric from text to integers.
ALTER TABLE layoffs_staging2
MODIFY total_laid_off INT,
MODIFY funds_raised_millions INT;


-- STEP 14: Deleting irrelevant rows
-- Checking for rows where both 'total_laid_off' and 'percentage_laid_off' are missing (already replaced '' with NULL).
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Deleting rows where both layoff metrics are absent.
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Reviewing the cleaned table after deletion.
SELECT *
FROM layoffs_staging2;

-- STEP 15: Dropping the helper column
-- Dropping the 'row_num' column as it's no longer needed.
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- FINAL STEP: Reviewing the cleaned dataset
-- Displaying the fully cleaned and transformed dataset.
SELECT *
FROM layoffs_staging2;
