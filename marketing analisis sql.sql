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

SELECT * 
FROM customer_journey
ORDER BY journeyid ASC;

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

--------------------------------------------------------------------
SELECT * FROM customer_review

-- Query to remove extra spaces in reviewtext 
UPDATE customer_review
SET ReviewText = REGEXP_REPLACE(ReviewText, '\s+', ' ', 'g')
WHERE ReviewText IS NOT NULL;

-------------------------------------------------------------------
SELECT * FROM customers;
SELECT * FROM geography
	
-- JOIN customers with geography to enrich customer data with geographic information

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

SELECT * FROM engagement