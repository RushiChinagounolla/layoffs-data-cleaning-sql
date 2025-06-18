-- ===============================================================
-- 📊 LAYOFFS EXPLORATORY DATA ANALYSIS (EDA)
-- Dataset Source: https://www.kaggle.com/datasets/swaptr/layoffs-2022.
-- Purpose: Analyzing cleaned layoff data to extract trends and insights.
-- Note: Analysis is based on the cleaned table 'layoffs_staging2'
-- ===============================================================

-- STEP 1: Reviewing the cleaned dataset
-- Displaying all rows to get an initial understanding of the data.
SELECT *
FROM layoffs_staging2;

-- STEP 2: Finding maximum values
-- Getting the highest total layoffs in a single record.
SELECT MAX(total_laid_off)
FROM layoffs_staging2;

-- Retrieving max values for both layoffs and percentage laid off.
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- STEP 3: Identifying companies with 100% layoffs
-- Filtering companies where the entire workforce was laid off, ordered by total laid off.
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Also ordering by funding raised to assess financial position.
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- STEP 4: Layoffs by company
-- Summing total layoffs by company to find most affected ones.
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- STEP 5: Date range of layoffs
-- Finding the earliest and latest layoff dates.
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- STEP 6: Layoffs by industry
-- Summing layoffs for each industry.
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- STEP 7: Layoffs by country
-- Aggregating layoffs by country.
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- STEP 8: Layoffs by exact date
-- Viewing total layoffs grouped by each unique date.
SELECT `date`, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY `date`
ORDER BY 1 DESC;

-- STEP 9: Layoffs by year
-- Aggregating layoffs by year for trend analysis.
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- STEP 10: Layoffs by month
-- Extracting YYYY-MM from date and summarizing monthly totals.
SELECT SUBSTRING(`date`, 1, 7) AS `month`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC;

-- STEP 11: Rolling monthly layoffs (cumulative)
-- Creating a rolling total over months to visualize growth.
WITH ROLLING_TOTAL AS (
  SELECT SUBSTRING(`date`, 1, 7) AS `month`, SUM(total_laid_off) AS total_off
  FROM layoffs_staging2
  WHERE `date` IS NOT NULL
  GROUP BY `month`
  ORDER BY 1 ASC
)
SELECT `month`, total_off,
       SUM(total_off) OVER (ORDER BY `month`) AS rolling_total
FROM ROLLING_TOTAL;

-- STEP 12: Yearly rolling totals
-- Calculating rolling layoffs for each year using a window function.
WITH ROLLING_TOTAL AS (
  SELECT SUBSTRING(`date`, 1, 7) AS `month`, SUM(total_laid_off) AS total_off
  FROM layoffs_staging2
  WHERE `date` IS NOT NULL
  GROUP BY `month`
  ORDER BY 1 ASC
)
SELECT *,
       SUM(total_off) OVER (PARTITION BY SUBSTRING(`month`, 1, 4) ORDER BY `month`) AS rolling_total
FROM ROLLING_TOTAL;

-- STEP 13: Yearly layoffs by company
-- Summing layoffs per company per year.
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 1;

-- STEP 14: Ranking companies by yearly layoffs
-- Ranking companies within each year using DENSE_RANK.
WITH RANKING AS (
  SELECT company, YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_off
  FROM layoffs_staging2
  GROUP BY company, `year`
  ORDER BY 1
)
SELECT *, DENSE_RANK() OVER (PARTITION BY `year` ORDER BY total_off DESC) AS ranking
FROM RANKING
WHERE `year` IS NOT NULL
ORDER BY ranking;

-- STEP 15: Top 5 companies per year
-- Extracting top 5 companies by layoffs for each year.
WITH RANKING AS (
  SELECT company, YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_off
  FROM layoffs_staging2
  GROUP BY company, `year`
  ORDER BY 1
), COMPANY_YEAR_RANK AS (
  SELECT *, DENSE_RANK() OVER (PARTITION BY `year` ORDER BY total_off DESC) AS ranking
  FROM RANKING
  WHERE `year` IS NOT NULL
)
SELECT *
FROM COMPANY_YEAR_RANK
WHERE ranking <= 5;
