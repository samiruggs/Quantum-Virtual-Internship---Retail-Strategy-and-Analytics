--- 1. Upload the data and load the data.

USE [Retail_Stategy_Analytics]
GO

SELECT [DATE]
      ,[STORE_NBR]
      ,[LYLTY_CARD_NBR]
      ,[TXN_ID]
      ,[PROD_NBR]
      ,[PROD_NAME]
      ,[PROD_QTY]
      ,[TOT_SALES]
  FROM [dbo].[QVI_transaction_data]

GO;

--- 2.  Make a copy of the data in case of future mistakes.

    SELECT *
    INTO transaction_data_copy
    FROM QVI_transaction_data;

--- 3. Check for duplicate rows

    WITH cte AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY 
        [DATE]
      ,[STORE_NBR]
      ,[LYLTY_CARD_NBR]
      ,[TXN_ID]
      ,[PROD_NBR]
      ,[PROD_NAME]
      ,[PROD_QTY]
      ORDER BY [TXN_ID]) AS rn
      FROM transaction_data_copy
)
      SELECT * FROM cte
      WHERE rn > 1;

--- 4. Delete the duplicates

      WITH cte AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY 
        [DATE]
      ,[STORE_NBR]
      ,[LYLTY_CARD_NBR]
      ,[TXN_ID]
      ,[PROD_NBR]
      ,[PROD_NAME]
      ,[PROD_QTY]
      ORDER BY [TXN_ID]) AS rn
      FROM transaction_data_copy
)
      DELETE FROM cte
      WHERE rn > 1;

--- 5. Confirm the deleted data

      WITH cte AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY 
        [DATE]
      ,[STORE_NBR]
      ,[LYLTY_CARD_NBR]
      ,[TXN_ID]
      ,[PROD_NBR]
      ,[PROD_NAME]
      ,[PROD_QTY]
      ORDER BY [TXN_ID]) AS rn
      FROM transaction_data_copy
)
      SELECT * FROM cte
      WHERE rn > 1;


--- 6. Check for outliers.

SELECT *
      FROM transaction_data_copy
      ORDER BY PROD_QTY DESC;	

--- 7. Delete the outliers

DELETE
      FROM transaction_data_copy
	  WHERE PROD_NBR = 4
      ORDER BY PROD_QTY DESC;

--- 8. Confirm the deletion.
      SELECT *
      FROM transaction_data_copy
      WHERE PROD_NBR = 4 AND PROD_QTY = 200

--- 9. Add a UNIT_COST Column
      ALTER TABLE transaction_data_copy
      ADD UNIT_COST DECIMAL(10,2);

--- 10. Confirm the addition

       SELECT *
      FROM transaction_data_copy; 

--- 11. Update the table with the UNIT_COST calculation. 
      
      UPDATE transaction_data_copy
      SET UNIT_COST = TOT_SALES/NULLIF(PROD_QTY,0)
      WHERE UNIT_COST = PROD_QTY/NULLIF(TOT_SALES,0);

--- 12. Confirm the update

	  SELECT *
      FROM transaction_data_copy; 

--- 13. Change the datatype of the TOT_SALES column to decimal (proper for money)

     ALTER TABLE transaction_data_copy
     ALTER COLUMN TOT_SALES DECIMAL(10,1);

--- 14.  Standardize the PROD_NAME column

	SELECT PROD_NAME FROM transaction_data_copy
GROUP BY PROD_NAME
ORDER BY PROD_NAME;
  
UPDATE transaction_data_copy
SET PROD_NAME = REPLACE(PROD_NAME,'Dorito','Doritos')
WHERE PROD_NAME LIKE 'Dorito%';

UPDATE transaction_data_copy
SET PROD_NAME = REPLACE(PROD_NAME,'GrnWves','Grain Waves')
WHERE PROD_NAME LIKE 'GrnWves%';

UPDATE transaction_data_copy
SET PROD_NAME = REPLACE(PROD_NAME,'Infzns','Infuzions')
WHERE PROD_NAME LIKE 'Infzns%';

