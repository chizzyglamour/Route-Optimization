CREATE SCHEMA UrbanEats;
USE UrbanEats;

SELECT * FROM urbaneats.customer_orders_realistic;
-- Data Cleaning 
-- Changing to the right datatype
ALTER TABLE customer_orders_realistic
ADD COLUMN NewOrderStamp DATETIME;
SET SQL_SAFE_UPDATES = 0; -- turning off safe updates
UPDATE customer_orders_realistic
SET NewOrderStamp = STR_TO_DATE(OrderTimeStamp, '%d/%m/%Y %H:%i');
ALTER TABLE customer_orders_realistic
DROP COLUMN  OrderTimeStamp;
ALTER TABLE customer_orders_realistic
CHANGE COLUMN NewOrderStamp OrderTimeStamp DATETIME;

ALTER TABLE customer_orders_realistic
MODIFY COLUMN Latitude DECIMAL(10,7);

ALTER TABLE customer_orders_realistic
MODIFY COLUMN Longitude DECIMAL(10,7);

ALTER TABLE customer_orders_realistic
MODIFY COLUMN DistanceKM DECIMAL(8,3);

ALTER TABLE customer_orders_realistic
MODIFY COLUMN DeliveryHours DECIMAL(5,2);

ALTER TABLE customer_orders_realistic
ADD COLUMN Delivery DATETIME;
SET SQL_SAFE_UPDATES = 0; -- turning off safe updates
UPDATE customer_orders_realistic
SET Delivery = STR_TO_DATE(DeliveryTime, '%d/%m/%Y %H:%i')
WHERE DeliveryTime != '';
ALTER TABLE customer_orders_realistic
DROP COLUMN  DeliveryTime;
ALTER TABLE customer_orders_realistic
CHANGE COLUMN Delivery DeliveryTime DATETIME;

-- 1) Add a new DATETIME column
ALTER TABLE customer_orders_realistic
  ADD COLUMN Delivery_tmp DATETIME;

-- 2) (Optional) Turn off safe-updates in this session if you hit errors:
SET SQL_SAFE_UPDATES = 0;

-- 3) Populate it using STR_TO_DATE, skipping empty strings
UPDATE customer_orders_realistic
SET Delivery_tmp = DeliveryTime
WHERE DeliveryTime IS NOT NULL
  AND TRIM(DeliveryTime) <> '';

-- 4) Drop the old text column
ALTER TABLE customer_orders_realistic
  DROP COLUMN DeliveryTime;

-- 5) Rename the tmp column to the original name
ALTER TABLE customer_orders_realistic
  CHANGE COLUMN Delivery_tmp DeliveryTime DATETIME;
  
SET SESSION sql_mode = REPLACE(@@sql_mode, 'NO_ZERO_DATE', '');
SET SESSION sql_mode = REPLACE(@@sql_mode, 'STRICT_TRANS_TABLES', '');

UPDATE customer_orders_realistic
SET DeliveryTime = '0000-00-00 00:00:00'
WHERE DeliveryTime IS NULL;

UPDATE customer_orders_realistic
SET TimeTakenToDeliver = '00:00:00'
WHERE TRIM(TimeTakenToDeliver) = '';

UPDATE drivers_realistic
SET ShiftStart = STR_TO_DATE(ShiftStart, '%d/%m/%Y %H:%i'),
ShiftEnd = STR_TO_DATE(ShiftEnd, '%d/%m/%Y %H:%i');

ALTER TABLE  drivers_realistic
MODIFY ShiftStart DATETIME,
MODIFY ShiftEnd DATETIME;

-- Data Exploration
SHOW TABLES;
SHOW COLUMNS FROM customer_orders_realistic;
DESCRIBE drivers_realistic;
DESC restaurants_realistic;
DESC traffic_data_realistic;

