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

      SELECT *
      FROM transaction_data_copy
      WHERE PROD_NBR = 4 AND PROD_QTY = 200

      ALTER TABLE transaction_data_copy
      ADD UNIT_COST FLOAT;

       SELECT *
      FROM transaction_data_copy

      
      
       SELECT *
      FROM transaction_data_copy

      
       SELECT *
      FROM QVI_transaction_data;

      UPDATE transaction_data_copy
      SET UNIT_COST = TOT_SALES/NULLIF(PROD_QTY,0)
      WHERE UNIT_COST = PROD_QTY/NULLIF(TOT_SALES,0);      --- 

     ALTER TABLE transaction_data_copy
     ALTER COLUMN TOT_SALES DECIMAL(10,1);       --- change datatype to decimal proper for money

      SELECT *
      FROM transaction_data_copy
      WHERE STORE_NBR = 1

      ALTER TABLE transaction_data_copy
     ALTER COLUMN UNIT_COST DECIMAL(10,1);       --- change datatype for money

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

