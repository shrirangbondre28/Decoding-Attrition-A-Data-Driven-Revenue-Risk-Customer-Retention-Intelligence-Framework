--customers table
CREATE TABLE customers (
             customer_id INT PRIMARY KEY,
			 signup_date DATE,
			 gender VARCHAR(10),
			 age SMALLINT,
			 city VARCHAR(50),
			 acquisition_channel VARCHAR(30),
			 is_active SMALLINT,
			 churn_flag SMALLINT
           );

SELECT * FROM customers
SELECT COUNT(*) FROM customers

--orders table
CREATE TABLE orders(
              order_id INT PRIMARY KEY,
			  customer_id INT REFERENCES customers(customer_id),
			  order_date DATE,
			  order_value NUMERIC(12,2),
			  product_category VARCHAR(30),
			  payment_method VARCHAR(30),
			  order_status VARCHAR(20),
			  discount_used SMALLINT
);

SELECT * FROM orders
SELECT COUNT(*) FROM orders

--activity table
CREATE TABLE activity(
             activity_id INT PRIMARY KEY,
			 customer_id INT REFERENCES customers(customer_id),
			 last_login_days INT,
			 session_count INT,
			 last_purchase_days INT,
			 email_click_rate NUMERIC(4,2)
			 );

SELECT * FROM activity
SELECT COUNT(*) FROM activity


--INDEXING for faster joins
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_activity_customer_id ON activity(customer_id);

-- Index churn_flag for fast filtering 
CREATE INDEX idx_customers_churn ON customers(churn_flag);


CREATE INDEX idx_orders_customer ON orders(order_status, customer_id);

-- DATA VALIDATION
-- 1. NULL Detec.
SELECT
    COUNT(*) - COUNT(customer_id)    AS null_customer_id,
    COUNT(*) - COUNT(signup_date)    AS null_signup_date,
    COUNT(*) - COUNT(age)            AS null_age,
    COUNT(*) - COUNT(city)           AS null_city,
    COUNT(*) - COUNT(churn_flag)     AS null_churn_flag
FROM customers;

-- Check NULLs in orders
SELECT
    COUNT(*) - COUNT(order_value)        AS null_order_value,
    COUNT(*) - COUNT(order_status)       AS null_order_status,
    COUNT(*) - COUNT(product_category)   AS null_product_category
FROM orders;

-- Check NULLs in activity
SELECT
    COUNT(*) - COUNT(last_login_days)    AS null_last_login,
    COUNT(*) - COUNT(session_count)      AS null_sessions,
    COUNT(*) - COUNT(email_click_rate)   AS null_email_rate
FROM activity;


-- Duplicate customer_ids
SELECT customer_id, COUNT(*) AS occurrences
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Duplicate order_ids
SELECT order_id, COUNT(*) AS occurrences
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Customers with duplicate activity records 
SELECT customer_id, COUNT(*) AS occurrences
FROM activity
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Age out of realistic range
SELECT COUNT(*) AS invalid_age
FROM customers
WHERE age < 18 OR age > 100;

-- Negative or zero order values
SELECT COUNT(*) AS invalid_order_value
FROM orders
WHERE order_value <= 0;

-- Invalid churn_flag values
SELECT DISTINCT churn_flag FROM customers;


-- Invalid order_status values
SELECT DISTINCT order_status FROM orders;


-- Email click rate outside 0-1 range
SELECT COUNT(*) AS invalid_email_rate
FROM activity
WHERE email_click_rate < 0 OR email_click_rate > 1;

-- Orders linked to non-existent customers (orphan records)
SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;



--data cleaning
-- Impute with median for numeric fields
UPDATE activity
SET session_count = (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY session_count) FROM activity)
WHERE session_count IS NULL;


-- Remove orders with zero or negative value
DELETE FROM orders WHERE order_value <= 0;

-- Flag customers with invalid ages
ALTER TABLE customers ADD COLUMN age_valid BOOLEAN DEFAULT TRUE;
UPDATE customers SET age_valid = FALSE WHERE age < 18 OR age > 100;


-- Standardize city casing
UPDATE customers SET city = INITCAP(TRIM(city));

-- Standardize acquisition_channel
UPDATE customers SET acquisition_channel = INITCAP(TRIM(acquisition_channel));

-- Ensure order_status is consistent
UPDATE orders SET order_status = INITCAP(TRIM(order_status));




-- EDA
--Overall Churn Rate
SELECT 
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned_customers,
    ROUND(AVG(churn_flag) * 100, 2) AS churn_rate_pct
FROM customers;


--churn by acquisition channel
SELECT 
    acquisition_channel,
    COUNT(*) AS total,
    SUM(churn_flag) AS churned,
    ROUND(AVG(churn_flag) * 100, 2) AS churn_rate_pct
FROM customers
GROUP BY acquisition_channel
ORDER BY churn_rate_pct DESC;


--churn by age group
SELECT 
    CASE 
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        WHEN age BETWEEN 46 AND 55 THEN '46-55'
        ELSE '56+' 
    END AS age_group,
    COUNT(*) AS total,
    ROUND(AVG(churn_flag) * 100, 2) AS churn_rate_pct
FROM customers
GROUP BY age_group
ORDER BY age_group;



--order distribution per customer
SELECT 
    orders_per_customer,
    COUNT(*) AS num_customers
FROM (
    SELECT customer_id, COUNT(order_id) AS orders_per_customer
    FROM orders
    GROUP BY customer_id
) t
GROUP BY orders_per_customer
ORDER BY orders_per_customer;




