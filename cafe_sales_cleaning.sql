USE cafe_sales;


SELECT *
FROM cafe_sales;

CREATE TABLE sales2
LIKE cafe_sales;

INSERT INTO sales2
SELECT *
FROM cafe_sales;

WITH CTE AS
(SELECT ROW_NUMBER () OVER (PARTITION BY `Transaction ID`, Item, Quantity, `Price Per Unit`, `Total Spent`, `Payment Method`, `Location`, 
`Transaction Date`) AS row_num
FROM  sales2)
SELECT *
FROM CTE
WHERE row_num >1;

SELECT DISTINCT(Item)
FROM cafe_sales;

UPDATE sales2
SET item = NULL
WHERE item LIKE '%UNKNOWN%' OR item LIKE '%ERROR%' OR item LIKE 'None';

SELECT DISTINCT(Item)
FROM sales2;

SELECT *
FROM sales2
WHERE Quantity REGEXP '[^0-9]';

UPDATE sales2
SET Quantity = NULL
WHERE Quantity REGEXP '[^0-9]';

UPDATE sales2
SET `Price Per Unit` = NULL
WHERE `Price Per Unit` REGEXP '[^0-9\.]';

UPDATE sales2
SET `Total Spent` = NULL
WHERE `Total Spent` REGEXP '[^0-9\.]';

SELECT *
FROM sales2;

SELECT * 
FROM sales2
WHERE Quantity REGEXP '[^0-9]';

SELECT *
FROM sales2
WHERE `Price Per Unit` REGEXP '[^0-9\.]';

SELECT *
FROM sales2
WHERE `Total Spent` REGEXP '[^0-9\.]';

SELECT DISTINCT(`Payment Method`)
FROM sales2;

UPDATE sales2
SET `Payment Method` = NULL
WHERE `Payment Method` LIKE '%UNKNOWN%' OR `Payment Method` LIKE '%ERROR%' OR `Payment Method` LIKE 'None';

SELECT DISTINCT(Location)
FROM sales2;

UPDATE sales2
SET Location = NULL
WHERE Location LIKE '%UNKNOWN%' OR Location LIKE '%ERROR%' OR Location LIKE 'None';

SELECT DISTINCT item, `Price Per Unit`
FROM sales2;



UPDATE sales2
SET `Price Per Unit` = CASE
    WHEN Item = 'Coffee' AND `Price Per Unit` IS NULL THEN 2.0
    WHEN Item = 'Tea' AND `Price Per Unit` IS NULL THEN 1.5
    WHEN Item = 'Sandwich' AND `Price Per Unit` IS NULL THEN 4.0
    WHEN Item = 'Salad' AND `Price Per Unit` IS NULL THEN 5.0
    WHEN Item = 'Cake' AND `Price Per Unit` IS NULL THEN 3.0
    WHEN Item = 'Cookie' AND `Price Per Unit` IS NULL THEN 1.0
    WHEN Item = 'Juice' AND `Price Per Unit` IS NULL THEN 3.0
    WHEN Item = 'Smoothie' AND `Price Per Unit` IS NULL THEN 4.0
    ELSE `Price Per Unit`
END;


SELECT COUNT(*) AS null_rows
FROM sales2
WHERE Quantity IS NULL
   OR `Price Per Unit` IS NULL
   OR `Total Spent` IS NULL;
   
   SELECT COUNT(*)
   FROM sales2
   WHERE `Price Per Unit` IS NULL;
   
UPDATE sales2
SET `Price Per Unit` = `Total Spent` / Quantity
WHERE `Price Per Unit` IS NULL;

SELECT *
   FROM sales2
   WHERE `Price Per Unit` IS NULL;

-- This is calculating the mode (i.e the most reccuring number in the factor)
SELECT `Price Per Unit`
FROM sales2
GROUP BY `Price Per Unit`
ORDER BY COUNT(*) DESC
LIMIT 1;

