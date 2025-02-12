SELECT * FROM customer_journey

--	display duplicate records
WITH DuplicateRecords AS (
    SELECT 
        JourneyID,  
        CustomerID,  
        ProductID,  
        VisitDate,  
        Stage,  
        Action,  
        Duration,  
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action  
            ORDER BY JourneyID  
        ) AS row_num  
    FROM 
        customer_journey  
)
SELECT * 
FROM DuplicateRecords
WHERE row_num > 1  --This shows duplicate rows
ORDER BY JourneyID;

-- Delete duplicate copies
WITH DuplicateRecords AS (
    SELECT 
        ctid,  -- `ctid` is the internal row identifier in PostgreSQL.
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action  
            ORDER BY JourneyID  
        ) AS row_num  
    FROM 
        customer_journey  
)
DELETE FROM customer_journey
WHERE ctid IN (
    SELECT ctid
    FROM DuplicateRecords
    WHERE row_num > 1  -- This eliminates duplicate rows, leaving the first one
);

--The average of the Duration column and then update the null values
WITH avg_duration AS (
    SELECT AVG(Duration) AS avg_value
    FROM customer_journey
    WHERE Duration IS NOT NULL  -- Excludes null values when calculating the average
)
UPDATE customer_journey
SET Duration = (SELECT avg_value FROM avg_duration)
WHERE Duration IS NULL;  -- Only updates rows where Duration is NULL.

SELECT * 
FROM customer_journey
ORDER BY journeyid ASC;

COPY (SELECT * FROM customer_journey --Exports the data from the customer_journey table to a CSV file
    ORDER BY journeyid ASC -- Data is sorted by the 'journeyid' field in ascending order before being exported.
) TO '\customer_journey.csv' WITH (FORMAT CSV, HEADER);  -- add file path

--------------------------------------------------------------------
SELECT * FROM customer_review

-- Query to remove extra spaces in reviewtext 
UPDATE customer_review
SET ReviewText = REGEXP_REPLACE(ReviewText, '\s+', ' ', 'g')
WHERE ReviewText IS NOT NULL;
-- This table is not exported to CSV because it will be processed and analyzed in Python.

-------------------------------------------------------------------
SELECT * FROM customers;
SELECT * FROM geography
	
-- Create a new table 'customers_enriched' by joining 'customers' and 'geography' tables
CREATE TABLE customers_enriched AS 
SELECT
	c.customerid,
	c.customername,
	c.email,
	c.gender,
	c.age,
	g.country,
	g.city
FROM customers AS c
LEFT JOIN geography AS g
ON c.geographyid = g.geographyid;

-- The resulting 'customers_enriched' table is then exported to a CSV file, including column headers.
COPY customers_enriched TO '\customers_enriched.csv' WITH (FORMAT csv, HEADER true); -- add file path

------------------------------------------------------------
SELECT * FROM engagement

-- Query to list unique ContentType values
SELECT DISTINCT contenttype
FROM engagement
ORDER BY contenttype;

-- Query to clean and normalize the column ContentType 
UPDATE engagement
SET contenttype = CASE
    WHEN LOWER(contenttype) = 'blog' THEN 'Blog'
    WHEN LOWER(contenttype) = 'newsletter' THEN 'Newsletter'
    WHEN LOWER(contenttype) = 'socialmedia' THEN 'SocialMedia'
    WHEN LOWER(contenttype) = 'video' THEN 'Video'
    ELSE ContentType
END;

--Query to separate Views and Clicks variables
SELECT 
    EngagementID,
    SPLIT_PART(ViewsClicksCombined, '-', 1) AS Views,
    SPLIT_PART(ViewsClicksCombined, '-', 2) AS Clicks
FROM engagement;

ALTER TABLE engagement
ADD COLUMN Views INTEGER,
ADD COLUMN Clicks INTEGER;

UPDATE engagement
SET 
    Views = SPLIT_PART(ViewsClicksCombined, '-', 1)::INTEGER,
    Clicks = SPLIT_PART(ViewsClicksCombined, '-', 2)::INTEGER;

ALTER TABLE engagement
DROP COLUMN ViewsClicksCombined;

-- Export the 'engagement' table to a CSV file
COPY engagement TO '\engagement.csv' WITH (FORMAT csv, HEADER true); --ad file path

---------------------------------------------------------
SELECT * FROM products

--Remove the category column
ALTER TABLE products
DROP COLUMN category;

--  Query to classify prices by 'low', 'medium' and 'high'
SELECT price, 
CASE 
	WHEN price < 50 THEN 'low'
	WHEN price BETWEEN 50 AND 200 THEN 'Medium'
	ELSE 'High'
END AS pricecategory
FROM products;

ALTER TABLE products -- Create new column
ADD COLUMN pricecategory
VARCHAR(10);

UPDATE products 
SET pricecategory = 
CASE 
	WHEN price < 50 THEN 'low'
	WHEN price BETWEEN 50 AND 200 THEN 'Medium'
	ELSE 'High'
END;

-- Export the 'products' table to a CSV file
COPY products TO '\products.csv' WITH (FORMAT csv, HEADER true); --ad file path