--Revenue Distribution by Order Status
SELECT 
    order_status,
    COUNT(*) AS order_count,
    ROUND(SUM(order_value), 2) AS total_value,
    ROUND(AVG(order_value), 2) AS avg_value
FROM orders
GROUP BY order_status
ORDER BY total_value DESC;


--churn by city
SELECT 
    city,
    COUNT(*) AS total_customers,
    ROUND(AVG(churn_flag) * 100, 2) AS churn_rate_pct
FROM customers
GROUP BY city
ORDER BY churn_rate_pct DESC;


--zero order customers(red flags)
SELECT COUNT(*) AS zero_order_customers
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;




--DATA MODELING
CREATE VIEW customer_360 AS
SELECT 
    c.customer_id,
    c.age,
    c.gender,
    c.city,
    c.acquisition_channel,
    c.signup_date,
    c.is_active,
    c.churn_flag,

    -- Transaction metrics (completed orders only)
    COUNT(CASE WHEN o.order_status = 'Completed' THEN 1 END) 
        AS total_orders,

    SUM(CASE WHEN o.order_status = 'Completed' THEN o.order_value ELSE 0 END) 
        AS total_revenue,

    AVG(CASE WHEN o.order_status = 'Completed' THEN o.order_value END) 
        AS avg_order_value,

    -- Discount behavior
    AVG(o.discount_used) 
        AS discount_usage_rate,

    -- Return behavior
    SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) 
        AS total_returns,

    SUM(CASE WHEN o.order_status = 'Cancelled' THEN 1 ELSE 0 END) 
        AS total_cancellations,

    -- Behavioral signals
    a.last_login_days,
    a.session_count,
    a.last_purchase_days,
    a.email_click_rate

FROM customers c
LEFT JOIN orders o 
    ON c.customer_id = o.customer_id
LEFT JOIN activity a 
    ON c.customer_id = a.customer_id

GROUP BY 
    c.customer_id, c.age, c.gender, c.city, 
    c.acquisition_channel, c.signup_date, c.is_active, c.churn_flag,
    a.last_login_days, a.session_count, a.last_purchase_days, a.email_click_rate;




--Moving advanced
--Discount Dependency vs Churn (High-Impact)
SELECT 
    CASE 
        WHEN discount_usage_rate > 0.7 THEN 'High Discount Users (>70%)'
        WHEN discount_usage_rate > 0.3 THEN 'Medium Discount Users (30-70%)'
        ELSE 'Low Discount Users (<30%)'
    END AS discount_segment,
    COUNT(*) AS customers,
    ROUND(AVG(churn_flag) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(total_revenue), 2) AS avg_revenue
FROM customer_360
GROUP BY discount_segment
ORDER BY churn_rate_pct DESC;


--Returns vs Churn (Experience Signal)
SELECT 
    total_returns,
    COUNT(*) AS customers,
    ROUND(AVG(churn_flag) * 100, 2) AS churn_rate_pct
FROM customer_360
GROUP BY total_returns
ORDER BY total_returns;


--Login Recency vs Churn
SELECT 
    CASE 
        WHEN last_login_days <= 30 THEN 'Active (≤30 days)'
        WHEN last_login_days <= 90 THEN 'At Risk (31-90 days)'
        WHEN last_login_days <= 180 THEN 'Disengaged (91-180 days)'
        ELSE 'Dormant (180+ days)'
    END AS login_segment,
    COUNT(*) AS customers,
    ROUND(AVG(churn_flag) * 100, 2) AS churn_rate_pct
FROM customer_360
GROUP BY login_segment
ORDER BY churn_rate_pct DESC;


--Revenue Lost to Churn
SELECT 
    SUM(total_revenue) AS revenue_lost_to_churn,
    COUNT(*) AS churned_customers,
    ROUND(AVG(total_revenue), 2) AS avg_revenue_per_churned_customer
FROM customer_360
WHERE churn_flag = 1;




--High-Risk Segment: The Danger Zone
SELECT 
    customer_id,
    age,
    city,
    acquisition_channel,
    total_orders,
    total_revenue,
    total_returns,
    last_login_days,
    session_count,
    email_click_rate,
    discount_usage_rate
FROM customer_360
WHERE churn_flag = 0  -- Still active, but...
  AND last_login_days > 60
  AND session_count < 10
  AND total_returns >= 1
ORDER BY last_login_days DESC;



--Order Status Impact on Churn
SELECT 
    CASE 
        WHEN total_cancellations > 0 AND total_returns > 0 THEN 'Cancelled + Returned'
        WHEN total_cancellations > 0 THEN 'Has Cancellations'
        WHEN total_returns > 0 THEN 'Has Returns'
        ELSE 'Clean History'
    END AS order_experience,
    COUNT(*) AS customers,
    ROUND(AVG(churn_flag) * 100, 2) AS churn_rate_pct
FROM customer_360
GROUP BY order_experience
ORDER BY churn_rate_pct DESC;



--Cohort Analysis: Signup Year vs Churn
SELECT 
    EXTRACT(YEAR FROM signup_date) AS signup_year,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(AVG(churn_flag) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(total_revenue), 2) AS avg_lifetime_revenue
FROM customer_360
GROUP BY signup_year
ORDER BY signup_year;



--Product Category vs Churn
SELECT 
    o.product_category,
    COUNT(DISTINCT c.customer_id) AS customers,
    ROUND(AVG(c.churn_flag) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(CASE WHEN o.order_status = 'Completed' THEN o.order_value ELSE 0 END), 2) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY o.product_category
ORDER BY churn_rate_pct DESC;



SELECT * FROM orders