#Imported table using table data importing wizard.

SELECT * FROM super_store.orders;
#Renamed the column table from the keyword
RENAME TABLE `order` TO orders;

#Renamed column headers with space inside the name to be oneword using underscore.
ALTER TABLE `order` 
RENAME COLUMN `Row ID` TO Row_ID,
RENAME COLUMN `Order ID` TO Order_ID,
RENAME COLUMN `Order Date` TO Order_date,
RENAME COLUMN `Ship Date` TO Ship_Date,
RENAME COLUMN `Ship Mode` TO Ship_Mode,
RENAME COLUMN `Customer ID` TO Customer_ID,
RENAME COLUMN `Customer Name` TO Customer_name,
RENAME COLUMN `Postal Code` TO Postal_Code,
RENAME COLUMN `Product ID` TO Product_ID,
RENAME COLUMN `Sub-Category` TO Sub_Category,
RENAME COLUMN `Product Name` TO Product_Name;

##Edited the two date columns from text to date#
UPDATE orders
SET Order_Date = STR_TO_DATE(Order_Date, '%m/%d/%Y');

ALTER TABLE orders
MODIFY COLUMN Order_Date DATE;

UPDATE orders
SET Ship_Date = STR_TO_DATE(Ship_Date, '%m/%d/%Y');

ALTER TABLE orders
MODIFY COLUMN Ship_Date DATE;

#Deleted two columns of country and postal code
ALTER TABLE orders
DROP COLUMN Postal_Code;

ALTER TABLE orders
DROP COLUMN Country;
 
#count of categories

SELECT DISTINCT orders.Segment, COUNT(returned.Returned) as Total_returns 
from orders inner join returned on orders.Order_ID = returned.Order_ID group by orders.Segment;

WITH Profit_Calculation AS (
    SELECT 
        Category,
        COUNT(Quantity) AS total_qty,
        ROUND(SUM(IF(Profit < 1, Profit * (-1), 0)), 2) AS net_loss,
        ROUND(SUM(IF(Profit > 1, Profit, 0)), 2) AS net_profit
    FROM 
        orders
    GROUP BY 
        Category
)
SELECT 
    Category,
    total_qty,
    net_loss,
    net_profit,
    ROUND(net_profit - net_loss, 2) AS Gross_Profit
FROM 
    Profit_Calculation;

select distinct(Category), sum(Quantity), round(sum(Profit),2) as Loses
from orders
where Profit <1
group by Category;



#who made the most sales
Select DISTINCT(Ship_Mode), Region, round(Sum(Sales),2) as Total_Sales
From orders
GROUP BY Ship_mode, Region;

SELECT p.Person_name, round(Sum(o.Sales),2), Sum(o.Quantity), p.Region
FROM people p
JOIN
orders o
on p.Region = o.Region
GROUP BY p.Person_name, p.Region;

select DISTINCT Category, Region, Sales,
(select
	IF(Profit > 0, profit, 0) ) AS Profit,
(select
    IF(Profit < 0, profit, 0)*-1 ) AS Loss
from orders 
;


with total_profit as (
select DISTINCT Category, Region, Sales,
(select
	IF(Profit > 0, profit, 0) )AS Profit,
(select
    IF(Profit < 0, profit, 0)*-1 ) AS Loss
from orders )
select Region, round(SUM(Sales),2) as Regional_sales, round(SUM(Profit),2) as Regional_Profits
from total_profit
Where Sales > 100
group by Region;



SELECT DATEDIFF(Ship_Date, Order_Date) as Duration, Category
FROM orders;

SELECT Segment, Ship_mode, DATEDIFF(orders.Ship_Date, orders.Order_Date) as Date_delay, returned.Order_ID
from orders  
join
returned
on orders.Order_ID = returned.Order_ID;

SELECT DISTINCT State, Region, round(SUM(Sales),2) AS total_sales
FROM orders
GROUP BY State, Region
ORDER BY SUM(Sales) DESC
LIMIT 10;


WITH TotalOrders AS (
    SELECT COUNT(order_id) AS total_orders
    FROM orders
)
SELECT 
    p.region,
    round(COUNT(r.Order_ID),2) AS num_returned_items, 
    t.total_orders,
    round(SUM(o.Sales),2) AS total_sales,
    round(SUM(o.Profit),2) AS total_profit,
    ((COUNT(r.Order_id)/ t.total_orders)*100) AS returned_percentage
FROM 
    orders o
LEFT JOIN 
    people p ON o.Region = p.Region
LEFT JOIN 
    returned r ON o.Order_ID = r.Order_ID
CROSS JOIN 
    TotalOrders t
WHERE 
    r.Order_ID IS NOT NULL
GROUP BY 
     p.Region, t.total_orders;
     
     
select Region, COUNT(DISTINCT(Customer_name))as No_Customers
FROM orders
Group BY Region;

SELECT o.Order_ID, DATEDIFF(Ship_Date, Order_Date) as Duration, r.Returned, o.Ship_Mode
FROM orders o
RIGHT JOIN
returned r
ON o.Order_ID = r.Order_ID
ORDER BY Duration DESC;

#Returned items vs duration 

WITH Relate AS (
    SELECT 
        o.Order_ID, 
        DATEDIFF(Ship_Date, Order_Date) AS Duration, 
        r.Returned
    FROM 
        orders o
    LEFT JOIN 
        returned r
    ON 
        o.Order_ID = r.Order_ID
)
SELECT 
    CASE 
        WHEN Returned = 'Yes' THEN 'Returned'
        ELSE 'Not Returned'
    END AS Return_Status,
    AVG(Duration) AS Average_Duration
FROM 
    Relate
GROUP BY 
    Return_Status
WITH ROLLUP;

#Category prone to return
WITH Category_Returns AS (
    SELECT 
        o.Category,
        COUNT(CASE WHEN r.Returned = 'Yes' THEN o.Order_ID END) AS Returned_Count,
        COUNT(o.Order_ID) AS Total_Count
    FROM 
        orders o
    LEFT JOIN 
        returned r ON o.Order_ID = r.Order_ID
    GROUP BY 
        Category
	WITH ROLLUP
)
SELECT 
    Category,
    Returned_Count,
    Total_Count,
    (Returned_Count * 100.0 / Total_Count) AS Return_Rate_Percentage
FROM 
    Category_Returns
ORDER BY 
    Returned_Count ASC;