UPDATE transaction_data_copy
SET PROD_NAME = REPLACE(PROD_NAME,'NCC','Natural Chip Co')
WHERE PROD_NAME LIKE 'NCC%';

UPDATE transaction_data_copy
SET PROD_NAME = 
CASE 
	WHEN PROD_NAME LIKE 'Natural Chip Co Co%' THEN REPLACE(PROD_NAME,'Natural Chip Co Co','Natural Chip Co')
	WHEN PROD_NAME LIKE 'Natural Chip CoCo%' THEN REPLACE(PROD_NAME,'Natural Chip CoCo','Natural Chip Co')
	ELSE PROD_NAME
END;

UPDATE transaction_data_copy
SET PROD_NAME = REPLACE(PROD_NAME,'RRD','Red Rock Deli')
WHERE PROD_NAME LIKE 'RRD%';

UPDATE transaction_data_copy
SET PROD_NAME = REPLACE(PROD_NAME,'Smithss','Smiths')
WHERE PROD_NAME LIKE 'Smithss%';

UPDATE transaction_data_copy
SET PROD_NAME = REPLACE(PROD_NAME,'Snbts','Sunbites')
WHERE PROD_NAME LIKE 'Snbts%';

UPDATE transaction_data_copy
SET PROD_NAME = REPLACE(PROD_NAME,'WW','Woolworths')
WHERE PROD_NAME LIKE 'WW%';

--15. Delete Salsa Products from the list.

	DELETE 
		FROM transaction_data_copy
		WHERE PROD_NAME LIKE '%Salsa%'

--- 16. See the impact of each brand in the market

	SELECT LEFT([PROD_NAME], CHARINDEX(' ', [PROD_NAME] + ' ')-1) AS BRAND,
	  	   SUM(PROD_QTY) AS TOT_QTY,
	       SUM(TOT_SALES) AS AGG_SALES
    FROM transaction_data_copy
    GROUP BY LEFT([PROD_NAME], CHARINDEX(' ', [PROD_NAME] + ' ')-1);

--- 17. Group the PROD_NAME and extract the Weight(pack size) into a new column with TOT_QTY and AGG_SALES into a new table

	WITH cte AS (
    SELECT PROD_NAME, SUM(PROD_QTY) AS TOT_QTY, SUM(TOT_SALES) AS AGG_SALES
    FROM transaction_data_copy
    GROUP BY PROD_NAME
)
SELECT 
    PROD_NAME,
        SUBSTRING(
        PROD_NAME, 
        PATINDEX('%[0-9]%', PROD_NAME), -- Start at the first digit
        (LEN(PROD_NAME) - CHARINDEX(' ', REVERSE(PROD_NAME)) + 1) -- End at the last character before the space
    ) AS RAW_WEIGHT_CLEANED,
    TOT_QTY,
    AGG_SALES
INTO brand_weight
FROM cte
WHERE PROD_NAME LIKE '%[0-9]%[gG]%';

--- 18. clean the new table by replacing 'G' with 'g' and others

    SELECT * FROM brand_weight

	UPDATE brand_weight
	SET RAW_WEIGHT_CLEANED = REPLACE(RAW_WEIGHT_CLEANED, 'G', 'g')
	WHERE RAW_WEIGHT_CLEANED LIKE '%G';

	UPDATE brand_weight
	SET RAW_WEIGHT_CLEANED = REPLACE(RAW_WEIGHT_CLEANED, '135g Swt Pot Sea Salt', '135g')
	WHERE RAW_WEIGHT_CLEANED LIKE '135g Swt Pot Sea Salt';

--- 19. Group the data based on pack size 

	SELECT RAW_WEIGHT_CLEANED,
	   SUM(TOT_QTY) AS TOT_QTY,
	   SUM(AGG_SALES) AS TOT_QTY
	FROM brand_weight
	GROUP BY RAW_WEIGHT_CLEANED	