-- Here since there are only 6 records missing, it was filled with the mode due to its low significance rate to actual analysis
-- But missing value `Price Per Unit` could further refined with mode based on categorical factors such as Payment Method, Item, Location and even transaction date
-- For date mode needs to be based on months
UPDATE sales2
SET `Price Per Unit` = 3.0
WHERE `Price Per Unit` IS NULL;

UPDATE sales2
SET Item = CASE
    WHEN `Price Per Unit` = 2.0 AND Item IS NULL THEN 'Coffee'
    WHEN `Price Per Unit` = 1.5 AND Item IS NULL THEN 'Tea'
    WHEN `Price Per Unit` = 4.0 AND Item IS NULL THEN 'Sandwich'
    WHEN `Price Per Unit` = 5.0 AND Item IS NULL THEN 'Salad'
    WHEN `Price Per Unit` = 3.0 AND Item IS NULL THEN 'Cake'
    WHEN `Price Per Unit` = 1.0 AND Item IS NULL THEN 'Cookie'
    ELSE Item
END;

SELECT *
FROM sales2
WHERE `Total Spent` IS NULL;

UPDATE sales2
SET `Total Spent` = `Price Per Unit` * Quantity
WHERE `Total Spent` IS NULL;

SELECT `Total Spent`
FROM sales2
WHERE Item = 'Juice'
GROUP BY `Total Spent`
ORDER BY COUNT(*) DESC
LIMIT 1;

SELECT DISTINCT Item
FROM sales2;

-- Calculating the modes of all total_spent based on items
WITH ranked_totals AS (
  SELECT 
    Item,
    `Total Spent`,
    COUNT(*) AS freq,
    ROW_NUMBER() OVER (PARTITION BY Item ORDER BY COUNT(*) DESC) AS ranks
  FROM sales2
  GROUP BY Item, `Total Spent`
)
SELECT Item, `Total Spent` AS mode_total_spent, freq
FROM ranked_totals
WHERE ranks = 1;

-- the modes:
-- 'Cake': 15.0
-- 'Coffee' : 10.0
-- 'Cookie': 2.0
-- 'Salad': 25.0
-- 'Sandwich': 20.0
-- 'Smoothie': 20.0
-- 'Tea': 3.0
-- juice = 6.0

UPDATE sales2
SET `Total Spent` = 15
WHERE Item = 'Cake' AND `Total Spent` IS NULL;

UPDATE sales2
SET `Total Spent` = 2
WHERE Item = 'Cookie' AND `Total Spent` IS NULL;

UPDATE sales2
SET `Total Spent` = 6
WHERE Item = 'Juice' AND `Total Spent` IS NULL;


SELECT *
FROM sales2
WHERE `Total Spent` IS NULL;

SELECT DISTINCT `Payment Method`
FROM sales2;

SELECT COUNT(*)
FROM sales2
WHERE `Payment Method` IS NULL;

SELECT `Payment Method`, COUNT(*) AS frequency
FROM sales2
GROUP BY `Payment Method`
ORDER BY frequency DESC;

-- EITHER calcualte the proportion of payment methods which is:
-- Proportions:

-- Digital Wallet: 2291 / 6822 ≈ 33.58%

-- Credit Card: 2273 / 6822 ≈ 33.31%

-- Cash: 2258 / 6822 ≈ 33.11%

-- Let’s say there are 3178 NULLs — we’ll distribute them proportionally:

-- Digital Wallet: 3178 × 0.3358 ≈ 1067

-- Credit Card: 3178 × 0.3331 ≈ 1058

-- Cash: 3178 × 0.3311 ≈ 1053

-- AND update the tables and set it as the values calculate above

-- Digital Wallet
UPDATE sales2
SET `Payment Method` = 'Digital Wallet'
WHERE `Payment Method` IS NULL
LIMIT 1067;

