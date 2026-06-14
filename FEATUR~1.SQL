''' 
Building a star schema:
fact transactions --> dim_products -- dim_customers -- (time derived in SQL)
'''

-- Creating Dimension table - Customers

CREATE TABLE dim_customers(
					
				customer_id			INT	PRIMARY KEY,
									-- customer_id set as unique identifier
				signup_date			DATE,
				region				VARCHAR(50),
				acquisition_channel	VARCHAR(50)
							);
				
-- Creating Dimention table - Products
				
CREATE TABLE dim_products(
				
				product_id			INT	PRIMARY KEY,
									-- product_id set as unique identifier
				category			VARCHAR(50),
				cost_price			NUMERIC(10,2)
							);

-- Creating Fact table - transactions

CREATE TABLE fact_transactions(

				transaction_id		INT PRIMARY KEY,
									-- transactions_id set as unique identifier
				customer_id			INT	REFERENCES dim_customers(customer_id),
									-- customer_id set as foreign key joining dim_customers table
				product_id			INT REFERENCES dim_products(product_id),
									-- product_id set as foreign key joining dim_products table
				transaction_date	DATE,
				quantity			INT,
				selling_price		NUMERIC(10,2),
				revenue				NUMERIC(10,2)
							);

-- Inserting Indexes for quicker query
				
CREATE INDEX idx_transactions_customer
ON fact_transactions(customer_id);

CREATE INDEX idx_transactions_date
ON fact_transactions(transaction_date);

CREATE INDEX idx_transactions_product
ON fact_transactions(product_id);


'''
Random data items generated on Python imported in these tables
Refer to python jupyter notebook for reference
'''


'''
Core SQL Queries to turn raw data into customer-level feature table
'''

-- Customer lifetime metrics

SELECT		customer_id AS [Customer_ID],
			MIN(DATE(transaction_date)) AS [First_Purchase_Date],
			MAX(DATE(transaction_date)) AS [Last_Purchase_Date],
			COUNT(transaction_id) AS [Total_Orders],
			ROUND(SUM(revenue),2) AS [Total_Revenue]
			-- customer_id grouped, iterations performed on rest columns
FROM 		fact_transactions ft 
GROUP BY	customer_id
ORDER BY	customer_id ASC;

-- Recency, Frequency, Monetary (RFM)

SELECT		customer_id AS [Customer_ID],
			CAST(JULIANDAY('2025-01-01') - JULIANDAY(MAX(transaction_date)) AS INT) AS [Recency],
			-- Recency subtracts maximum transaction date from today's date
			-- Result - lower number = more recent customer
			COUNT(transaction_id) AS [Frequency],
			-- Frequency counts number of transactions per customer
			ROUND(SUM(revenue),2) AS [Monetary]
			-- Monetary counts total money spent by customer
FROM 		fact_transactions ft 
GROUP BY 	customer_id
ORDER BY	Recency ASC;

-- Cohort Analysis Prep

SELECT		customer_id AS [Customer_ID],
			STRFTIME('%Y-%m',MIN(transaction_date)) AS [Cohort_Month]
			-- Cohort Month filters customers based on the month they made their first purchase
FROM		fact_transactions ft 
GROUP BY	customer_id;

-- Product/Category Preference Features

SELECT		ft.customer_id AS [Customer_ID],
			dp.category AS [Category],
			ROUND(SUM(ft.revenue),2) AS [Cat_Revenue]
FROM		fact_transactions ft 
INNER JOIN	dim_products dp 
ON			dp.product_id = ft.product_id
			-- inner join between dim_products and fact_transactions table via product_id
GROUP BY	ft.customer_id,
			dp.product_id
ORDER BY	Category ASC,
			Cat_Revenue DESC;