--- 20. The Stores with the highest quantity sales (Best Performing Stores)

SELECT STORE_NBR,
	   SUM(PROD_QTY) AS TOT_QTY,
	   SUM(TOT_SALES) AS AGG_SALES
FROM transaction_data_copy
GROUP BY STORE_NBR
ORDER BY TOT_QTY DESC;

---21. The best performing product

SELECT PROD_NAME,
	   SUM(PROD_QTY) AS TOT_QTY,
	   SUM(TOT_SALES) AS AGG_SALES
FROM transaction_data_copy
GROUP BY PROD_NAME
ORDER BY TOT_QTY DESC;

--- 21 The most loyal customers

SELECT LYLTY_CARD_NBR,
	   SUM(PROD_QTY) AS TOT_QTY,
	   SUM(TOT_SALES) AS AGG_SALES
FROM transaction_data_copy
GROUP BY LYLTY_CARD_NBR
ORDER BY TOT_QTY DESC;

--- 22. Best Performing Months

SELECT DATENAME(MONTH, [DATE]) AS [MONTH],
	   SUM(PROD_QTY) AS TOT_QTY,
	   SUM(TOT_SALES) AS AGG_SALES,
	   AVG(TOT_SALES) AS AVG_SALES
FROM transaction_data_copy
GROUP BY DATENAME(MONTH, [DATE]),
		MONTH([DATE])
ORDER BY MONTH([DATE]);

---23. Best Performing days in December

SELECT 
		[DATE],
	   SUM(PROD_QTY) AS TOT_QTY,
	   SUM(TOT_SALES) AS AGG_SALES,
	   AVG(TOT_SALES) AS AVG_SALES
FROM transaction_data_copy
WHERE MONTH([DATE]) = 12
GROUP BY [DATE]
ORDER BY [DATE]

--- 24. Best performing days of the week
SELECT 
    DATENAME(WEEKDAY, [DATE]) AS [DAY],
    DATEPART(WEEKDAY, [DATE]) AS DayNum,
    SUM(PROD_QTY) AS TOT_QTY,
    SUM(TOT_SALES) AS AGG_SALES,
    AVG(TOT_SALES) AS AVG_SALES
FROM transaction_data_copy
GROUP BY 
    DATENAME(WEEKDAY, [DATE]),
    DATEPART(WEEKDAY, [DATE])
ORDER BY 
    DayNum;

--25. Number of loyal customers

SELECT COUNT(DISTINCT LYLTY_CARD_NBR) AS loyalty_count FROM transaction_data_copy;

--- 26. Join transaction data with customer behaviour data. send into a new table joined_data

SELECT 
    t.[DATE],
    t.STORE_NBR,
    T.TXN_ID,
    t.LYLTY_CARD_NBR,  
    t.PROD_NAME,
    t.PROD_QTY,
    t.TOT_SALES,
    t.UNIT_COST,
    q.PREMIUM_CUSTOMER,
    q.LIFESTAGE
INTO join_data
FROM transaction_data_copy t
JOIN QVI_purchase_behaviour q
    ON t.LYLTY_CARD_NBR = q.LYLTY_CARD_NBR;

--- 27. The behaviour and stages of loyal customers

SELECT LYLTY_CARD_NBR,
	   SUM(PROD_QTY) AS TOT_QTY,
	   SUM(TOT_SALES) AS AGG_SALES,
	   COUNT(LYLTY_CARD_NBR) AS TXN_COUNT,
	   LIFESTAGE,
	   PREMIUM_CUSTOMER
FROM join_data
GROUP BY LYLTY_CARD_NBR,LIFESTAGE,PREMIUM_CUSTOMER
ORDER BY TOT_QTY DESC

--- 28. Distribution of iifestage

  SELECT LIFESTAGE,
		COUNT(LIFESTAGE) AS [COUNT],
		SUM(PROD_QTY) AS TOT_QTY,
SUM(TOT_SALES) AS AGG_SALES
 FROM join_data
GROUP BY LIFESTAGE
ORDER BY [COUNT] DESC;

