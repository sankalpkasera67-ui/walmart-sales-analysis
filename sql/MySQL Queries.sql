-- Walmart Project Queries - MySQL

SELECT * FROM walmart;

-- Count total records
SELECT COUNT(*) FROM walmart;

-- Count payment methods and number of transactions by payment method
SELECT
    payment_method,
    COUNT(*) AS no_payments
FROM walmart
GROUP BY payment_method;

-- Count distinct branches
SELECT COUNT(DISTINCT branch) FROM walmart;

-- Find the minimum quantity sold
SELECT MIN(quantity) FROM walmart;

-- Business Problem Q1:
-- Find different payment methods, number of transactions, and quantity sold by payment method
SELECT
    payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;

-- Q2: Identify the highest-rated category in each branch
SELECT
    branch,
    category,
    avg_rating
FROM (
    SELECT
        branch,
        category,
        AVG(rating) AS avg_rating,
        RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS rnk
    FROM walmart
    GROUP BY branch, category
) ranked
WHERE rnk = 1;

-- Q3: Identify the busiest day for each branch
SELECT
    branch,
    day_name,
    no_transactions
FROM (
    SELECT
        branch,
        DAYNAME(STR_TO_DATE(date,'%d/%m/%Y')) AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart
    GROUP BY branch, day_name
) ranked
WHERE rnk = 1;

-- Q4: Calculate total quantity sold by payment method
SELECT
    payment_method,
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;

-- Q5: Average, minimum and maximum rating of categories in each city
SELECT
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating) AS avg_rating
FROM walmart
GROUP BY city, category;

-- Q6: Calculate total profit for each category
SELECT
    category,
    ROUND(
        SUM(
            CAST(REPLACE(unit_price,'$','') AS DECIMAL(10,2))
            * quantity
            * profit_margin
        ),
        2
    ) AS total_profit
FROM walmart
GROUP BY category
ORDER BY total_profit DESC;

-- Q7: Most common payment method for each branch
WITH cte AS (
    SELECT
        branch,
        payment_method,
        COUNT(*) AS total_trans,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart
    GROUP BY branch, payment_method
)
SELECT
    branch,
    payment_method AS preferred_payment_method
FROM cte
WHERE rnk = 1;

-- Q8: Categorize sales into Morning, Afternoon and Evening shifts
SELECT
    branch,
    CASE
        WHEN HOUR(TIME(time)) < 12 THEN 'Morning'
        WHEN HOUR(TIME(time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS num_invoices
FROM walmart
GROUP BY branch, shift
ORDER BY branch, num_invoices DESC;

-- Q9: Top 5 branches with highest revenue decrease ratio
WITH revenue_2022 AS (
    SELECT
        branch,
        SUM(
            CAST(REPLACE(unit_price,'$','') AS DECIMAL(10,2))
            * quantity
        ) AS revenue
    FROM walmart
    WHERE YEAR(STR_TO_DATE(date,'%d/%m/%Y')) = 2022
    GROUP BY branch
),

revenue_2023 AS (
    SELECT
        branch,
        SUM(
            CAST(REPLACE(unit_price,'$','') AS DECIMAL(10,2))
            * quantity
        ) AS revenue
    FROM walmart
    WHERE YEAR(STR_TO_DATE(date,'%d/%m/%Y')) = 2023
    GROUP BY branch
)

SELECT
    r2022.branch,
    ROUND(r2022.revenue,2) AS last_year_revenue,
    ROUND(r2023.revenue,2) AS current_year_revenue,
    ROUND(
        ((r2022.revenue-r2023.revenue)/r2022.revenue)*100,
        2
    ) AS revenue_decrease_ratio
FROM revenue_2022 r2022
JOIN revenue_2023 r2023
ON r2022.branch = r2023.branch
WHERE r2022.revenue > r2023.revenue
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;

SELECT DISTINCT YEAR(STR_TO_DATE(date,'%d/%m/%Y')) AS year
FROM walmart;
WITH revenue_by_year AS (
    SELECT
        YEAR(STR_TO_DATE(date,'%d/%m/%Y')) AS sales_year,
        branch,
        SUM(
            CAST(REPLACE(unit_price,'$','') AS DECIMAL(10,2)) * quantity
        ) AS revenue
    FROM walmart
    GROUP BY sales_year, branch
),

latest_year AS (
    SELECT MAX(sales_year) AS current_year
    FROM revenue_by_year
)

SELECT
    prev.branch,
    ROUND(prev.revenue,2) AS last_year_revenue,
    ROUND(curr.revenue,2) AS current_year_revenue,
    ROUND(
        ((prev.revenue-curr.revenue)/prev.revenue)*100,
        2
    ) AS revenue_decrease_ratio
FROM revenue_by_year prev
JOIN revenue_by_year curr
    ON prev.branch = curr.branch
JOIN latest_year ly
WHERE prev.sales_year = ly.current_year - 1
AND curr.sales_year = ly.current_year
AND prev.revenue > curr.revenue
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;