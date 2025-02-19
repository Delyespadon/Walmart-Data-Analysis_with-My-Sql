# Walmart Data Analysis with my sql 

## Project Overview

This project is an end-to-end data analysis solution designed to extract critical business insights from Walmart sales data. We utilize  MySQL for advanced querying, and structured problem-solving techniques to solve key business questions. .

---

## Project Steps

### 1. Set Up the Environment
   - **Tools Used**: SQL (MySQL and PostgreSQL)
   - **Goal**: Create a structured workspace within VS Code and organize project folders for smooth development and data handling.

### 2. Download Walmart Sales Data
   - **Data Source**: Use the Kaggle API to download the Walmart sales datasets from Kaggle.
   - **Dataset Link**: [Walmart Sales Dataset](https://www.kaggle.com/najir0123/walmart-10k-sales-datasets)
   - **Storage**: Save the data in the `data/` folder for easy reference and access.


### 3. Explore the Data
   - **Goal**: Conduct an initial data exploration to understand data distribution, check column names, types, and identify potential issues.
  

### 4. Data Cleaning
   - **Remove Duplicates**: Identify and remove duplicate entries to avoid skewed results.
   - **Handle Missing Values**: Drop rows or columns with missing values if they are insignificant; fill values where essential.
   - **Validation**: Check for any remaining inconsistencies and verify the cleaned data.

### 5. Feature Engineering
   - **Create New Columns**: Calculate the `Total Amount` for each transaction by multiplying `unit_price` by `quantity` and adding this as a new column.
   - **Enhance Dataset**: Adding this calculated field will streamline further SQL analysis and aggregation tasks.

### 6. Load Data into MySQL and PostgreSQL
 **Verification**
 ```sql
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
```

### 7. SQL Analysis: Complex Queries and Business Problem Solving
  ## Business Problems and Solutions


 ### 1.  Analyze Payment Methods and Sales 
 **Question:** What are the different payment methods, and how many transactions and 
items were sold with each method? 
```sql
SELECT 
    payment_method,
    COUNT(payment_method) AS total_transaction,
    SUM(quantity) AS items_sold
FROM
    walmart
GROUP BY 1
ORDER BY 3;
```
**Purpose:** This helps understand customer preferences for payment methods, aiding in 
payment optimization strategies

### 2. Analyze Customer Loyalty by Payment Method
**Question:** How many transactions per customer are recorded for each payment method?
```sql
SELECT 
    payment_method, customer_id, COUNT(*) AS transaction_count
FROM
    sales
GROUP BY payment_method , customer_id
ORDER BY transaction_count DESC;
```
**Purpose:** Understand which payment methods correlate with higher customer loyalty?

  ### 3. Identify the Highest-Rated Category in Each Branch
  **Question:** Which category received the highest average rating in each branch?
```sql
SELECT 
    category,
    ROUND(AVG(rating), 3) AS average_rating_per_category
FROM
    walmart
GROUP BY 1
ORDER BY 2 DESC;
```
**Purpose:** This allows Walmart to recognize and promote popular categories in specific 
branches, enhancing customer satisfaction and branch-specific marketing. 

### 4 Identify Underperforming Categories Across Branches
**Question:** Which categories have the lowest total sales and profit margins?
```sql
SELECT 
    category,
    SUM(unit_price * quantity) AS total_sales,
    AVG(profit_margin) AS avg_profit_margin
FROM
    sales
GROUP BY category
ORDER BY total_sales ASC , avg_profit_margin ASC
LIMIT 5;
```
**Purpose:**  Identify product categories that may need new marketing strategies or promotions
### 5. Determine the Busiest Day for Each Branch
**Question:**  What is the busiest day of the week for each branch based on transaction volume?
```sql
SELECT 
    Branch,
    DAYNAME(date) AS day_of_week,
    COUNT(invoice_id) AS transaction_count
FROM
    walmart
GROUP BY 1 , 2
ORDER BY 1 , 3 DESC;
```
**Purpose:** This insight helps in optimizing staffing and inventory management to 
accommodate peak days. 

### 6 Evaluate Sales Contribution by Time of Year
**Question:** What are the total sales during holidays, weekends, and weekdays?
``` sql
SELECT 
    CASE
        WHEN DAYOFWEEK(date) IN (1 , 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    SUM(unit_price * quantity) AS total_sales
FROM
    sales
GROUP BY day_type;
```
**Purpose:** Determine periods with high and low sales activity for targeted promotions.

### 7 Calculate Total Quantity Sold by Payment Method
**Question:** How many items were sold through each payment method?
```sql
SELECT 
    payment_method, SUM(quantity) AS items_sold
FROM
    walmart
GROUP BY 1
ORDER BY 2;
```
**Purpose:**  This helps Walmart track sales volume by payment type, providing insights 
into customer purchasing habits


### 8. Analyze Sales Shifts Throughout the Day
 **Question:** How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
```sql
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
```
**Purpose:** Understand which payment methods are most profitable

### 9 Analyze Profitability by Payment Method
**Question:** Which payment method yields the highest average profit per transaction?
```sql
SELECT 
    payment_method,
    AVG(unit_price * quantity * profit_margin) AS avg_profit
FROM
    sales
GROUP BY payment_method
ORDER BY avg_profit DESC;
```
### 10 . Analyze Category Ratings by City
**Question:** What are the average, minimum, and maximum ratings for each category in each city?
```sql
SELECT 
    city,
    category,
    ROUND(AVG(rating), 3) AS average_rating,
    MIN(rating) AS minimum_rating,
    MAX(rating) AS maximum_rating
FROM
    walmart
GROUP BY 1 , 2;
```
**Purpose:** This data can guide city-level promotions, allowing Walmart to address 
regional preferences and improve customer experiences. 

 ### 11 Assess Customer Satisfaction by Shift
**Question:** What is the average customer rating for morning, afternoon, and evening shifts?
```sql
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
```
**Purpose:** Helps evaluate if staff performance or peak-hour issues affect customer satisfaction.

### 12. Calculate Total Profit by Category
**Question:** What is the total profit for each category, ranked from highest to lowest?
```sql
SELECT 
    category,
    ROUND(SUM((unit_price * profit_margin * quantity)),
            3) AS profit_per_category
FROM
    walmart
GROUP BY 1
ORDER BY 2 DESC;
```
**Purpose:** Identifying high-profit categories helps focus efforts on expanding these  products or managing pricing strategies effectively. 

### Track Repeat Purchases by Category 
**13 Question: Which product categories have the highest rate of repeat purchases?**
```sql
SELECT category, COUNT(DISTINCT customer_id) AS unique_customers, COUNT(*) AS total_purchases
FROM sales
GROUP BY category
ORDER BY total_purchases DESC;
```
**Purpose:** Helps Walmart identify customer favorites and drive loyalty programs

### 14 Compare Sales-to-Profit Ratios Across Branches
**Question:** What is the sales-to-profit ratio for each branch?
```sql
SELECT 
    branch,
    SUM(unit_price * quantity) AS total_sales,
    SUM(unit_price * quantity * profit_margin) AS total_profit,
    (SUM(unit_price * quantity * profit_margin) / SUM(unit_price * quantity)) * 100 AS sales_to_profit_ratio
FROM
    sales
GROUP BY branch
ORDER BY sales_to_profit_ratio DESC;
```
**Purpose:** This information aids in understanding branch-specific payment preferences, potentially allowing branches to streamline their payment processing systems. 

### 15. Determine the Most Common Payment Method per Branch
**Question:** What is the most frequently used payment method in each branch?  
```sql
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
```
**Purpose:** Highlights branches that generate high sales but low profitability, indicating possible cost issues.

### 16. Analyze Sales Shifts Throughout the Day
**Question:** How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
```
sql
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
```
**Purpose:** This insight helps in managing staff shifts and stock replenishment schedules, 
especially during high-sales periods. 

### 17 Analyze Customer Preferences by City
**Question:** What are the top-selling categories in each city?
```sql
SELECT 
    city, category, SUM(unit_price * quantity) AS total_sales
FROM
    sales
GROUP BY city , category
ORDER BY city , total_sales DESC;
```
**Purpose:** Helps Walmart tailor city-specific inventory and marketing strategies.
### 18 : Identify the 5 branches with the highest revenue decrease ratio from last year to current year (e.g., 2022 to 2023)
```sql
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
```
**Purpose:** Detecting branches with declining revenue is crucial for understanding 
possible local issues and creating strategies to boost sales or mitigate losses.


### Findings:
### Payment Method Preferences
**Credit Card:** Most used (4,256 transactions, 9,567 items sold).
**Ewallet:** Second most used (3,881 transactions, 8,932 items sold).
**Cash:** Least preferred (1,832 transactions, 4,984 items sold).
### Busiest Sales Days
-Tuesday is the busiest day (1,473 transactions), followed closely by Sunday (1,468 transactions).
- Monday has the lowest sales activity (1,373 transactions).
### Underperforming Categories (Low Sales & Profit Margins)
**Health and Beauty:** Lowest sales (854 units sold) but decent margin (40%).
**Sports and Travel:** Low sales (920 units sold) and lowest profit margin (38%)
### Sales Distribution by Shift
- Morning is the most active shift (9,969 transactions).
- Afternoon & Evening transactions are missing from the dataset (needs verification).

### Recommendations
1)  Prioritize Credit Card & Ewallet transactions through discounts or cashback.
2)  Strengthen Tuesday & Sunday workforce to handle peak demand.
3)  Expand Food and Beverages marketing in high-rated branches.
4)  Improve Sports & Travel sales with targeted promotions.
5)  Investigate Afternoon and Evening sales drop to uncover missing data or trends.


   - **Documentation**: Keep clear notes of each query's objective, approach, and results.

