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

		
      SELECT *
      FROM transaction_data_copy
      WHERE STORE_NBR = 1

      

     SELECT *
      FROM transaction_data_copy
      WHERE PROD_NAME LIKE '%Chip%'   

       SELECT *
            INTO chip_data
            FROM transaction_data_copy
        WHERE PROD_NAME LIKE '%Chip%' 

        
        
	INSERT INTO brand_data(brand_id,brand_name)
	VALUES (1,'Cobs Popd'), 
		   (2,'Dontus Corn Chips'),
		   (3,'French Fries'),
		   (4,'Natural Chip'),
		   (5,'Smiths'),
		   (6,'Thins'),
		   (7,'Tostitos'), 
		   (8,'WW');

	DELETE FROM brand_data
	WHERE brand_id IS NULL;

	SELECT DISTINCT * 
	INTO brand_data1
	FROM brand_data;





