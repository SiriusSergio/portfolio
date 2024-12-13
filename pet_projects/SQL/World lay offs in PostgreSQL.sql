-- Очистка данных
-- Исходный датасет

SELECT *
FROM public.layoffs;


-- Создание копии исходного датасета

CREATE TABLE layoffs_staging (LIKE layoffs INCLUDING ALL);


INSERT INTO layoffs_staging
  (SELECT *
   FROM layoffs);


SELECT *
FROM layoffs_staging;

-- Изменение типов данных

-- Просмотр и изменение формата даты
SELECT "date",
CAST("date" AS DATE)
FROM layoffs_staging;

 -- Запустим запрос для поиска строк, которые не соответствуют формату MM/DD/YYYY
SELECT "date"
FROM layoffs_staging
WHERE "date" !~ '^\d{1,2}/\d{1,2}/\d{4}$';

-- Удалим строки с неверным форматом даты
DELETE FROM layoffs_staging
WHERE "date" !~ '^\d{1,2}/\d{1,2}/\d{4}$';

-- Теперь изменим тип данных на DATE
ALTER TABLE layoffs_staging
ALTER COLUMN "date" TYPE DATE
USING TO_DATE("date", 'MM/DD/YYYY');

-- Обновление значений NULL

-- Обновляем поле industry, чтобы заменить пустые строки и строку со значением 'NULL' на NULL
UPDATE layoffs_staging
SET industry = NULL 
WHERE TRIM(industry) = ''
OR LOWER(industry) = 'null';

-- Заменяем пустые значения на NULL в поле total_laid_off
UPDATE layoffs_staging
SET total_laid_off = NULL 
WHERE total_laid_off LIKE 'NULL';

-- То же для поля percentage_laid_off
UPDATE layoffs_staging
SET percentage_laid_off = NULL 
WHERE percentage_laid_off LIKE 'NULL';

-- Изменяем тип данных для total_laid_off на INTEGER
ALTER TABLE layoffs_staging
ALTER COLUMN total_laid_off TYPE INTEGER
USING total_laid_off::INTEGER;

-- Изменяем тип данных для percentage_laid_off на INTEGER
ALTER TABLE layoffs_staging
ALTER COLUMN percentage_laid_off TYPE INTEGER
USING percentage_laid_off::INTEGER;

-- Заменяем 'NULL' на NULL для поля funds_raised_millions
UPDATE layoffs_staging
SET funds_raised_millions = NULL 
WHERE funds_raised_millions = 'NULL';

-- Изменяем тип данных для поля funds_raised_millions на FLOAT
ALTER TABLE layoffs_staging
ALTER COLUMN funds_raised_millions TYPE FLOAT
USING funds_raised_millions::FLOAT;


-- Удаление дубликатов
-- Создаем CTE (Common Table Expression), чтобы получить все строки и их порядковый номер
 WITH duplicates_cte AS
  (SELECT *,
          ROW_NUMBER () OVER (PARTITION BY company, "location", industry, total_laid_off, percentage_laid_off, "date", stage, country, funds_raised_millions) AS row_num
   FROM layoffs_staging)
SELECT *
FROM duplicates_cte
WHERE row_num > 1;

-- Удаление дубликатов с использованием подзапроса
DELETE
FROM layoffs_staging
WHERE ctid IN
    (SELECT ctid
     FROM
       (SELECT ctid,
               ROW_NUMBER() OVER(PARTITION BY company, "location", industry, total_laid_off, percentage_laid_off, "date", stage, country, funds_raised_millions) AS row_num
        FROM layoffs_staging) ls
     WHERE ls.row_num > 1);

-- Стандартизация данных

-- Просмотр уникальных значений в поле 'company' для поиска ошибок
SELECT DISTINCT company
FROM layoffs_staging;

-- Поиск опечаток в названиях компаний (например, пробелы в начале названия)
SELECT company,
       TRIM(company)
