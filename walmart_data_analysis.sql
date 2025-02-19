-- creation of the database 
Create database walmartdb;

-- creation of the table 
CREATE TABLE walmart (
    invoice_id INT,
    Branch VARCHAR(50),
    City VARCHAR(50),
    category VARCHAR(50),
    unit_price FLOAT,
    quantity FLOAT,
    date VARCHAR(50),
    time TIME,
    payment_method VARCHAR(50),
    rating FLOAT,
    profit_margin FLOAT,
    Total_quantity FLOAT
);

-- Updating the the table so that the date column is in a date type 
 
UPDATE walmart 
SET 
    date = CASE
        WHEN
            LENGTH(SUBSTRING_INDEX(date, '/', - 1)) = 2
        THEN
            CONCAT(SUBSTRING_INDEX(date, '/', 1),
                    '/',
                    SUBSTRING_INDEX(SUBSTRING_INDEX(date, '/', 2), '/', - 1),
                    '/',
                    CASE
                        WHEN SUBSTRING_INDEX(date, '/', - 1) = '19' THEN '2019'
                        WHEN SUBSTRING_INDEX(date, '/', - 1) = '20' THEN '2020'
                        WHEN SUBSTRING_INDEX(date, '/', - 1) = '21' THEN '2021'
                        WHEN SUBSTRING_INDEX(date, '/', - 1) = '22' THEN '2022'
                        WHEN SUBSTRING_INDEX(date, '/', - 1) = '23' THEN '2023'
                        ELSE SUBSTRING_INDEX(date, '/', - 1)
                    END)
        ELSE date
    END;
UPDATE walmart 
SET 
    date = CASE
        WHEN
            date REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$'
        THEN
            CASE
                WHEN
                    CAST(SUBSTRING_INDEX(date, '/', 1) AS UNSIGNED) <= 12
                        AND CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(date, '/', 2), '/', - 1)
                        AS UNSIGNED) <= 31
                THEN
                    STR_TO_DATE(date, '%m/%d/%Y')
                ELSE STR_TO_DATE(date, '%d/%m/%Y')
            END
    END;
    
UPDATE walmart 
SET 
    date = CASE
        WHEN date LIKE '____-__-__' THEN date
        WHEN
            date LIKE '__/__/____'
        THEN
            CASE
                WHEN CAST(SUBSTRING_INDEX(date, '/', 1) AS UNSIGNED) <= 12 THEN STR_TO_DATE(date, '%m/%d/%Y')
                ELSE STR_TO_DATE(date, '%d/%m/%Y')
            END
    END;
ALTER TABLE walmart MODIFY COLUMN date DATE;

-- Solution to bussiness problems usefull for data analysis 

SELECT 
    payment_method,
    COUNT(payment_method) AS total_transaction,
    SUM(quantity) AS items_sold
FROM
    walmart
GROUP BY 1
ORDER BY 3;

-- 2 Analyze Customer Loyalty by Payment Method
-- How many transactions per customer are recorded for each payment method?

SELECT 
    payment_method, customer_id, COUNT(*) AS transaction_count
FROM
    sales
GROUP BY payment_method , customer_id
ORDER BY transaction_count DESC;

-- 3. Identify the Highest-Rated Category in Each Branch
-- Question: Which category received the highest average rating in each branch?
SELECT 
    category,
    ROUND(AVG(rating), 3) AS average_rating_per_category
FROM
    walmart
GROUP BY 1
ORDER BY 2 DESC;
-- 4 Identify Underperforming Categories Across Branches
SELECT 
    category,
    SUM(unit_price * quantity) AS total_sales,
    AVG(profit_margin) AS avg_profit_margin
FROM
    sales
GROUP BY category
ORDER BY total_sales ASC , avg_profit_margin ASC
LIMIT 5;

-- 5. Determine the Busiest Day for Each Branch
-- Question: What is the busiest day of the week for each branch based on transaction volume?
SELECT 
    Branch,
    DAYNAME(date) AS day_of_week,
    COUNT(invoice_id) AS transaction_count
FROM
    walmart