--- 29. Distribution of PREMIUM_CUSTOMERS
SELECT PREMIUM_CUSTOMER,
	   COUNT(PREMIUM_CUSTOMER) AS [COUNT],
		SUM(PROD_QTY) AS TOT_QTY,
		SUM(TOT_SALES) AS AGG_SALES
 FROM join_data
GROUP BY PREMIUM_CUSTOMER
ORDER BY [COUNT] DESC;

--- 29 joint distribution

SELECT LIFESTAGE,
		PREMIUM_CUSTOMER,
		COUNT(LIFESTAGE) AS [COUNT],
		SUM(PROD_QTY) AS TOT_QTY,
		SUM(TOT_SALES) AS AGG_SALES
 FROM join_data
GROUP BY LIFESTAGE, PREMIUM_CUSTOMER
ORDER BY [COUNT] DESC;

--- FOCUS ON OLDER FAMILIES AND BUDGET SEGMENTS.

--- 30. Create a table for the older family and budget segments

SELECT *
INTO old_bud
FROM join_data
WHERE LIFESTAGE = 'OLDER FAMILIES' AND PREMIUM_CUSTOMER = 'Budget'

--- 30. Confirm the table is formed and check for any null values.

SELECT * FROM old_bud;

--- 31. Preferred stores by the segments

SELECT CONCAT('STORE ',STORE_NBR) AS STORE_NBR,
	   SUM(PROD_QTY) AS TOT_QTY,
	   SUM(TOT_SALES) AS AGG_SALES
FROM old_bud
GROUP BY STORE_NBR;

--- 32. Most loyal customer of the segment

SELECT LYLTY_CARD_NBR,
	   COUNT(LYLTY_CARD_NBR) as [TXN_COUNT],
	   SUM(PROD_QTY) AS TOT_QTY,
	   SUM(TOT_SALES) AS AGG_SALES
FROM old_bud
GROUP BY LYLTY_CARD_NBR
ORDER BY [TXN_COUNT] DESC;

--- 33. Months purchase pattern for the segment

SELECT DATENAME(MONTH,[DATE]) AS [DATE],
	   COUNT(LYLTY_CARD_NBR) as [TXN_COUNT],
	   SUM(PROD_QTY) AS TOT_QTY,
	   SUM(TOT_SALES) AS AGG_SALES
FROM old_bud
GROUP BY DATENAME(MONTH,[DATE]),MONTH([DATE])
ORDER BY MONTH([DATE]);

--- 34. Day of purchase for the segment

SELECT DATENAME(WEEKDAY,[DATE]) AS [DAY],
	   DATEPART(WEEKDAY,[DATE]) AS [DATE_PART],
	   COUNT(LYLTY_CARD_NBR) as [TXN_COUNT],
	   SUM(PROD_QTY) AS TOT_QTY,
	   SUM(TOT_SALES) AS AGG_SALES
FROM old_bud
GROUP BY DATENAME(WEEKDAY,[DATE]),DATEPART(WEEKDAY,[DATE])
ORDER BY DATEPART(WEEKDAY,[DATE]);

--- 35. Most product purchased by segment


SELECT PROD_NAME,
	   COUNT(LYLTY_CARD_NBR) as [TXN_COUNT],
	   SUM(PROD_QTY) AS TOT_QTY,
	   SUM(TOT_SALES) AS AGG_SALES
FROM old_bud
GROUP BY PROD_NAME
ORDER BY [TXN_COUNT] DESC;

--- 36. brand preference of the segment. 

SELECT LEFT([PROD_NAME],CHARINDEX(' ',[PROD_NAME])-1) AS BRAND,
	   COUNT(LYLTY_CARD_NBR) as [TXN_COUNT],
	   SUM(PROD_QTY) AS TOT_QTY,
	   SUM(TOT_SALES) AS AGG_SALES
FROM old_bud
GROUP BY PROD_NAME
ORDER BY [TXN_COUNT] DESC;








 