FROM layoffs_staging
WHERE company LIKE ' %' 

-- Используем функцию TRIM для обновления поля 'company' и удаления пробелов в начале
UPDATE layoffs_staging
SET company = TRIM(company);

-- Просмотр уникальных значений в поле 'industry'
SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1;

 -- Обнаружены два значения 'Crypto' и 'Cryptocurrency', которые означают одно и то же
-- Заменим все значения, начинающиеся на 'Crypto', на 'Crypto'
SELECT *
FROM layoffs_staging
WHERE industry LIKE 'Crypto%';

UPDATE	layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

 -- Проверка поля 'location' — нет проблем, оставляем без изменений
SELECT "location"
FROM layoffs_staging;

-- Проверка поля 'country' на наличие лишних символов, например, точек в конце названия
SELECT DISTINCT country
FROM layoffs_staging;

 -- Удалим точку в конце названия 'United States'
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging;

-- Обновление поля 'country', чтобы удалить точку в конце
UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'


-- Заполнение пропущенных данных
-- Ищем строки с NULL или пустыми значениями в поле 'industry'
SELECT *
FROM layoffs_staging
WHERE  industry IS NULL;

 -- У нас есть несколько компаний с пустыми или NULL-значениями в поле industry
 -- Давайте попробуем отфильтровать названия этих компаний и посмотреть, есть ли данные об отрасли 
	 -- Компании для проверки: 
	 -- Juul
	 -- Carvana
	 -- Airbnb
	 -- Bally's Interactive

SELECT *
FROM layoffs_staging
WHERE company = 'Airbnb'; -- Изменим на: Travel

SELECT *
FROM layoffs_staging
WHERE company = 'Juul'; -- Изменим на: Consumer

SELECT *
FROM layoffs_staging
WHERE company = 'Carvana'; -- Изменим на: Transportation

SELECT *
FROM layoffs_staging
WHERE company LIKE 'Bally%'; -- Невозможно изменить, так как нет данных для заполнения

 -- Используем подзапрос для заполнения пустых значений в поле 'industry' на основе существующих данных
UPDATE layoffs_staging
SET industry = subquery.industry
FROM ( SELECT *
		FROM layoffs_staging ls
		WHERE ls.industry IS NOT NULL
) AS subquery 
WHERE layoffs_staging.company = subquery.company
  AND layoffs_staging.industry IS NULL;
  
 
 -- Поиск строк, где оба поля 'total_laid_off' и 'percentage_laid_off' содержат NULL	
SELECT *
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
 
-- Эти данные не нужны, поэтому удаляем такие строки
DELETE
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;



-- А теперь давайте проведем разведывательный анализ данных с помощью PostgreSQL.

 -- Я хочу взглянуть на:
	-- Диапазон дат, в который попадают эти данные
	-- Сумму общего числа уволенных по каждой компании, отрасли, стране
	-- Сумму с накоплением увольнений за месяц, за год
	-- Топ-5 компаний с наибольшим количеством увольнений за год

-- Определим диапазон дат в данных
SELECT MAX("date"), MIN("date")
FROM layoffs_staging;

-- Сумма уволенных по компаниям
SELECT company, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging
GROUP BY company
HAVING  SUM(total_laid_off) IS NOT NULL -- фильтруем только те значения, которые не равны NULL
ORDER BY 2 DESC;

-- Сумма уволенных по отраслям
SELECT industry, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging
GROUP BY industry
HAVING  SUM(total_laid_off) IS NOT NULL -- фильтруем только те значения, которые не равны NULL
ORDER BY 2 DESC;

-- Сумма уволенных по странам
SELECT country, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging
GROUP BY country
HAVING  SUM(total_laid_off) IS NOT NULL -- фильтруем только те значения, которые не равны NULL
ORDER BY 2 DESC;

-- Скользящий итог по уволенным в разрезе месяцев
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

-- Топ 5 компаний с наибольшим количеством уволенных по годам
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