GROUP BY 1 , 2
ORDER BY 1 , 3 DESC;
-- 6 Evaluate Sales Contribution by Time of Year
-- Question: What are the total sales during holidays, weekends, and weekdays?
SELECT 
    CASE
        WHEN DAYOFWEEK(date) IN (1 , 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    SUM(unit_price * quantity) AS total_sales
FROM
    sales
GROUP BY day_type;

-- 7 Calculate Total Quantity Sold by Payment Method
-- Question: How many items were sold through each payment method?

SELECT 
    payment_method, SUM(quantity) AS items_sold
FROM
    walmart
GROUP BY 1
ORDER BY 2;


-- 8. Analyze Sales Shifts Throughout the Day
--  Question: How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
SELECT 
    branch,
    CASE
        WHEN HOUR(time) < 12 THEN 'Morning'
        WHEN HOUR(time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shifts,
    COUNT(*) AS Transaction_per_shift
FROM
    walmart
GROUP BY 1 , 2
ORDER BY 1 , 3;
-- 9 Analyze Profitability by Payment Method
-- Question: Which payment method yields the highest average profit per transaction?
SELECT 
    payment_method,
    AVG(unit_price * quantity * profit_margin) AS avg_profit
FROM
    sales
GROUP BY payment_method
ORDER BY avg_profit DESC;

-- 10 . Analyze Category Ratings by City
-- Question: What are the average, minimum, and maximum ratings for each category in each city?
SELECT 
    city,
    category,
    ROUND(AVG(rating), 3) AS average_rating,
    MIN(rating) AS minimum_rating,
    MAX(rating) AS maximum_rating
FROM
    walmart
GROUP BY 1 , 2;
 
 -- 11 Assess Customer Satisfaction by Shift
-- Question: What is the average customer rating for morning, afternoon, and evening shifts?

SELECT 
    CASE
        WHEN HOUR(time) BETWEEN 6 AND 12 THEN 'Morning'
        WHEN HOUR(time) BETWEEN 13 AND 18 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    AVG(rating) AS avg_rating
FROM
    sales
GROUP BY shift;

-- 12. Calculate Total Profit by Category
--  Question: What is the total profit for each category, ranked from highest to lowest?
SELECT 
    category,
    ROUND(SUM((unit_price * profit_margin * quantity)),
            3) AS profit_per_category
FROM
    walmart
GROUP BY 1
ORDER BY 2 DESC;

-- 12 Question: Which product categories have the highest rate of repeat purchases?

SELECT category, COUNT(DISTINCT customer_id) AS unique_customers, COUNT(*) AS total_purchases
FROM sales
GROUP BY category
ORDER BY total_purchases DESC;

-- 13 Compare Sales-to-Profit Ratios Across Branches
-- Question: What is the sales-to-profit ratio for each branch?

SELECT 
    branch,
    SUM(unit_price * quantity) AS total_sales,
    SUM(unit_price * quantity * profit_margin) AS total_profit,
    (SUM(unit_price * quantity * profit_margin) / SUM(unit_price * quantity)) * 100 AS sales_to_profit_ratio
FROM
    sales
GROUP BY branch
ORDER BY sales_to_profit_ratio DESC;

-- 14. Determine the Most Common Payment Method per Branch
-- Question: What is the most frequently used payment method in each branch?  

WITH CTE AS (
    SELECT 
        branch, 
        payment_method, 
        COUNT(*) AS payment_count,  
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rk 
    FROM walmart
    GROUP BY branch, payment_method
)
SELECT branch, payment_method
FROM CTE
WHERE rk = 1;-- Select the most frequent payment method(s) per branch

SELECT 
    CASE
        WHEN is_promotion = 1 THEN 'Promotion'
        ELSE 'Non-Promotion'
    END AS period_type,
    SUM(unit_price * quantity) AS total_sales
FROM
    sales
GROUP BY period_type;

-- 16. Analyze Sales Shifts Throughout the Day
-- Question: How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
SELECT 
    branch,
    CASE
        WHEN time IS NULL THEN 'Unknown'
        WHEN HOUR(TIME(time)) < 12 THEN 'Morning'
        WHEN HOUR(TIME(time)) = 12 THEN 'Morning'
        WHEN HOUR(TIME(time)) < 18 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS invoice_count
FROM
    walmart
GROUP BY branch , shift
ORDER BY branch , invoice_count DESC;

-- 17 Analyze Customer Preferences by City
-- Question: What are the top-selling categories in each city?

SELECT 
    city, category, SUM(unit_price * quantity) AS total_sales
FROM
    sales
GROUP BY city , category
ORDER BY city , total_sales DESC;

-- 18 : Identify the 5 branches with the highest revenue decrease ratio from last year to current year (e.g., 2022 to 2023)

WITH revenue_2022 AS (
    SELECT
        branch,
        SUM(total) AS revenue_2022
    FROM walmart
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%Y')) = 2022
    GROUP BY branch
),
revenue_2023 AS (
    SELECT
        branch,
        SUM(total) AS revenue_2023
    FROM walmart
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%Y')) = 2023
    GROUP BY branch
)
SELECT
    r2022.branch,
    r2022.revenue_2022,
    COALESCE(r2023.revenue_2023, 0) AS revenue_2023,  -- Handle missing 2023 revenue
    CASE
        WHEN r2022.revenue_2022 IS NULL OR r2022.revenue_2022 = 0 THEN NULL -- Avoid divide by zero
        ELSE ROUND(((r2022.revenue_2022 - COALESCE(r2023.revenue_2023, 0)) / r2022.revenue_2022) * 100, 2)
    END AS revenue_decrease_ratio
FROM revenue_2022 AS r2022
LEFT JOIN revenue_2023 AS r2023 ON r2022.branch = r2023.branch
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;