-- Credit Card
UPDATE sales2
SET `Payment Method` = 'Credit Card'
WHERE `Payment Method` IS NULL
LIMIT 1058;

-- Cash
UPDATE sales2
SET `Payment Method` = 'Cash'
WHERE `Payment Method` IS NULL
LIMIT 1053;


-- OR METHOD 2:

WITH method_counts AS (
    SELECT 
        'Digital Wallet' AS method, 2291 AS count
    UNION ALL
    SELECT 'Credit Card', 2273
    UNION ALL
    SELECT 'Cash', 2258
),
totals AS (
    SELECT SUM(count) AS total FROM method_counts
),
distribution AS (
    SELECT 
        method,
        ROUND(3178 * (count / (SELECT total FROM totals))) AS nulls_to_assign
    FROM method_counts
),
null_rows AS (
    SELECT rowid
    FROM sales2
    WHERE `Payment Method` IS NULL
    LIMIT 3178
),
numbered_nulls AS (
    SELECT 
        rowid,
        ROW_NUMBER() OVER () AS rn
    FROM null_rows
)
-- Final update for each group
UPDATE sales2
JOIN numbered_nulls ON sales2.rowid = numbered_nulls.rowid
SET `Payment Method` = CASE 
    WHEN rn <= (SELECT nulls_to_assign FROM distribution WHERE method = 'Digital Wallet') THEN 'Digital Wallet'
    WHEN rn <= (SELECT SUM(nulls_to_assign) FROM distribution WHERE method IN ('Digital Wallet', 'Credit Card')) THEN 'Credit Card'
    ELSE 'Cash'
END;

SELECT *
FROM sales2;

SELECT Location, COUNT(*) AS frequency
FROM sales2
GROUP BY Location
ORDER BY frequency DESC;

-- Calculations for proportions:

-- Takeaway: 3022

-- In-store: 3017

-- Total known = 3022 + 3017 = 6039

-- Proportions:
-- Takeaway: 3022 / 6039 ≈ 0.5002

-- In-store: 3017 / 6039 ≈ 0.4998

-- Apply proportions to 3961 NULLs:
-- Takeaway: 3961 × 0.5002 ≈ 1982

-- In-store: 3961 × 0.4998 ≈ 1979

SELECT *
FROM sales2
WHERE Location IS NULL;

-- Takeaway
UPDATE sales2
SET Location = 'Takeaway'
WHERE Location IS NULL
LIMIT 1982;

-- In-store
UPDATE sales2
SET Location = 'In-store'
WHERE Location IS NULL
LIMIT 1979;

SELECT *
FROM sales2;

CREATE TABLE sales3 LIKE sales2;

INSERT INTO sales3
SELECT *
FROM sales2;

SELECT *
FROM sales3
WHERE `Transaction Date` IS NULL;

UPDATE sales3
SET Quantity = `Total Spent`/`Price Per Unit`
WHERE Quantity IS NULL;



UPDATE sales3
SET `Transaction Date` = 
  CASE
    WHEN `Transaction Date` REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' 
      THEN STR_TO_DATE(`Transaction Date`, '%Y-%m-%d')
    ELSE NULL
  END;
  
ALTER TABLE sales3
MODIFY COLUMN `Transaction Date` DATE;

  
  SELECT *
  FROM sales3
  WHERE `Transaction Date` IS NULL;
  
  -- Update NULL Transaction Dates with random dates from 2023-01-01 to 2023-12-31
UPDATE sales3
SET `Transaction Date` = DATE_ADD('2023-01-01', INTERVAL FLOOR(RAND() * 365) DAY)
WHERE `Transaction Date` IS NULL;

SELECT *
FROM sales3
WHERE `Transaction ID` IS NULL
OR Item IS NULL
OR Quantity IS NULL
OR `Price Per Unit` IS NULL
OR `Total Spent` IS NULL
OR `Payment Method` IS NULL
OR Location IS NULL
 OR `Transaction Date` IS NULL;












   
   

