SELECT * FROM customer_orders_realistic;
SELECT * FROM drivers_realistic;
SELECT * FROM restaurants_realistic;
SELECT * FROM traffic_data_realistic;
-- Feature Engineering
-- Estimated Travel Time
SELECT 
	O.OrderID,
    o.DistanceKM,
    ROUND(o.DistanceKM*(1+t.TrafficDensity /100))AS EstimatedTravelTime_min
FROM customer_orders_realistic o
JOIN traffic_data_realistic t
ON o.LocationID = t.LocationID;

-- Driver Shift Length
SELECT 
	DriverID,
    ShiftStart,
    ShiftEnd,
    TIMESTAMPDIFF(HOUR, ShiftStart, ShiftEnd) AS ShiftLength_hr
FROM drivers_realistic;

-- Deliverytime per restaurant
SELECT
	r.RestaurantID,
    r.RestaurantName,
    AVG(o.DeliveryHours) AS avg_delivery_time
FROM restaurants_realistic r
JOIN customer_orders_realistic o
ON o.RestaurantID = r.RestaurantID
GROUP BY r.RestaurantID, r.RestaurantName;

-- Driver's busy period
SELECT
DriverID,
EXTRACT(HOUR FROM OrderTimeStamp) AS OrderHour,
COUNT(*) AS NumberofOrders
FROM customer_orders_realistic
GROUP BY DriverID,EXTRACT(HOUR FROM OrderTimeStamp);

-- Order Volume by Area
SELECT 
	LocationID,
	COUNT(*) AS TotalOrders
FROM customer_orders_realistic
GROUP BY LocationID;

-- Preliminary Analysis
SELECT 
	AVG(DeliveryHours) AS AvgDeliveryTime,
    MIN(DeliveryHours) AS MinDeliveryTime,
    MAX(DeliveryHours) AS MaxDeliveryTime
FROM customer_orders_realistic;

-- Frequency of Delivery Statuses
SELECT
	OrderStatus,
    COUNT(*) AS StatusCount
FROM customer_orders_realistic
GROUP BY OrderStatus;

-- Shift Length and Count
SELECT 
	DriverID,
    DriverName,
    COUNT(*) AS NumberOfShifts,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, ShiftStart, ShiftEnd)))AS AvgShiftLength
FROM drivers_realistic
GROUP BY DriverID,DriverName;

-- Number of Orders Per Restaurant
SELECT
	Restaurantid,
    COUNT(*) AS TotalOrders
FROM customer_orders_realistic
GROUP BY RestaurantID;

-- Traffic Density Statistics
SELECT
	AVG(TrafficDensity)AS AvgTrafficDensity,
    MIN(TrafficDensity)AS MinTrafficDensity,
    MAX(TrafficDensity)AS MaxTrafficDensity
FROM traffic_data_realistic;

-- Identifying Peak Delivery Time
SELECT
	EXTRACT(Hour FROM OrderTimeStamp)AS HourOfDay,
    COUNT(*)AS OrderCount
FROM customer_orders_realistic
GROUP BY HourOfDay;

SELECT
	DAYNAME(OrderTimeStamp)AS DayOfWeek,
    COUNT(*)AS OrderCount
FROM customer_orders_realistic
GROUP BY DayOfWeek;

SELECT
	d.ShiftID,
    AVG(o.DeliveryHours)AS AvgDeliveryTime
FROM customer_orders_realistic o
JOIN drivers_realistic d
ON o.DriverID = d.DriverID
GROUP BY d.ShiftID;

SELECT 
	t.TrafficDensity,
    AVG(o.DeliveryHours)AS AvgDeliveryTime
FROM customer_orders_realistic o
JOIN traffic_data_realistic t
ON t.LocationID = o.LocationID
GROUP BY t.TrafficDensity;

SELECT 
	r.RestaurantID,
    AVG(o.DeliveryHours)AS AvgDeliveryTime
FROM customer_orders_realistic o
JOIN restaurants_realistic r
ON r.RestaurantID = o.RestaurantID
GROUP BY r.RestaurantID;
    


	

 
	

    
	
	


