USE [FinalProject]
GO

/****** Object:  StoredProcedure [dbo].[Update_Customer_Item]    Script Date: 1/25/2024 10:59:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[Update_Customer_Item] AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    -- Initialize variables
    DECLARE @CurrentDate DATETIME = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0)
    DELETE CustomerItem
    -- Create a temporary table to store the top 5 items for each customer
    CREATE TABLE #Customer_top5_Items
    (
        CustomerId INT,
        ItemCode INT,
    )
    -- Create a temporary table to hold the ranked selling items
    CREATE TABLE #Ranked_Sales_Item 
    (
        ItemCode INT,
        Item_Rank INT
    )

    -- Create a temporary table to hold the valid customers
    CREATE TABLE #Valid_Customers 
    (
        Id INT,
    )

    -- Get the customers with valid national code
    INSERT INTO #Valid_Customers (Id)
    SELECT Id
    FROM Customer
    WHERE dbo.is_valid_iranian_national_code(NationalCode) = 1;

    -- Populate the temporary table with the top 5 items for each customer
    WITH Ranked_Customer_Items AS(
         SELECT CustomerId, ItemCode,
            RANK() OVER (PARTITION BY CustomerId ORDER BY SUM(Quantity) DESC) AS top_items
        FROM Sales
        WHERE TransactionTime < @CurrentDate
        GROUP BY CustomerId, ItemCode
        )
    INSERT INTO #Customer_top5_Items (CustomerId, ItemCode)
    SELECT CustomerId, ItemCode
    FROM Ranked_Customer_Items
    WHERE top_items <= 5 AND
          CustomerID IN (SELECT Id FROM #Valid_Customers)





    -- Loop until all customers are assigned an item
    WHILE EXISTS (SELECT 1 FROM #Valid_Customers WHERE Id NOT IN (SELECT CustomerId FROM CustomerItem)) 
    BEGIN

        DELETE #Ranked_Sales_Item
        DECLARE @Loop_Rank INT = 1

        -- Get the top selling items

        INSERT INTO #Ranked_Sales_Item (ItemCode, Item_Rank)
        SELECT ItemCode, 
            ROW_NUMBER() OVER (ORDER BY SUM(Quantity) DESC) AS Item_Rank
        FROM Sales
        WHERE TransactionTime < @CurrentDate AND
              CustomerID NOT IN (SELECT CustomerId FROM CustomerItem) AND
              CustomerID  IN (SELECT Id FROM #Valid_Customers)
        GROUP BY ItemCode

        

        WHILE NOT EXISTS (
            SELECT 1
            FROM #Customer_top5_Items A
            INNER JOIN  #Ranked_Sales_Item B ON A.ItemCode=B.ItemCode
            WHERE B.Item_Rank=@Loop_Rank  AND
                  A.CustomerId NOT IN (SELECT CustomerId FROM CustomerItem)  
        )
        BEGIN
            SET @Loop_Rank += 1
        END

        INSERT INTO CustomerItem (CustomerId,ItemCode)
        SELECT A.CustomerId,B.ItemCode
        FROM #Customer_top5_Items A
        INNER JOIN  #Ranked_Sales_Item B ON A.ItemCode=B.ItemCode
        WHERE B.Item_Rank=@Loop_Rank  AND
              A.CustomerId NOT IN (SELECT CustomerId FROM CustomerItem) 

    END

    -- Update log table
	INSERT INTO Update_CustomerItem_Log (datetime)
	VALUES (CONVERT(DATETIME, CONVERT(VARCHAR, DATEADD(DAY, -1, GETDATE()), 101) + ' 23:59:59'));

    DROP TABLE #Customer_top5_Items
    DROP TABLE #Valid_Customers
    DROP TABLE #Ranked_Sales_Item
END
GO