### 8. Project Publishing and Documentation
   - **Documentation**: Maintain well-structu
   - red documentation of the entire process in Markdown or a mySQL file
   - **Project Publishing**: Publish the completed project on GitHub or any other version control platform, including:
     - The `README.md` file (this document).
     - Jupyter Notebooks (if applicable).
     - SQL query scripts.
     - Data files (if possible) or steps to access them.

---

## Requirements


- **SQL Databases**: MySQL, PostgreSQL

- **Kaggle API Key** (for data downloading)

## Getting Started

   ```
1. Set up your Kaggle API, download the data, and follow the steps to load and analyze.

---

## Project Structure

```plaintext
|-- data/                     # Raw data and transformed data
|-- sql_queries/              # SQL scripts for analysis and queries
|-- README.md                 # Project documentation
|-- main.py                   # Main script for loading, cleaning, and processing data
```
---

## Results and Insights

This section will include your analysis findings:
- **Sales Insights**: Key categories, branches with highest sales, and preferred payment methods.
- **Profitability**: Insights into the most profitable product categories and locations.
- **Customer Behavior**: Trends in ratings, payment preferences, and peak shopping hours.

## Future Enhancements

Possible extensions to this project:
- Integration with a dashboard tool (e.g., Power BI or Tableau) for interactive visualization.
- Additional data sources to enhance analysis depth.
- Automation of the data pipeline for real-time data ingestion and analysis.

---

## Acknowledgments

- **Data Source**: Kaggle’s Walmart Sales Dataset
- **Inspiration**: Walmart’s business case studies on sales and supply chain optimization.

---
